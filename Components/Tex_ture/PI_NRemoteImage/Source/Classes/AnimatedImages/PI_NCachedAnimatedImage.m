//
//  PI_NCachedAnimatedImage.m
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PI_NCachedAnimatedImage.h"

#import "PI_NRemoteLock.h"
#import "PI_NGIFAnimatedImage.h"
#if PI_N_WEBP
#import "PI_NWebPAnimatedImage.h"
#endif

#import <PI_NOperation/PI_NOperationQueue.h>
#import "NSData+ImageDe_tectors.h"

static const NSUInteger kFramesToRenderForLargeFrames = 4;
static const NSUInteger kFramesToRenderMinimum = 2;

static const CFTimeInterval kSecondsAfterMemWarningToMinimumCache = 1;
static const CFTimeInterval kSecondsAfterMemWarningToLargeCache = 5;
static const CFTimeInterval kSecondsAfterMemWarningToAllCache = 10;
#if PI_N_TARGET_IOS
static const CFTimeInterval kSecondsBetweenMemoryWarnings = 15;
#endif

@interface PI_NCachedAnimatedImage () <PI_NCachedAnimatedFrameProvider>
{
    // Since _animatedImage is set on init it is thread-safe.
    id <PI_NAnimatedImage> _animatedImage;
    
    PI_NImage *_coverImage;
    PI_NAnimatedImageInfoReady _coverImageReadyCallback;
    dispatch_block_t _playbackReadyCallback;
    NSMutableDictionary *_frameCache;
    NSInteger _frameRenderCount; // Number of frames to cache until playback is ready.
    BOOL _playbackReady;
    PI_NOperationQueue *_operationQueue;
    dispatch_queue_t _cachingQueue;
    
    NSUInteger _playhead;
    BOOL _notifyOnReady;
    NSMutableIndexSet *_cachedOrCachingFrames;
    PI_NRemoteLock *_lock;
    BOOL _cacheCleared; // Flag used to cancel any caching operations after clear cache is called.
}

@property (atomic, strong) NSDate *lastMemoryWarning;

// Set to YES if we continually see memory warnings after ramping up the number of cached frames.
@property (atomic, assign) BOOL cachingFramesCausingMemoryWarnings;

@end

@implementation PI_NCachedAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if ([animatedImageData pin_isAnimatedGIF]) {
        return [self initWithAnimatedImage:[[PI_NGIFAnimatedImage alloc] initWithAnimatedImageData:animatedImageData]];
    }
#if PI_N_WEBP
    if ([animatedImageData pin_isAnimatedWebP]) {
        return [self initWithAnimatedImage:[[PI_NWebPAnimatedImage alloc] initWithAnimatedImageData:animatedImageData]];
    }
#endif
    return nil;
}

- (instancetype)initWithAnimatedImage:(id <PI_NAnimatedImage>)animatedImage
{
    if (self = [super init]) {
        _animatedImage = animatedImage;
        _frameCache = [[NSMutableDictionary alloc] init];
        _frameRenderCount = 0;
        _playhead = 0;
        _notifyOnReady = YES;
        _cachedOrCachingFrames = [[NSMutableIndexSet alloc] init];
        _lock = [[PI_NRemoteLock alloc] initWithName:@"PI_NCachedAnimatedImage Lock"];
        
#if PI_N_TARGET_IOS
        _lastMemoryWarning = [NSDate distantPast];
        PI_NWeakify(self);
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            PI_NStrongify(self);
            NSDate *now = [NSDate date];
            if (-[self.lastMemoryWarning timeIntervalSinceDate:now] < kSecondsBetweenMemoryWarnings) {
                self.cachingFramesCausingMemoryWarnings = YES;
            }
            self.lastMemoryWarning = now;
            [self cleanupFrames];
        }];
#endif
        
        _operationQueue = [[PI_NOperationQueue alloc] initWithMaxConcurrentOperations:kFramesToRenderForLargeFrames];
        _cachingQueue = dispatch_queue_create("Caching Queue", DISPATCH_QUEUE_SERIAL);
        
        // dispatch later so that blocks can be set after init this runloop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self imageAtIndex:0];
        });
    }
    return self;
}

- (PI_NImage *)coverImage
{
    __block PI_NImage *coverImage = nil;
    [_lock lockWithBlock:^{
        if (self->_coverImage == nil) {
            CGImageRef coverImageRef = [self->_animatedImage imageAtIndex:0 cacheProvider:self];
            [self l_updateCoverImage:coverImageRef];
        }
        coverImage = self->_coverImage;
    }];
    return coverImage;
}

- (void)l_updateCoverImage:(CGImageRef)coverImageRef
{
    if (coverImageRef) {
        BOOL notify = _coverImage == nil && coverImageRef != nil;
#if PI_N_TARGET_IOS
        _coverImage = [UIImage imageWithCGImage:coverImageRef];
#elif PI_N_TARGET_MAC
        _coverImage = [[NSImage alloc] initWithCGImage:coverImageRef size:CGSizeMake(_animatedImage.width, _animatedImage.height)];
#endif
        if (notify && _coverImageReadyCallback) {
            _coverImageReadyCallback(_coverImage);
        }
    } else {
        _coverImage = nil;
    }
}

- (BOOL)coverImageReady
{
    __block BOOL coverImageReady = NO;
    [_lock lockWithBlock:^{
        if (self->_coverImage == nil) {
            CGImageRef coverImageRef = (__bridge CGImageRef)[self->_frameCache objectForKey:@(0)];
            if (coverImageRef) {
                [self l_updateCoverImage:coverImageRef];
            }
        }
        coverImageReady = self->_coverImage != nil;
    }];
    return coverImageReady;
}

#pragma mark - passthrough

- (CFTimeInterval)totalDuration
{
    return _animatedImage.totalDuration;
}

- (NSUInteger)frameInterval
{
    return _animatedImage.frameInterval;
}

- (size_t)loopCount
{
    return _animatedImage.loopCount;
}

- (size_t)frameCount
{
    return _animatedImage.frameCount;
}

- (NSError *)error
{
    return _animatedImage.error;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
    __block CGImageRef imageRef;
    __block BOOL cachingDisabled = NO;
    [_lock lockWithBlock:^{
        // Reset cache cleared flag if it's been set.
        self->_cacheCleared = NO;
        imageRef = (__bridge CGImageRef)[self->_frameCache objectForKey:@(index)];
        
        self->_playhead = index;
        if (imageRef == NULL) {
            if ([self framesToCache] == 0) {
                // We're not caching so we should just generate the frame.
                cachingDisabled = YES;
            } else {
                PI_NLog(@"cache miss, aww.");
                self->_notifyOnReady = YES;
            }
        }
        
        // Retain and autorelease while we have the lock, another thread could remove it from the cache
        // and allow it to be released.
        if (imageRef) {
            CGImageRetain(imageRef);
            CFAutorelease(imageRef);
        }
    }];
    
    if (cachingDisabled && imageRef == NULL) {
        imageRef = [_animatedImage imageAtIndex:index cacheProvider:self];
    } else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self updateCache];
        });
    }

    return imageRef;
}

- (void)updateCache
{
    // skip if we don't have any frames to cache
    if ([self framesToCache] > 0) {
        [_operationQueue scheduleOperation:^{
            // Kick off, in order, caching frames which need to be cached
            NSRange endKeepRange;
            NSRange beginningKeepRange;
            
            [self getKeepRanges:&endKeepRange beginningKeepRange:&beginningKeepRange];
            
            [self->_lock lockWithBlock:^{
                for (NSUInteger idx = endKeepRange.location; idx < NSMaxRange(endKeepRange); idx++) {
                    if ([self->_cachedOrCachingFrames containsIndex:idx] == NO) {
                        [self l_cacheFrame:idx];
                    }
                }
                
                if (beginningKeepRange.location != NSNotFound) {
                    for (NSUInteger idx = beginningKeepRange.location; idx < NSMaxRange(beginningKeepRange); idx++) {
                        if ([self->_cachedOrCachingFrames containsIndex:idx] == NO) {
                            [self l_cacheFrame:idx];
                        }
                    }
                }
            }];
        }];
    }
    
    [_operationQueue scheduleOperation:^{
        [self cleanupFrames];
    }];
}

- (void)getKeepRanges:(nonnull out NSRange *)endKeepRangeIn beginningKeepRange:(nonnull out NSRange *)beginningKeepRangeIn
{
    __block NSRange endKeepRange;
    __block NSRange beginningKeepRange;
    
    NSUInteger framesToCache = [self framesToCache];
    
    [self->_lock lockWithBlock:^{
        // find the range of frames we want to keep
        endKeepRange = NSMakeRange(self->_playhead, framesToCache);
        beginningKeepRange = NSMakeRange(NSNotFound, 0);
        if (NSMaxRange(endKeepRange) > self->_animatedImage.frameCount) {
            beginningKeepRange = NSMakeRange(0, NSMaxRange(endKeepRange) - self->_animatedImage.frameCount);
            endKeepRange.length = self->_animatedImage.frameCount - self->_playhead;
        }
    }];
    
    if (endKeepRangeIn) {
        *endKeepRangeIn = endKeepRange;
    }
    if (beginningKeepRangeIn) {
        *beginningKeepRangeIn = beginningKeepRange;
    }
}

- (void)cleanupFrames
{
    NSRange endKeepRange;
    NSRange beginningKeepRange;
    [self getKeepRanges:&endKeepRange beginningKeepRange:&beginningKeepRange];
    
    [_lock lockWithBlock:^{
        NSMutableIndexSet *removedFrames = [[NSMutableIndexSet alloc] init];
        PI_NLog(@"Checking if frames need removing: %lu", _cachedOrCachingFrames.count);
        [self->_cachedOrCachingFrames enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL shouldKeepFrame = NSLocationInRange(idx, endKeepRange);
            if (beginningKeepRange.location != NSNotFound) {
                shouldKeepFrame |= NSLocationInRange(idx, beginningKeepRange);
            }
            if (shouldKeepFrame == NO) {
                [removedFrames addIndex:idx];
                [self->_frameCache removeObjectForKey:@(idx)];
                PI_NLog(@"Removing: %lu", (unsigned long)idx);
            }
        }];
        [self->_cachedOrCachingFrames removeIndexes:removedFrames];
    }];
}

- (void)l_cacheFrame:(NSUInteger)frameIndex
{
    if ([_cachedOrCachingFrames containsIndex:frameIndex] == NO && _cacheCleared == NO) {
        PI_NLog(@"Requesting: %lu", (unsigned long)frameIndex);
        [_cachedOrCachingFrames addIndex:frameIndex];
        _frameRenderCount++;
        
        dispatch_async(_cachingQueue, ^{
            CGImageRef imageRef = [self->_animatedImage imageAtIndex:frameIndex cacheProvider:self];
            PI_NLog(@"Generating: %lu", (unsigned long)frameIndex);

            if (imageRef) {
                [self->_lock lockWithBlock:^{
                    [self->_frameCache setObject:(__bridge id _Nonnull)(imageRef) forKey:@(frameIndex)];
                    
                    // Update the cover image
                    if (frameIndex == 0) {
                        [self l_updateCoverImage:imageRef];
                    }
                    
                    self->_frameRenderCount--;
                    NSAssert(self->_frameRenderCount >= 0, @"playback ready is less than zero, something is wrong :(");
                    
                    PI_NLog(@"Frames left: %ld", (long)_frameRenderCount);
                    
                    dispatch_block_t notify = nil;
                    if (self->_frameRenderCount == 0 && self->_notifyOnReady) {
                        self->_notifyOnReady = NO;
                        if (self->_playbackReadyCallback) {
                            notify = self->_playbackReadyCallback;
                            [self->_operationQueue scheduleOperation:^{
                                notify();
                            }];
                        }
                    }
                }];
            }
        });
    }
}

// Returns the number of frames that should be cached
- (NSUInteger)framesToCache
{
    unsigned long long totalBytes = [NSProcessInfo processInfo].physicalMemory;
    NSUInteger framesToCache = 0;
    
    NSUInteger frameCost = _animatedImage.bytesPerFrame;
    if (frameCost * _animatedImage.frameCount < totalBytes / 250) {
        // If the total number of bytes takes up less than a 250th of total memory, lets just cache 'em all.
        framesToCache = _animatedImage.frameCount;
    } else if (frameCost < totalBytes / 1000) {
        // If the cost of a frame is less than 1000th of physical memory, cache 4 frames to smooth animation.
        framesToCache = kFramesToRenderForLargeFrames;
    } else if (frameCost < totalBytes / 500) {
        // Oooph, lets just try to get ahead of things by one.
        framesToCache = kFramesToRenderMinimum;
    } else {
        // No caching :(
        framesToCache = 0;
    }
    
    // If it's been less than 5 seconds, we're not caching
    CFTimeInterval timeSinceLastWarning = -[self.lastMemoryWarning timeIntervalSinceNow];
    if (self.cachingFramesCausingMemoryWarnings || timeSinceLastWarning < kSecondsAfterMemWarningToMinimumCache) {
        framesToCache = 0;
    } else if (timeSinceLastWarning < kSecondsAfterMemWarningToLargeCache) {
        framesToCache = MIN(framesToCache, kFramesToRenderMinimum);
    } else if (timeSinceLastWarning < kSecondsAfterMemWarningToAllCache) {
        framesToCache = MIN(framesToCache, kFramesToRenderForLargeFrames);
    }
    
    return framesToCache;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return [_animatedImage durationAtIndex:index];
}

- (BOOL)playbackReady
{
    __block BOOL playbackReady = NO;
    [_lock lockWithBlock:^{
        if (self->_playbackReady == NO) {
            self->_playbackReady = self->_frameRenderCount == 0;
        }
        playbackReady = self->_playbackReady;
    }];
    return playbackReady;
}

- (dispatch_block_t)playbackReadyCallback
{
    __block dispatch_block_t playbackReadyCallback = nil;
    [_lock lockWithBlock:^{
        playbackReadyCallback = self->_playbackReadyCallback;
    }];
    return playbackReadyCallback;
}

- (void)setPlaybackReadyCallback:(dispatch_block_t)playbackReadyCallback
{
    [_lock lockWithBlock:^{
        self->_playbackReadyCallback = playbackReadyCallback;
    }];
}

- (PI_NAnimatedImageInfoReady)coverImageReadyCallback
{
    __block PI_NAnimatedImageInfoReady coverImageReadyCallback;
    [_lock lockWithBlock:^{
        coverImageReadyCallback = self->_coverImageReadyCallback;
    }];
    return coverImageReadyCallback;
}

- (void)setCoverImageReadyCallback:(PI_NAnimatedImageInfoReady)coverImageReadyCallback
{
    [_lock lockWithBlock:^{
        self->_coverImageReadyCallback = coverImageReadyCallback;
    }];
}

/**
 @abstract Clear any cached data. Called when playback is paused.
 */
- (void)clearAnimatedImageCache
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self->_lock lockWithBlock:^{
            self->_cacheCleared = YES;
            self->_coverImage = nil;
            [self->_cachedOrCachingFrames enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                [self->_frameCache removeObjectForKey:@(idx)];
            }];
            [self->_cachedOrCachingFrames removeAllIndexes];
        }];
    });
}

# pragma mark - PI_NCachedAnimatedFrameProvider

- (CGImageRef)cachedFrameImageAtIndex:(NSUInteger)index
{
    __block CGImageRef imageRef;
    [_lock lockWithBlock:^{
        imageRef = (__bridge CGImageRef)[self->_frameCache objectForKey:@(index)];
        if (imageRef) {
            CGImageRetain(imageRef);
            CFAutorelease(imageRef);
        }
    }];
    return imageRef;
}

@end
