//
//  A_SVideoPlayerNode.mm
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

#import <Foundation/Foundation.h>

#if TARGET_OS_IOS

#import <Async_DisplayKit/A_SVideoPlayerNode.h>

#import <AVFoundation/AVFoundation.h>

#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/A_SDefaultPlaybackButton.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>

static void *A_SVideoPlayerNodeContext = &A_SVideoPlayerNodeContext;

@interface A_SVideoPlayerNode() <A_SVideoNodeDelegate, A_SVideoPlayerNodeDelegate>
{
  __weak id<A_SVideoPlayerNodeDelegate> _delegate;

  struct {
    unsigned int delegateNeededDefaultControls:1;
    unsigned int delegateCustomControls:1;
    unsigned int delegateSpinnerTintColor:1;
    unsigned int delegateSpinnerStyle:1;
    unsigned int delegatePlaybackButtonTint:1;
    unsigned int delegateFullScreenButtonImage:1;
    unsigned int delegateScrubberMaximumTrackTintColor:1;
    unsigned int delegateScrubberMinimumTrackTintColor:1;
    unsigned int delegateScrubberThumbTintColor:1;
    unsigned int delegateScrubberThumbImage:1;
    unsigned int delegateTimeLabelAttributes:1;
    unsigned int delegateTimeLabelAttributedString:1;
    unsigned int delegateLayoutSpecForControls:1;
    unsigned int delegateVideoNodeDidPlayToTime:1;
    unsigned int delegateVideoNodeWillChangeState:1;
    unsigned int delegateVideoNodeShouldChangeState:1;
    unsigned int delegateVideoNodePlaybackDidFinish:1;
    unsigned int delegateDidTapVideoPlayerNode:1;
    unsigned int delegateDidTapFullScreenButtonNode:1;
    unsigned int delegateVideoPlayerNodeDidSetCurrentItem:1;
    unsigned int delegateVideoPlayerNodeDidStallAtTimeInterval:1;
    unsigned int delegateVideoPlayerNodeDidStartInitialLoading:1;
    unsigned int delegateVideoPlayerNodeDidFinishInitialLoading:1;
    unsigned int delegateVideoPlayerNodeDidRecoverFromStall:1;
  } _delegateFlags;
  
  // The asset passed in the initializer will be assigned as pending asset. As soon as the first
  // preload state happened all further asset handling is made by using the asset of the backing
  // video node
  AVAsset *_pendingAsset;
  
  // The backing video node. Ideally this is the source of truth and the video player node should
  // not handle anything related to asset management
  A_SVideoNode *_videoNode;

  NSArray *_neededDefaultControls;

  NSMutableDictionary *_cachedControls;

  A_SDefaultPlaybackButton *_playbackButtonNode;
  A_SButtonNode *_fullScreenButtonNode;
  A_STextNode  *_elapsedTextNode;
  A_STextNode  *_durationTextNode;
  A_SDisplayNode *_scrubberNode;
  A_SStackLayoutSpec *_controlFlexGrowSpacerSpec;
  A_SDisplayNode *_spinnerNode;

  BOOL _isSeeking;
  CMTime _duration;

  BOOL _controlsDisabled;

  BOOL _shouldAutoPlay;
  BOOL _shouldAutoRepeat;
  BOOL _muted;
  int32_t _periodicTimeObserverTimescale;
  NSString *_gravity;

  BOOL _shouldAggressivelyRecoverFromStall;

  UIColor *_defaultControlsColor;
}

@end

@implementation A_SVideoPlayerNode

@dynamic placeholderImageURL;

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }

  [self _initControlsAndVideoNode];

  return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset
{
  if (!(self = [self init])) {
    return nil;
  }
  
  _pendingAsset = asset;
  
  return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
  return [self initWithAsset:[AVAsset assetWithURL:URL]];
}

- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix
{
  if (!(self = [self initWithAsset:asset])) {
    return nil;
  }
  
  _videoNode.videoComposition = videoComposition;
  _videoNode.audioMix = audioMix;

  return self;
}

- (void)_initControlsAndVideoNode
{
  _defaultControlsColor = [UIColor whiteColor];
  _cachedControls = [[NSMutableDictionary alloc] init];
  
  _videoNode = [[A_SVideoNode alloc] init];
  _videoNode.delegate = self;
  [self addSubnode:_videoNode];
}

#pragma mark - Setter / Getter

- (void)setAssetURL:(NSURL *)assetURL
{
  A_SDisplayNodeAssertMainThread();
  
  self.asset = [AVAsset assetWithURL:assetURL];
}

- (NSURL *)assetURL
{
  NSURL *url = nil;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if ([_pendingAsset isKindOfClass:AVURLAsset.class]) {
      url = ((AVURLAsset *)_pendingAsset).URL;
    }
  }
  
  return url ?: _videoNode.assetURL;
}

- (void)setAsset:(AVAsset *)asset
{
  A_SDisplayNodeAssertMainThread();

  __instanceLock__.lock();
  
  // Clean out pending asset
  _pendingAsset = nil;
  
  // Set asset based on interface state
  if ((A_SInterfaceStateIncludesPreload(self.interfaceState))) {
    // Don't hold the lock while accessing the subnode
    __instanceLock__.unlock();
    _videoNode.asset = asset;
    return;
  }
  
  _pendingAsset = asset;
  __instanceLock__.unlock();
}

- (AVAsset *)asset
{
  __instanceLock__.lock();
  AVAsset *asset = _pendingAsset;
  __instanceLock__.unlock();

  return asset ?: _videoNode.asset;
}

#pragma mark - A_SDisplayNode

- (void)didLoad
{
  [super didLoad];
  {
    A_SDN::MutexLocker l(__instanceLock__);
    [self createControls];
  }
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  
  AVAsset *pendingAsset = nil;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    pendingAsset = _pendingAsset;
    _pendingAsset = nil;
  }

  // If we enter preload state we apply the pending asset to load to the video node so it can start and fetch the asset
  if (pendingAsset != nil && _videoNode.asset != pendingAsset) {
    _videoNode.asset = pendingAsset;
  }
}

- (BOOL)supportsLayerBacking
{
  return NO;
}

#pragma mark - UI

- (void)createControls
{
  {
    A_SDN::MutexLocker l(__instanceLock__);

    if (_controlsDisabled) {
      return;
    }

    if (_neededDefaultControls == nil) {
      _neededDefaultControls = [self createDefaultControlElementArray];
    }

    if (_cachedControls == nil) {
      _cachedControls = [[NSMutableDictionary alloc] init];
    }

    for (id object in _neededDefaultControls) {
      A_SVideoPlayerNodeControlType type = (A_SVideoPlayerNodeControlType)[object integerValue];
      switch (type) {
        case A_SVideoPlayerNodeControlTypePlaybackButton:
          [self _locked_createPlaybackButton];
          break;
        case A_SVideoPlayerNodeControlTypeElapsedText:
          [self _locked_createElapsedTextField];
          break;
        case A_SVideoPlayerNodeControlTypeDurationText:
          [self _locked_createDurationTextField];
          break;
        case A_SVideoPlayerNodeControlTypeScrubber:
          [self _locked_createScrubber];
          break;
        case A_SVideoPlayerNodeControlTypeFullScreenButton:
          [self _locked_createFullScreenButton];
          break;
        case A_SVideoPlayerNodeControlTypeFlexGrowSpacer:
          [self _locked_createControlFlexGrowSpacer];
          break;
        default:
          break;
      }
    }

    if (_delegateFlags.delegateCustomControls && _delegateFlags.delegateLayoutSpecForControls) {
      NSDictionary *customControls = [_delegate videoPlayerNodeCustomControls:self];
      for (id key in customControls) {
        id node = customControls[key];
        if (![node isKindOfClass:[A_SDisplayNode class]]) {
          continue;
        }

        [self addSubnode:node];
        [_cachedControls setObject:node forKey:key];
      }
    }
  }

  A_SPerformBlockOnMainThread(^{
    [self setNeedsLayout];
  });
}

- (NSArray *)createDefaultControlElementArray
{
  if (_delegateFlags.delegateNeededDefaultControls) {
    return [_delegate videoPlayerNodeNeededDefaultControls:self];
  }

  return @[ @(A_SVideoPlayerNodeControlTypePlaybackButton),
            @(A_SVideoPlayerNodeControlTypeElapsedText),
            @(A_SVideoPlayerNodeControlTypeScrubber),
            @(A_SVideoPlayerNodeControlTypeDurationText) ];
}

- (void)removeControls
{
  for (A_SDisplayNode *node in [_cachedControls objectEnumerator]) {
    [node removeFromSupernode];
  }

  [self cleanCachedControls];
}

- (void)cleanCachedControls
{
  [_cachedControls removeAllObjects];

  _playbackButtonNode = nil;
  _fullScreenButtonNode = nil;
  _elapsedTextNode = nil;
  _durationTextNode = nil;
  _scrubberNode = nil;
}

- (void)_locked_createPlaybackButton
{
  if (_playbackButtonNode == nil) {
    _playbackButtonNode = [[A_SDefaultPlaybackButton alloc] init];
    _playbackButtonNode.style.preferredSize = CGSizeMake(16.0, 22.0);

    if (_delegateFlags.delegatePlaybackButtonTint) {
      _playbackButtonNode.tintColor = [_delegate videoPlayerNodePlaybackButtonTint:self];
    } else {
      _playbackButtonNode.tintColor = _defaultControlsColor;
    }

    if (_videoNode.playerState == A_SVideoNodePlayerStatePlaying) {
      _playbackButtonNode.buttonType = A_SDefaultPlaybackButtonTypePause;
    }

    [_playbackButtonNode addTarget:self action:@selector(didTapPlaybackButton:) forControlEvents:A_SControlNodeEventTouchUpInside];
    [_cachedControls setObject:_playbackButtonNode forKey:@(A_SVideoPlayerNodeControlTypePlaybackButton)];
  }

  [self addSubnode:_playbackButtonNode];
}

- (void)_locked_createFullScreenButton
{
  if (_fullScreenButtonNode == nil) {
    _fullScreenButtonNode = [[A_SButtonNode alloc] init];
    _fullScreenButtonNode.style.preferredSize = CGSizeMake(16.0, 22.0);
    
    if (_delegateFlags.delegateFullScreenButtonImage) {
      [_fullScreenButtonNode setImage:[_delegate videoPlayerNodeFullScreenButtonImage:self] forState:UIControlStateNormal];
    }

    [_fullScreenButtonNode addTarget:self action:@selector(didTapFullScreenButton:) forControlEvents:A_SControlNodeEventTouchUpInside];
    [_cachedControls setObject:_fullScreenButtonNode forKey:@(A_SVideoPlayerNodeControlTypeFullScreenButton)];
  }
  
  [self addSubnode:_fullScreenButtonNode];
}

- (void)_locked_createElapsedTextField
{
  if (_elapsedTextNode == nil) {
    _elapsedTextNode = [[A_STextNode alloc] init];
    _elapsedTextNode.attributedText = [self timeLabelAttributedStringForString:@"00:00"
                                                                  forControlType:A_SVideoPlayerNodeControlTypeElapsedText];
    _elapsedTextNode.truncationMode = NSLineBreakByClipping;

    [_cachedControls setObject:_elapsedTextNode forKey:@(A_SVideoPlayerNodeControlTypeElapsedText)];
  }
  [self addSubnode:_elapsedTextNode];
}

- (void)_locked_createDurationTextField
{
  if (_durationTextNode == nil) {
    _durationTextNode = [[A_STextNode alloc] init];
    _durationTextNode.attributedText = [self timeLabelAttributedStringForString:@"00:00"
                                                                   forControlType:A_SVideoPlayerNodeControlTypeDurationText];
    _durationTextNode.truncationMode = NSLineBreakByClipping;

    [_cachedControls setObject:_durationTextNode forKey:@(A_SVideoPlayerNodeControlTypeDurationText)];
  }
  [self updateDurationTimeLabel];
  [self addSubnode:_durationTextNode];
}

- (void)_locked_createScrubber
{
  if (_scrubberNode == nil) {
    __weak __typeof__(self) weakSelf = self;
    _scrubberNode = [[A_SDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull {
      __typeof__(self) strongSelf = weakSelf;
      
      UISlider *slider = [[UISlider alloc] initWithFrame:CGRectZero];
      slider.minimumValue = 0.0;
      slider.maximumValue = 1.0;

      if (_delegateFlags.delegateScrubberMinimumTrackTintColor) {
        slider.minimumTrackTintColor  = [strongSelf.delegate videoPlayerNodeScrubberMinimumTrackTint:strongSelf];
      }

      if (_delegateFlags.delegateScrubberMaximumTrackTintColor) {
        slider.maximumTrackTintColor  = [strongSelf.delegate videoPlayerNodeScrubberMaximumTrackTint:strongSelf];
      }

      if (_delegateFlags.delegateScrubberThumbTintColor) {
        slider.thumbTintColor  = [strongSelf.delegate videoPlayerNodeScrubberThumbTint:strongSelf];
      }

      if (_delegateFlags.delegateScrubberThumbImage) {
        UIImage *thumbImage = [strongSelf.delegate videoPlayerNodeScrubberThumbImage:strongSelf];
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
      }


      [slider addTarget:strongSelf action:@selector(beginSeek) forControlEvents:UIControlEventTouchDown];
      [slider addTarget:strongSelf action:@selector(endSeek) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
      [slider addTarget:strongSelf action:@selector(seekTimeDidChange:) forControlEvents:UIControlEventValueChanged];

      return slider;
    }];

    _scrubberNode.style.flexShrink = 1;

    [_cachedControls setObject:_scrubberNode forKey:@(A_SVideoPlayerNodeControlTypeScrubber)];
  }

  [self addSubnode:_scrubberNode];
}

- (void)_locked_createControlFlexGrowSpacer
{
  if (_controlFlexGrowSpacerSpec == nil) {
    _controlFlexGrowSpacerSpec = [[A_SStackLayoutSpec alloc] init];
    _controlFlexGrowSpacerSpec.style.flexGrow = 1.0;
  }

  [_cachedControls setObject:_controlFlexGrowSpacerSpec forKey:@(A_SVideoPlayerNodeControlTypeFlexGrowSpacer)];
}

- (void)updateDurationTimeLabel
{
  if (!_durationTextNode) {
    return;
  }
  NSString *formattedDuration = [self timeStringForCMTime:_duration forTimeLabelType:A_SVideoPlayerNodeControlTypeDurationText];
  _durationTextNode.attributedText = [self timeLabelAttributedStringForString:formattedDuration forControlType:A_SVideoPlayerNodeControlTypeDurationText];
}

- (void)updateElapsedTimeLabel:(NSTimeInterval)seconds
{
  if (!_elapsedTextNode) {
    return;
  }
  NSString *formattedElapsed = [self timeStringForCMTime:CMTimeMakeWithSeconds( seconds, _videoNode.periodicTimeObserverTimescale ) forTimeLabelType:A_SVideoPlayerNodeControlTypeElapsedText];
  _elapsedTextNode.attributedText = [self timeLabelAttributedStringForString:formattedElapsed forControlType:A_SVideoPlayerNodeControlTypeElapsedText];
}

- (NSAttributedString*)timeLabelAttributedStringForString:(NSString*)string forControlType:(A_SVideoPlayerNodeControlType)controlType
{
  NSDictionary *options;
  if (_delegateFlags.delegateTimeLabelAttributes) {
    options = [_delegate videoPlayerNodeTimeLabelAttributes:self timeLabelType:controlType];
  } else {
    options = @{
                NSFontAttributeName : [UIFont systemFontOfSize:12.0],
                NSForegroundColorAttributeName: _defaultControlsColor
                };
  }


  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:string attributes:options];

  return attributedString;
}

#pragma mark - A_SVideoNodeDelegate
- (void)videoNode:(A_SVideoNode *)videoNode willChangePlayerState:(A_SVideoNodePlayerState)state toState:(A_SVideoNodePlayerState)toState
{
  if (_delegateFlags.delegateVideoNodeWillChangeState) {
    [_delegate videoPlayerNode:self willChangeVideoNodeState:state toVideoNodeState:toState];
  }

  if (toState == A_SVideoNodePlayerStateReadyToPlay) {
    _duration = _videoNode.currentItem.duration;
    [self updateDurationTimeLabel];
  }

  if (toState == A_SVideoNodePlayerStatePlaying) {
    _playbackButtonNode.buttonType = A_SDefaultPlaybackButtonTypePause;
    [self removeSpinner];
  } else if (toState != A_SVideoNodePlayerStatePlaybackLikelyToKeepUpButNotPlaying && toState != A_SVideoNodePlayerStateReadyToPlay) {
    _playbackButtonNode.buttonType = A_SDefaultPlaybackButtonTypePlay;
  }

  if (toState == A_SVideoNodePlayerStateLoading || toState == A_SVideoNodePlayerStateInitialLoading) {
    [self showSpinner];
  }

  if (toState == A_SVideoNodePlayerStateReadyToPlay || toState == A_SVideoNodePlayerStatePaused || toState == A_SVideoNodePlayerStatePlaybackLikelyToKeepUpButNotPlaying) {
    [self removeSpinner];
  }
}

- (BOOL)videoNode:(A_SVideoNode *)videoNode shouldChangePlayerStateTo:(A_SVideoNodePlayerState)state
{
  if (_delegateFlags.delegateVideoNodeShouldChangeState) {
    return [_delegate videoPlayerNode:self shouldChangeVideoNodeStateTo:state];
  }
  return YES;
}

- (void)videoNode:(A_SVideoNode *)videoNode didPlayToTimeInterval:(NSTimeInterval)timeInterval
{
  if (_delegateFlags.delegateVideoNodeDidPlayToTime) {
    [_delegate videoPlayerNode:self didPlayToTime:_videoNode.player.currentTime];
  }

  if (_isSeeking) {
    return;
  }

  if (_elapsedTextNode) {
    [self updateElapsedTimeLabel:timeInterval];
  }

  if (_scrubberNode) {
    [(UISlider*)_scrubberNode.view setValue:( timeInterval / CMTimeGetSeconds(_duration) ) animated:NO];
  }
}

- (void)videoDidPlayToEnd:(A_SVideoNode *)videoNode
{
  if (_delegateFlags.delegateVideoNodePlaybackDidFinish) {
    [_delegate videoPlayerNodeDidPlayToEnd:self];
  }
}

- (void)didTapVideoNode:(A_SVideoNode *)videoNode
{
  if (_delegateFlags.delegateDidTapVideoPlayerNode) {
    [_delegate didTapVideoPlayerNode:self];
  } else {
    [self togglePlayPause];
  }
}

- (void)videoNode:(A_SVideoNode *)videoNode didSetCurrentItem:(AVPlayerItem *)currentItem
{
  if (_delegateFlags.delegateVideoPlayerNodeDidSetCurrentItem) {
    [_delegate videoPlayerNode:self didSetCurrentItem:currentItem];
  }
}

- (void)videoNode:(A_SVideoNode *)videoNode didStallAtTimeInterval:(NSTimeInterval)timeInterval
{
  if (_delegateFlags.delegateVideoPlayerNodeDidStallAtTimeInterval) {
    [_delegate videoPlayerNode:self didStallAtTimeInterval:timeInterval];
  }
}

- (void)videoNodeDidStartInitialLoading:(A_SVideoNode *)videoNode
{
  if (_delegateFlags.delegateVideoPlayerNodeDidStartInitialLoading) {
    [_delegate videoPlayerNodeDidStartInitialLoading:self];
  }
}

- (void)videoNodeDidFinishInitialLoading:(A_SVideoNode *)videoNode
{
  if (_delegateFlags.delegateVideoPlayerNodeDidFinishInitialLoading) {
    [_delegate videoPlayerNodeDidFinishInitialLoading:self];
  }
}

- (void)videoNodeDidRecoverFromStall:(A_SVideoNode *)videoNode
{
  if (_delegateFlags.delegateVideoPlayerNodeDidRecoverFromStall) {
    [_delegate videoPlayerNodeDidRecoverFromStall:self];
  }
}

#pragma mark - Actions
- (void)togglePlayPause
{
  if (_videoNode.playerState == A_SVideoNodePlayerStatePlaying) {
    [_videoNode pause];
  } else {
    [_videoNode play];
  }
}

- (void)showSpinner
{
  A_SDN::MutexLocker l(__instanceLock__);

  if (!_spinnerNode) {
  
    __weak __typeof__(self) weakSelf = self;
    _spinnerNode = [[A_SDisplayNode alloc] initWithViewBlock:^UIView *{
      __typeof__(self) strongSelf = weakSelf;
      UIActivityIndicatorView *spinnnerView = [[UIActivityIndicatorView alloc] init];
      spinnnerView.backgroundColor = [UIColor clearColor];

      if (_delegateFlags.delegateSpinnerTintColor) {
        spinnnerView.color = [_delegate videoPlayerNodeSpinnerTint:strongSelf];
      } else {
        spinnnerView.color = _defaultControlsColor;
      }
      
      if (_delegateFlags.delegateSpinnerStyle) {
        spinnnerView.activityIndicatorViewStyle = [_delegate videoPlayerNodeSpinnerStyle:strongSelf];
      }
      
      return spinnnerView;
    }];
    
    _spinnerNode.style.preferredSize = CGSizeMake(44.0, 44.0);

    [self addSubnode:_spinnerNode];
    [self setNeedsLayout];
  }
  [(UIActivityIndicatorView *)_spinnerNode.view startAnimating];
}

- (void)removeSpinner
{
  A_SDN::MutexLocker l(__instanceLock__);

  if (!_spinnerNode) {
    return;
  }
  [_spinnerNode removeFromSupernode];
  _spinnerNode = nil;
}

- (void)didTapPlaybackButton:(A_SControlNode*)node
{
  [self togglePlayPause];
}

- (void)didTapFullScreenButton:(A_SButtonNode*)node
{
  if (_delegateFlags.delegateDidTapFullScreenButtonNode) {
    [_delegate didTapFullScreenButtonNode:node];
  }
}

- (void)beginSeek
{
  _isSeeking = YES;
}

- (void)endSeek
{
  _isSeeking = NO;
}

- (void)seekTimeDidChange:(UISlider*)slider
{
  CGFloat percentage = slider.value * 100;
  [self seekToTime:percentage];
}

#pragma mark - Public API
- (void)seekToTime:(CGFloat)percentComplete
{
  CGFloat seconds = ( CMTimeGetSeconds(_duration) * percentComplete ) / 100;

  [self updateElapsedTimeLabel:seconds];
  [_videoNode.player seekToTime:CMTimeMakeWithSeconds(seconds, _videoNode.periodicTimeObserverTimescale)];

  if (_videoNode.playerState != A_SVideoNodePlayerStatePlaying) {
    [self togglePlayPause];
  }
}

- (void)play
{
  [_videoNode play];
}

- (void)pause
{
  [_videoNode pause];
}

- (BOOL)isPlaying
{
  return [_videoNode isPlaying];
}

- (void)resetToPlaceholder
{
  [_videoNode resetToPlaceholder];
}

- (NSArray *)controlsForLayoutSpec
{
  NSMutableArray *controls = [[NSMutableArray alloc] initWithCapacity:_cachedControls.count];

  if (_cachedControls[ @(A_SVideoPlayerNodeControlTypePlaybackButton) ]) {
    [controls addObject:_cachedControls[ @(A_SVideoPlayerNodeControlTypePlaybackButton) ]];
  }

  if (_cachedControls[ @(A_SVideoPlayerNodeControlTypeElapsedText) ]) {
    [controls addObject:_cachedControls[ @(A_SVideoPlayerNodeControlTypeElapsedText) ]];
  }

  if (_cachedControls[ @(A_SVideoPlayerNodeControlTypeScrubber) ]) {
    [controls addObject:_cachedControls[ @(A_SVideoPlayerNodeControlTypeScrubber) ]];
  }

  if (_cachedControls[ @(A_SVideoPlayerNodeControlTypeDurationText) ]) {
    [controls addObject:_cachedControls[ @(A_SVideoPlayerNodeControlTypeDurationText) ]];
  }
  
  if (_cachedControls[ @(A_SVideoPlayerNodeControlTypeFullScreenButton) ]) {
    [controls addObject:_cachedControls[ @(A_SVideoPlayerNodeControlTypeFullScreenButton) ]];
  }

  return controls;
}


#pragma mark - Layout

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  CGSize maxSize = constrainedSize.max;

  // Prevent crashes through if infinite width or height
  if (isinf(maxSize.width) || isinf(maxSize.height)) {
    A_SDisplayNodeAssert(NO, @"Infinite width or height in A_SVideoPlayerNode");
    maxSize = CGSizeZero;
  }

  _videoNode.style.preferredSize = maxSize;

  A_SLayoutSpec *layoutSpec;
  if (_delegateFlags.delegateLayoutSpecForControls) {
    layoutSpec = [_delegate videoPlayerNodeLayoutSpec:self forControls:_cachedControls forMaximumSize:maxSize];
  } else {
    layoutSpec = [self defaultLayoutSpecThatFits:maxSize];
  }

  NSMutableArray *children = [[NSMutableArray alloc] init];

  if (_spinnerNode) {
    A_SCenterLayoutSpec *centerLayoutSpec = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:A_SCenterLayoutSpecSizingOptionDefault child:_spinnerNode];
    centerLayoutSpec.style.preferredSize = maxSize;
    [children addObject:centerLayoutSpec];
  }

  A_SOverlayLayoutSpec *overlaySpec = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:_videoNode overlay:layoutSpec];
  overlaySpec.style.preferredSize = maxSize;
  [children addObject:overlaySpec];

  return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:children];
}

- (A_SLayoutSpec *)defaultLayoutSpecThatFits:(CGSize)maxSize
{
  _scrubberNode.style.preferredSize = CGSizeMake(maxSize.width, 44.0);

  A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
  spacer.style.flexGrow = 1.0;

  A_SStackLayoutSpec *controlbarSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                            spacing:10.0
                                                                     justifyContent:A_SStackLayoutJustifyContentStart
                                                                         alignItems:A_SStackLayoutAlignItemsCenter
                                                                           children: [self controlsForLayoutSpec] ];
  controlbarSpec.style.alignSelf = A_SStackLayoutAlignSelfStretch;

  UIEdgeInsets insets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

  A_SInsetLayoutSpec *controlbarInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:controlbarSpec];

  controlbarInsetSpec.style.alignSelf = A_SStackLayoutAlignSelfStretch;

  A_SStackLayoutSpec *mainVerticalStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                                                 spacing:0.0
                                                                          justifyContent:A_SStackLayoutJustifyContentStart
                                                                              alignItems:A_SStackLayoutAlignItemsStart
                                                                                children:@[spacer,controlbarInsetSpec]];

  return mainVerticalStack;
}

#pragma mark - Properties
- (id<A_SVideoPlayerNodeDelegate>)delegate
{
  return _delegate;
}

- (void)setDelegate:(id<A_SVideoPlayerNodeDelegate>)delegate
{
  if (delegate == _delegate) {
    return;
  }

  _delegate = delegate;
  
  if (_delegate == nil) {
    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
  } else {
    _delegateFlags.delegateNeededDefaultControls = [_delegate respondsToSelector:@selector(videoPlayerNodeNeededDefaultControls:)];
    _delegateFlags.delegateCustomControls = [_delegate respondsToSelector:@selector(videoPlayerNodeCustomControls:)];
    _delegateFlags.delegateSpinnerTintColor = [_delegate respondsToSelector:@selector(videoPlayerNodeSpinnerTint:)];
    _delegateFlags.delegateSpinnerStyle = [_delegate respondsToSelector:@selector(videoPlayerNodeSpinnerStyle:)];
    _delegateFlags.delegateScrubberMaximumTrackTintColor = [_delegate respondsToSelector:@selector(videoPlayerNodeScrubberMaximumTrackTint:)];
    _delegateFlags.delegateScrubberMinimumTrackTintColor = [_delegate respondsToSelector:@selector(videoPlayerNodeScrubberMinimumTrackTint:)];
    _delegateFlags.delegateScrubberThumbTintColor = [_delegate respondsToSelector:@selector(videoPlayerNodeScrubberThumbTint:)];
    _delegateFlags.delegateScrubberThumbImage = [_delegate respondsToSelector:@selector(videoPlayerNodeScrubberThumbImage:)];
    _delegateFlags.delegateTimeLabelAttributes = [_delegate respondsToSelector:@selector(videoPlayerNodeTimeLabelAttributes:timeLabelType:)];
    _delegateFlags.delegateLayoutSpecForControls = [_delegate respondsToSelector:@selector(videoPlayerNodeLayoutSpec:forControls:forMaximumSize:)];
    _delegateFlags.delegateVideoNodeDidPlayToTime = [_delegate respondsToSelector:@selector(videoPlayerNode:didPlayToTime:)];
    _delegateFlags.delegateVideoNodeWillChangeState = [_delegate respondsToSelector:@selector(videoPlayerNode:willChangeVideoNodeState:toVideoNodeState:)];
    _delegateFlags.delegateVideoNodePlaybackDidFinish = [_delegate respondsToSelector:@selector(videoPlayerNodeDidPlayToEnd:)];
    _delegateFlags.delegateVideoNodeShouldChangeState = [_delegate respondsToSelector:@selector(videoPlayerNode:shouldChangeVideoNodeStateTo:)];
    _delegateFlags.delegateTimeLabelAttributedString = [_delegate respondsToSelector:@selector(videoPlayerNode:timeStringForTimeLabelType:forTime:)];
    _delegateFlags.delegatePlaybackButtonTint = [_delegate respondsToSelector:@selector(videoPlayerNodePlaybackButtonTint:)];
    _delegateFlags.delegateFullScreenButtonImage = [_delegate respondsToSelector:@selector(videoPlayerNodeFullScreenButtonImage:)];
    _delegateFlags.delegateDidTapVideoPlayerNode = [_delegate respondsToSelector:@selector(didTapVideoPlayerNode:)];
    _delegateFlags.delegateDidTapFullScreenButtonNode = [_delegate respondsToSelector:@selector(didTapFullScreenButtonNode:)];
    _delegateFlags.delegateVideoPlayerNodeDidSetCurrentItem = [_delegate respondsToSelector:@selector(videoPlayerNode:didSetCurrentItem:)];
    _delegateFlags.delegateVideoPlayerNodeDidStallAtTimeInterval = [_delegate respondsToSelector:@selector(videoPlayerNode:didStallAtTimeInterval:)];
    _delegateFlags.delegateVideoPlayerNodeDidStartInitialLoading = [_delegate respondsToSelector:@selector(videoPlayerNodeDidStartInitialLoading:)];
    _delegateFlags.delegateVideoPlayerNodeDidFinishInitialLoading = [_delegate respondsToSelector:@selector(videoPlayerNodeDidFinishInitialLoading:)];
    _delegateFlags.delegateVideoPlayerNodeDidRecoverFromStall = [_delegate respondsToSelector:@selector(videoPlayerNodeDidRecoverFromStall:)];
  }
}

- (void)setControlsDisabled:(BOOL)controlsDisabled
{
  if (_controlsDisabled == controlsDisabled) {
    return;
  }
  
  _controlsDisabled = controlsDisabled;

  if (_controlsDisabled && _cachedControls.count > 0) {
    [self removeControls];
  } else if (!_controlsDisabled) {
    [self createControls];
  }
}

- (void)setShouldAutoPlay:(BOOL)shouldAutoPlay
{
  if (_shouldAutoPlay == shouldAutoPlay) {
    return;
  }
  _shouldAutoPlay = shouldAutoPlay;
  _videoNode.shouldAutoplay = _shouldAutoPlay;
}

- (void)setShouldAutoRepeat:(BOOL)shouldAutoRepeat
{
  if (_shouldAutoRepeat == shouldAutoRepeat) {
    return;
  }
  _shouldAutoRepeat = shouldAutoRepeat;
  _videoNode.shouldAutorepeat = _shouldAutoRepeat;
}

- (void)setMuted:(BOOL)muted
{
  if (_muted == muted) {
    return;
  }
  _muted = muted;
  _videoNode.muted = _muted;
}

- (void)setPeriodicTimeObserverTimescale:(int32_t)periodicTimeObserverTimescale
{
  if (_periodicTimeObserverTimescale == periodicTimeObserverTimescale) {
    return;
  }
  _periodicTimeObserverTimescale = periodicTimeObserverTimescale;
  _videoNode.periodicTimeObserverTimescale = _periodicTimeObserverTimescale;
}

- (NSString *)gravity
{
  if (_gravity == nil) {
    _gravity = _videoNode.gravity;
  }
  return _gravity;
}

- (void)setGravity:(NSString *)gravity
{
  if (_gravity == gravity) {
    return;
  }
  _gravity = gravity;
  _videoNode.gravity = _gravity;
}

- (A_SVideoNodePlayerState)playerState
{
  return _videoNode.playerState;
}

- (BOOL)shouldAggressivelyRecoverFromStall
{
  return _videoNode.shouldAggressivelyRecoverFromStall;
}

- (void) setPlaceholderImageURL:(NSURL *)placeholderImageURL
{
  _videoNode.URL = placeholderImageURL;
}

- (NSURL*) placeholderImageURL
{
  return _videoNode.URL;
}

- (A_SVideoNode*)videoNode
{
  return _videoNode;
}

- (void)setShouldAggressivelyRecoverFromStall:(BOOL)shouldAggressivelyRecoverFromStall
{
  if (_shouldAggressivelyRecoverFromStall == shouldAggressivelyRecoverFromStall) {
    return;
  }
  _shouldAggressivelyRecoverFromStall = shouldAggressivelyRecoverFromStall;
  _videoNode.shouldAggressivelyRecoverFromStall = _shouldAggressivelyRecoverFromStall;
}

#pragma mark - Helpers
- (NSString *)timeStringForCMTime:(CMTime)time forTimeLabelType:(A_SVideoPlayerNodeControlType)type
{
  if (!CMTIME_IS_VALID(time)) {
    return @"00:00";
  }
  if (_delegateFlags.delegateTimeLabelAttributedString) {
    return [_delegate videoPlayerNode:self timeStringForTimeLabelType:type forTime:time];
  }

  NSUInteger dTotalSeconds = CMTimeGetSeconds(time);

  NSUInteger dHours = floor(dTotalSeconds / 3600);
  NSUInteger dMinutes = floor(dTotalSeconds % 3600 / 60);
  NSUInteger dSeconds = floor(dTotalSeconds % 3600 % 60);

  NSString *videoDurationText;
  if (dHours > 0) {
    videoDurationText = [NSString stringWithFormat:@"%i:%02i:%02i", (int)dHours, (int)dMinutes, (int)dSeconds];
  } else {
    videoDurationText = [NSString stringWithFormat:@"%02i:%02i", (int)dMinutes, (int)dSeconds];
  }
  return videoDurationText;
}

@end

#endif // TARGET_OS_IOS
