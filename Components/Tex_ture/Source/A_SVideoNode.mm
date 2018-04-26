//
//  A_SVideoNode.mm
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AVFoundation/AVFoundation.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SVideoNode.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>

static BOOL A_SAssetIsEqual(AVAsset *asset1, AVAsset *asset2) {
  return A_SObjectIsEqual(asset1, asset2)
  || ([asset1 isKindOfClass:[AVURLAsset class]]
      && [asset2 isKindOfClass:[AVURLAsset class]]
      && A_SObjectIsEqual(((AVURLAsset *)asset1).URL, ((AVURLAsset *)asset2).URL));
}

static UIViewContentMode A_SContentModeFromVideoGravity(NSString *videoGravity) {
  if ([videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
    return UIViewContentModeScaleAspectFill;
  } else if ([videoGravity isEqualToString:AVLayerVideoGravityResize]) {
    return UIViewContentModeScaleToFill;
  } else {
    return UIViewContentModeScaleAspectFit;
  }
}

static void *A_SVideoNodeContext = &A_SVideoNodeContext;
static NSString * const kPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const kplaybackBufferEmpty = @"playbackBufferEmpty";
static NSString * const kStatus = @"status";
static NSString * const kRate = @"rate";

@interface A_SVideoNode ()
{
  struct {
    unsigned int delegateVideNodeShouldChangePlayerStateTo:1;
    unsigned int delegateVideoDidPlayToEnd:1;
    unsigned int delegateDidTapVideoNode:1;
    unsigned int delegateVideoNodeWillChangePlayerStateToState:1;
    unsigned int delegateVideoNodeDidPlayToTimeInterval:1;
    unsigned int delegateVideoNodeDidStartInitialLoading:1;
    unsigned int delegateVideoNodeDidFinishInitialLoading:1;
    unsigned int delegateVideoNodeDidSetCurrentItem:1;
    unsigned int delegateVideoNodeDidStallAtTimeInterval:1;
    unsigned int delegateVideoNodeDidRecoverFromStall:1;
    unsigned int delegateVideoNodeDidFailToLoadValueForKey:1;
  } _delegateFlags;
  
  BOOL _shouldBePlaying;
  
  BOOL _shouldAutorepeat;
  BOOL _shouldAutoplay;
  BOOL _shouldAggressivelyRecoverFromStall;
  BOOL _muted;
  
  A_SVideoNodePlayerState _playerState;
  
  AVAsset *_asset;
  NSURL *_assetURL;
  AVVideoComposition *_videoComposition;
  AVAudioMix *_audioMix;
  
  AVPlayerItem *_currentPlayerItem;
  AVPlayer *_player;
  
  id _timeObserver;
  int32_t _periodicTimeObserverTimescale;
  CMTime _timeObserverInterval;
  
  CMTime _lastPlaybackTime;
	
  A_SDisplayNode *_playerNode;
  NSString *_gravity;
}

@end

@implementation A_SVideoNode

@dynamic delegate;

// TODO: Support preview images with HTTP Live Streaming videos.

#pragma mark - Construction and Layout

- (instancetype)initWithCache:(id<A_SImageCacheProtocol>)cache downloader:(id<A_SImageDownloaderProtocol>)downloader
{
  if (!(self = [super initWithCache:cache downloader:downloader])) {
    return nil;
  }

  self.gravity = AVLayerVideoGravityResizeAspect;
  _periodicTimeObserverTimescale = 10000;
  [self addTarget:self action:@selector(tapped) forControlEvents:A_SControlNodeEventTouchUpInside];
  _lastPlaybackTime = kCMTimeZero;
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  
  return self;
}

- (A_SDisplayNode *)constructPlayerNode
{
  A_SVideoNode * __weak weakSelf = self;

  return [[A_SDisplayNode alloc] initWithLayerBlock:^CALayer *{
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] init];
    playerLayer.player = weakSelf.player;
    playerLayer.videoGravity = weakSelf.gravity;
    return playerLayer;
  }];
}

- (AVPlayerItem *)constructPlayerItem
{
  A_SDisplayNodeAssertMainThread();
  A_SDN::MutexLocker l(__instanceLock__);

  AVPlayerItem *playerItem = nil;
  if (_assetURL != nil) {
    playerItem = [[AVPlayerItem alloc] initWithURL:_assetURL];
    _asset = [playerItem asset];
  } else {
    playerItem = [[AVPlayerItem alloc] initWithAsset:_asset];
  }

  playerItem.videoComposition = _videoComposition;
  playerItem.audioMix = _audioMix;
  return playerItem;
}

- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray<NSString *> *)requestedKeys
{
  A_SDisplayNodeAssertMainThread();
  
  for (NSString *key in requestedKeys) {
    NSError *error = nil;
    AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
    if (keyStatus == AVKeyValueStatusFailed) {
      NSLog(@"Asset loading failed with error: %@", error);
      if (_delegateFlags.delegateVideoNodeDidFailToLoadValueForKey) {
        [self.delegate videoNode:self didFailToLoadValueForKey:key asset:asset error:error];
      }
    }
  }
  
  if ([asset isPlayable] == NO) {
    NSLog(@"Asset is not playable.");
    return;
  }

  AVPlayerItem *playerItem = [self constructPlayerItem];
  [self setCurrentItem:playerItem];
  
  if (_player != nil) {
    [_player replaceCurrentItemWithPlayerItem:playerItem];
  } else {
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
  }

  if (_delegateFlags.delegateVideoNodeDidSetCurrentItem) {
    [self.delegate videoNode:self didSetCurrentItem:playerItem];
  }

  if (self.image == nil && self.URL == nil) {
    [self generatePlaceholderImage];
  }
}

- (void)addPlayerItemObservers:(AVPlayerItem *)playerItem
{
  if (playerItem == nil) {
    return;
  }
  
  [playerItem addObserver:self forKeyPath:kStatus options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:A_SVideoNodeContext];
  [playerItem addObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey options:NSKeyValueObservingOptionNew context:A_SVideoNodeContext];
  [playerItem addObserver:self forKeyPath:kplaybackBufferEmpty options:NSKeyValueObservingOptionNew context:A_SVideoNodeContext];
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(didPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(videoNodeDidStall:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(errorWhilePlaying:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(errorWhilePlaying:) name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem
{
  @try {
    [playerItem removeObserver:self forKeyPath:kStatus context:A_SVideoNodeContext];
    [playerItem removeObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey context:A_SVideoNodeContext];
    [playerItem removeObserver:self forKeyPath:kplaybackBufferEmpty context:A_SVideoNodeContext];
  }
  @catch (NSException * __unused exception) {
    NSLog(@"Unnecessary KVO removal");
  }

  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
  [notificationCenter removeObserver:self name: AVPlayerItemPlaybackStalledNotification object:playerItem];
  [notificationCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
  [notificationCenter removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
}

- (void)addPlayerObservers:(AVPlayer *)player
{
  if (player == nil) {
    return;
  }

  [player addObserver:self forKeyPath:kRate options:NSKeyValueObservingOptionNew context:A_SVideoNodeContext];

  __weak __typeof(self) weakSelf = self;
  _timeObserverInterval = CMTimeMake(1, _periodicTimeObserverTimescale);
  _timeObserver = [player addPeriodicTimeObserverForInterval:_timeObserverInterval queue:NULL usingBlock:^(CMTime time){
    [weakSelf periodicTimeObserver:time];
  }];
}

- (void) removePlayerObservers:(AVPlayer *)player
{
  if (_timeObserver != nil) {
    [player removeTimeObserver:_timeObserver];
    _timeObserver = nil;
  }

  @try {
    [player removeObserver:self forKeyPath:kRate context:A_SVideoNodeContext];
  }
  @catch (NSException * __unused exception) {
    NSLog(@"Unnecessary KVO removal");
  }
}

- (void)layout
{
  [super layout];
  // The _playerNode wraps AVPlayerLayer, and therefore should extend across the entire bounds.
  _playerNode.frame = self.bounds;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  __instanceLock__.lock();
  A_SDisplayNode *playerNode = _playerNode;
  __instanceLock__.unlock();

  CGSize calculatedSize = constrainedSize;
  
  // Prevent crashes through if infinite width or height
  if (isinf(calculatedSize.width) || isinf(calculatedSize.height)) {
    A_SDisplayNodeAssert(NO, @"Infinite width or height in A_SVideoNode");
    calculatedSize = CGSizeZero;
  }
  
  if (playerNode != nil) {
    playerNode.style.preferredSize = calculatedSize;
    [playerNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, calculatedSize)];
  }
  
  return calculatedSize;
}

- (void)generatePlaceholderImage
{
  A_SVideoNode * __weak weakSelf = self;
  AVAsset *asset = self.asset;

  [self imageAtTime:kCMTimeZero completionHandler:^(UIImage *image) {
    A_SPerformBlockOnMainThread(^{
      // Ensure the asset hasn't changed since the image request was made
      if (A_SAssetIsEqual(weakSelf.asset, asset)) {
        [weakSelf setVideoPlaceholderImage:image];
      }
    });
  }];
}

- (void)imageAtTime:(CMTime)imageTime completionHandler:(void(^)(UIImage *image))completionHandler
{
  A_SPerformBlockOnBackgroundThread(^{
    AVAsset *asset = self.asset;

    // Skip the asset image generation if we don't have any tracks available that are capable of supporting it
    NSArray<AVAssetTrack *>* visualAssetArray = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    if (visualAssetArray.count == 0) {
      completionHandler(nil);
      return;
    }

    AVAssetImageGenerator *previewImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    previewImageGenerator.appliesPreferredTrackTransform = YES;
    previewImageGenerator.videoComposition = _videoComposition;

    [previewImageGenerator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:imageTime]]
                                                completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                                  if (error != nil && result != AVAssetImageGeneratorCancelled) {
                                                    NSLog(@"Asset preview image generation failed with error: %@", error);
                                                  }
                                                  completionHandler(image ? [UIImage imageWithCGImage:image] : nil);
                                                }];
  });
}

- (void)setVideoPlaceholderImage:(UIImage *)image
{
  __instanceLock__.lock();
  NSString *gravity = _gravity;
  __instanceLock__.unlock();
  
  if (image != nil) {
    self.contentMode = A_SContentModeFromVideoGravity(gravity);
  }
  self.image = image;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  A_SDN::MutexLocker l(__instanceLock__);

  if (object == _currentPlayerItem) {
    if ([keyPath isEqualToString:kStatus]) {
      if ([change[NSKeyValueChangeNewKey] integerValue] == AVPlayerItemStatusReadyToPlay) {
        if (self.playerState != A_SVideoNodePlayerStatePlaying) {
          self.playerState = A_SVideoNodePlayerStateReadyToPlay;
          if (_shouldBePlaying && A_SInterfaceStateIncludesVisible(self.interfaceState)) {
            [self play];
          }
        }
        // If we don't yet have a placeholder image update it now that we should have data available for it
        if (self.image == nil && self.URL == nil) {
          [self generatePlaceholderImage];
        }
      }
    } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUpKey]) {
      BOOL likelyToKeepUp = [change[NSKeyValueChangeNewKey] boolValue];
      if (likelyToKeepUp && self.playerState == A_SVideoNodePlayerStatePlaying) {
        return;
      }
      if (!likelyToKeepUp) {
        self.playerState = A_SVideoNodePlayerStateLoading;
      } else if (self.playerState != A_SVideoNodePlayerStateFinished) {
        self.playerState = A_SVideoNodePlayerStatePlaybackLikelyToKeepUpButNotPlaying;
      }
      if (_shouldBePlaying && (_shouldAggressivelyRecoverFromStall || likelyToKeepUp) && A_SInterfaceStateIncludesVisible(self.interfaceState)) {
        if (self.playerState == A_SVideoNodePlayerStateLoading && _delegateFlags.delegateVideoNodeDidRecoverFromStall) {
          [self.delegate videoNodeDidRecoverFromStall:self];
        }
        [self play]; // autoresume after buffer catches up
      }
    } else if ([keyPath isEqualToString:kplaybackBufferEmpty]) {
      if (_shouldBePlaying && [change[NSKeyValueChangeNewKey] boolValue] == YES && A_SInterfaceStateIncludesVisible(self.interfaceState)) {
        self.playerState = A_SVideoNodePlayerStateLoading;
      }
    }
  } else if (object == _player) {
    if ([keyPath isEqualToString:kRate]) {
      if ([change[NSKeyValueChangeNewKey] floatValue] == 0.0) {
        if (self.playerState == A_SVideoNodePlayerStatePlaying) {
          self.playerState = A_SVideoNodePlayerStatePaused;
        }
      } else {
        self.playerState = A_SVideoNodePlayerStatePlaying;
      }
    }
  }
}

- (void)tapped
{
  if (_delegateFlags.delegateDidTapVideoNode) {
    [self.delegate didTapVideoNode:self];
    
  } else {
    if (_shouldBePlaying) {
      [self pause];
    } else {
      [self play];
    }
  }
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  
  A_SDN::MutexLocker l(__instanceLock__);
  AVAsset *asset = self.asset;
  // Return immediately if the asset is nil;
  if (asset == nil || self.playerState != A_SVideoNodePlayerStateUnknown) {
      return;
  }

  self.playerState = A_SVideoNodePlayerStateLoading;
  if (_delegateFlags.delegateVideoNodeDidStartInitialLoading) {
      [self.delegate videoNodeDidStartInitialLoading:self];
  }
  
  NSArray<NSString *> *requestedKeys = @[@"playable"];
  [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
    A_SPerformBlockOnMainThread(^{
      if (_delegateFlags.delegateVideoNodeDidFinishInitialLoading) {
        [self.delegate videoNodeDidFinishInitialLoading:self];
      }
      [self prepareToPlayAsset:asset withKeys:requestedKeys];
    });
  }];
}

- (void)periodicTimeObserver:(CMTime)time
{
  NSTimeInterval timeInSeconds = CMTimeGetSeconds(time);
  if (timeInSeconds <= 0) {
    return;
  }
  
  if (_delegateFlags.delegateVideoNodeDidPlayToTimeInterval) {
    [self.delegate videoNode:self didPlayToTimeInterval:timeInSeconds];
    
  }
}

- (void)didExitPreloadState
{
  [super didExitPreloadState];
  
  {
    A_SDN::MutexLocker l(__instanceLock__);

    self.player = nil;
    self.currentItem = nil;
    self.playerState = A_SVideoNodePlayerStateUnknown;
  }
}

- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  
  __instanceLock__.lock();
  BOOL shouldPlay = NO;
  if (_shouldBePlaying || _shouldAutoplay) {
    if (_player != nil && CMTIME_IS_VALID(_lastPlaybackTime)) {
      [_player seekToTime:_lastPlaybackTime];
    }
    shouldPlay = YES;
  }
  __instanceLock__.unlock();
  
  if (shouldPlay) {
    [self play];
  }
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  
  A_SDN::MutexLocker l(__instanceLock__);
  
  if (_shouldBePlaying) {
    [self pause];
    if (_player != nil && CMTIME_IS_VALID(_player.currentTime)) {
      _lastPlaybackTime = _player.currentTime;
    }
    _shouldBePlaying = YES;
  }
}

#pragma mark - Video Properties

- (void)setPlayerState:(A_SVideoNodePlayerState)playerState
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  A_SVideoNodePlayerState oldState = _playerState;
  
  if (oldState == playerState) {
    return;
  }
  
  if (_delegateFlags.delegateVideoNodeWillChangePlayerStateToState) {
    [self.delegate videoNode:self willChangePlayerState:oldState toState:playerState];
  }
  
  _playerState = playerState;
}

- (void)setAssetURL:(NSURL *)assetURL
{
  A_SDisplayNodeAssertMainThread();
  
  if (A_SObjectIsEqual(assetURL, self.assetURL) == NO) {
    [self setAndFetchAsset:[AVURLAsset assetWithURL:assetURL] url:assetURL];
  }
}

- (NSURL *)assetURL
{
  A_SDN::MutexLocker l(__instanceLock__);

  if (_assetURL != nil) {
    return _assetURL;
  } else if ([_asset isKindOfClass:AVURLAsset.class]) {
    return ((AVURLAsset *)_asset).URL;
  }

  return nil;
}

- (void)setAsset:(AVAsset *)asset
{
  A_SDisplayNodeAssertMainThread();
  
  if (A_SAssetIsEqual(asset, self.asset) == NO) {
    [self setAndFetchAsset:asset url:nil];
  }
}

- (AVAsset *)asset
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _asset;
}

- (void)setAndFetchAsset:(AVAsset *)asset url:(NSURL *)assetURL
{
  A_SDisplayNodeAssertMainThread();
  
  [self didExitPreloadState];
  
  {
    A_SDN::MutexLocker l(__instanceLock__);
    self.videoPlaceholderImage = nil;
    _asset = asset;
    _assetURL = assetURL;
  }
  
  [self setNeedsPreload];
}

- (void)setVideoComposition:(AVVideoComposition *)videoComposition
{
  A_SDN::MutexLocker l(__instanceLock__);

  _videoComposition = videoComposition;
  _currentPlayerItem.videoComposition = videoComposition;
}

- (AVVideoComposition *)videoComposition
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _videoComposition;
}

- (void)setAudioMix:(AVAudioMix *)audioMix
{
  A_SDN::MutexLocker l(__instanceLock__);

  _audioMix = audioMix;
  _currentPlayerItem.audioMix = audioMix;
}

- (AVAudioMix *)audioMix
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _audioMix;
}

- (AVPlayer *)player
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _player;
}

- (AVPlayerLayer *)playerLayer
{
  A_SDN::MutexLocker l(__instanceLock__);
  return (AVPlayerLayer *)_playerNode.layer;
}

- (void)setDelegate:(id<A_SVideoNodeDelegate>)delegate
{
  [super setDelegate:delegate];
  
  if (delegate == nil) {
    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
  } else {
    _delegateFlags.delegateVideNodeShouldChangePlayerStateTo = [delegate respondsToSelector:@selector(videoNode:shouldChangePlayerStateTo:)];
    _delegateFlags.delegateVideoDidPlayToEnd = [delegate respondsToSelector:@selector(videoDidPlayToEnd:)];
    _delegateFlags.delegateDidTapVideoNode = [delegate respondsToSelector:@selector(didTapVideoNode:)];
    _delegateFlags.delegateVideoNodeWillChangePlayerStateToState = [delegate respondsToSelector:@selector(videoNode:willChangePlayerState:toState:)];
    _delegateFlags.delegateVideoNodeDidPlayToTimeInterval = [delegate respondsToSelector:@selector(videoNode:didPlayToTimeInterval:)];
    _delegateFlags.delegateVideoNodeDidStartInitialLoading = [delegate respondsToSelector:@selector(videoNodeDidStartInitialLoading:)];
    _delegateFlags.delegateVideoNodeDidFinishInitialLoading = [delegate respondsToSelector:@selector(videoNodeDidFinishInitialLoading:)];
    _delegateFlags.delegateVideoNodeDidSetCurrentItem = [delegate respondsToSelector:@selector(videoNode:didSetCurrentItem:)];
    _delegateFlags.delegateVideoNodeDidStallAtTimeInterval = [delegate respondsToSelector:@selector(videoNode:didStallAtTimeInterval:)];
    _delegateFlags.delegateVideoNodeDidRecoverFromStall = [delegate respondsToSelector:@selector(videoNodeDidRecoverFromStall:)];
    _delegateFlags.delegateVideoNodeDidFailToLoadValueForKey = [delegate respondsToSelector:@selector(videoNode:didFailToLoadValueForKey:asset:error:)];
  }
}

- (void)setGravity:(NSString *)gravity
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_playerNode.isNodeLoaded) {
    ((AVPlayerLayer *)_playerNode.layer).videoGravity = gravity;
  }
  self.contentMode = A_SContentModeFromVideoGravity(gravity);
  _gravity = gravity;
}

- (NSString *)gravity
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _gravity;
}

- (BOOL)muted
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _muted;
}

- (void)setMuted:(BOOL)muted
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  _player.muted = muted;
  _muted = muted;
}

#pragma mark - Video Playback

- (void)play
{
  __instanceLock__.lock();

  if (![self isStateChangeValid:A_SVideoNodePlayerStatePlaying]) {
    __instanceLock__.unlock();
    return;
  }

  if (_player == nil) {
    __instanceLock__.unlock();
      [self setNeedsPreload];
    __instanceLock__.lock();
  }

  if (_playerNode == nil) {
    _playerNode = [self constructPlayerNode];

    __instanceLock__.unlock();
      [self addSubnode:_playerNode];
    __instanceLock__.lock();
      
    [self setNeedsLayout];
  }
  
  
  [_player play];
  _shouldBePlaying = YES;
  __instanceLock__.unlock();
}

- (BOOL)ready
{
  return _currentPlayerItem.status == AVPlayerItemStatusReadyToPlay;
}

- (void)pause
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (![self isStateChangeValid:A_SVideoNodePlayerStatePaused]) {
    return;
  }
  [_player pause];
  _shouldBePlaying = NO;
}

- (BOOL)isPlaying
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  return (_player.rate > 0 && !_player.error);
}

- (BOOL)isStateChangeValid:(A_SVideoNodePlayerState)state
{
  if (_delegateFlags.delegateVideNodeShouldChangePlayerStateTo) {
    if (![self.delegate videoNode:self shouldChangePlayerStateTo:state]) {
      return NO;
    }
  }
  return YES;
}

- (void)resetToPlaceholder
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  if (_playerNode != nil) {
    [_playerNode removeFromSupernode];
    _playerNode = nil;
  }
  
  [_player seekToTime:kCMTimeZero];
  [self pause];
}


#pragma mark - Playback observers

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  if (self.shouldBePlaying && self.isVisible) {
    [self play];
  }
}

- (void)didPlayToEnd:(NSNotification *)notification
{
  self.playerState = A_SVideoNodePlayerStateFinished;
  if (_delegateFlags.delegateVideoDidPlayToEnd) {
    [self.delegate videoDidPlayToEnd:self];
  }

  if (_shouldAutorepeat) {
    [_player seekToTime:kCMTimeZero];
    [self play];
  } else {
    [self pause];
  }
}

- (void)videoNodeDidStall:(NSNotification *)notification
{
  self.playerState = A_SVideoNodePlayerStateLoading;
  if (_delegateFlags.delegateVideoNodeDidStallAtTimeInterval) {
    [self.delegate videoNode:self didStallAtTimeInterval:CMTimeGetSeconds(_player.currentItem.currentTime)];
  }
}

- (void)errorWhilePlaying:(NSNotification *)notification
{
  if ([notification.name isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification]) {
    NSLog(@"Failed to play video");
  } else if ([notification.name isEqualToString:AVPlayerItemNewErrorLogEntryNotification]) {
    AVPlayerItem *item = (AVPlayerItem *)notification.object;
    AVPlayerItemErrorLogEvent *logEvent = item.errorLog.events.lastObject;
    NSLog(@"AVPlayerItem error log entry added for video with error %@ status %@", item.error,
          (item.status == AVPlayerItemStatusFailed ? @"FAILED" : [NSString stringWithFormat:@"%ld", (long)item.status]));
    NSLog(@"Item is %@", item);
    
    if (logEvent) {
      NSLog(@"Log code %ld domain %@ comment %@", (long)logEvent.errorStatusCode, logEvent.errorDomain, logEvent.errorComment);
    }
  }
}

#pragma mark - Internal Properties

- (AVPlayerItem *)currentItem
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _currentPlayerItem;
}

- (void)setCurrentItem:(AVPlayerItem *)currentItem
{
  A_SDN::MutexLocker l(__instanceLock__);

  [self removePlayerItemObservers:_currentPlayerItem];

  _currentPlayerItem = currentItem;

  if (currentItem != nil) {
    [self addPlayerItemObservers:currentItem];
  }
}

- (A_SDisplayNode *)playerNode
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _playerNode;
}

- (void)setPlayerNode:(A_SDisplayNode *)playerNode
{
  __instanceLock__.lock();
  _playerNode = playerNode;
  __instanceLock__.unlock();

  [self setNeedsLayout];
}

- (void)setPlayer:(AVPlayer *)player
{
  A_SDN::MutexLocker l(__instanceLock__);

  [self removePlayerObservers:_player];

  _player = player;
  player.muted = _muted;
  ((AVPlayerLayer *)_playerNode.layer).player = player;

  if (player != nil) {
    [self addPlayerObservers:player];
  }
}

- (BOOL)shouldBePlaying
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _shouldBePlaying;
}

- (void)setShouldBePlaying:(BOOL)shouldBePlaying
{
  A_SDN::MutexLocker l(__instanceLock__);
  _shouldBePlaying = shouldBePlaying;
}

#pragma mark - Lifecycle

- (void)dealloc
{
  [self removePlayerItemObservers:_currentPlayerItem];
  [self removePlayerObservers:_player];

  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end
