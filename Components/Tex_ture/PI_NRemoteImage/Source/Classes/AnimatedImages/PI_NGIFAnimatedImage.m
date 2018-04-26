//
//  PI_NGIFAnimatedImage.m
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PI_NGIFAnimatedImage.h"

#import <ImageIO/ImageIO.h>
#if PI_N_TARGET_IOS
#import <MobileCoreServices/UTCoreTypes.h>
#elif PI_N_TARGET_MAC
#import <CoreServices/CoreServices.h>
#endif

#import "PI_NImage+DecodedImage.h"

@interface PI_NGIFAnimatedImage ()
{
    NSData *_animatedImageData;
    CGImageSourceRef _imageSource;
    uint32_t _width;
    uint32_t _height;
    BOOL _hasAlpha;
    size_t _frameCount;
    size_t _loopCount;
    CFTimeInterval *_durations;
    NSError *_error;
}
@end

@implementation PI_NGIFAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if (self = [super init]) {
        _imageSource =
            CGImageSourceCreateWithData((CFDataRef)animatedImageData,
                                        (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint:
                                                               (__bridge NSString *)kUTTypeGIF,
                                                           (__bridge NSString *)kCGImageSourceShouldCache:
                                                               (__bridge NSNumber *)kCFBooleanFalse});
        if (_imageSource) {
            _frameCount = (uint32_t)CGImageSourceGetCount(_imageSource);
            NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(_imageSource, nil);
            _loopCount = (uint32_t)[[[imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                                     objectForKey:(__bridge NSString *)kCGImagePropertyGIFLoopCount] unsignedLongValue];
            _durations = malloc(sizeof(CFTimeInterval) * _frameCount);
            imageProperties = (__bridge_transfer NSDictionary *)
                CGImageSourceCopyPropertiesAtIndex(_imageSource,
                                                   0,
                                                   (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache:
                                                                          (__bridge NSNumber *)kCFBooleanFalse});
            _width = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
            _height = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
            
            for (NSUInteger frameIdx = 0; frameIdx < _frameCount; frameIdx++) {
                _durations[frameIdx] = [PI_NGIFAnimatedImage frameDurationAtIndex:frameIdx source:_imageSource];
            }
        }
    }
    return self;
}

+ (Float32)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    Float32 frameDuration = kPI_NAnimatedImageDefaultDuration;
    NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    // use unclamped delay time before delay time before default
    NSNumber *unclamedDelayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (unclamedDelayTime != nil) {
        frameDuration = [unclamedDelayTime floatValue];
    } else {
        NSNumber *delayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime != nil) {
            frameDuration = [delayTime floatValue];
        }
    }
    
    static dispatch_once_t onceToken;
    static Float32 maximumFrameDuration;
    dispatch_once(&onceToken, ^{
        maximumFrameDuration = 1.0 / [PI_NAnimatedImage maximumFramesPerSecond];
    });
    
    if (frameDuration < maximumFrameDuration) {
        frameDuration = kPI_NAnimatedImageDefaultDuration;
    }
    
    return frameDuration;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
    }
    if (_durations) {
        free(_durations);
    }
}

- (size_t)frameCount
{
    return _frameCount;
}

- (size_t)loopCount
{
    return _loopCount;
}

- (uint32_t)width
{
    return _width;
}

- (uint32_t)height
{
    return _height;
}

- (uint32_t)bytesPerFrame
{
    return _width * _height * 3;
}

- (NSError *)error
{
    return _error;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return _durations[index];
}

- (CGImageRef)imageAtIndex:(NSUInteger)index cacheProvider:(nullable id<PI_NCachedAnimatedFrameProvider>)cacheProvider
{
    // I believe this is threadsafe as CGImageSource *seems* immutable…
    CGImageRef imageRef =
        CGImageSourceCreateImageAtIndex(_imageSource,
                                        index,
                                        (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache:
                                                               (__bridge NSNumber *)kCFBooleanFalse});
    if (imageRef) {
        CGImageRef decodedImageRef = [PI_NImage pin_decodedImageRefWithCGImageRef:imageRef];
        CGImageRelease(imageRef);
        imageRef = decodedImageRef;
    }
    
    return imageRef;
}

@end
