//
//  A_SVideoPlayerNode.h
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

#if TARGET_OS_IOS
#import <CoreMedia/CoreMedia.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SVideoNode.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>

@class AVAsset;
@class A_SButtonNode;
@protocol A_SVideoPlayerNodeDelegate;

typedef NS_ENUM(NSInteger, A_SVideoPlayerNodeControlType) {
  A_SVideoPlayerNodeControlTypePlaybackButton,
  A_SVideoPlayerNodeControlTypeElapsedText,
  A_SVideoPlayerNodeControlTypeDurationText,
  A_SVideoPlayerNodeControlTypeScrubber,
  A_SVideoPlayerNodeControlTypeFullScreenButton,
  A_SVideoPlayerNodeControlTypeFlexGrowSpacer,
};

NS_ASSUME_NONNULL_BEGIN

@interface A_SVideoPlayerNode : A_SDisplayNode

@property (nullable, nonatomic, weak) id<A_SVideoPlayerNodeDelegate> delegate;

@property (nonatomic, assign, readonly) CMTime duration;

@property (nonatomic, assign) BOOL controlsDisabled;

#pragma mark - A_SVideoNode property proxy
/**
 * When shouldAutoplay is set to true, a video node will play when it has both loaded and entered the "visible" interfaceState.
 * If it leaves the visible interfaceState it will pause but will resume once it has returned.
 */
@property (nonatomic, assign, readwrite) BOOL shouldAutoPlay;
@property (nonatomic, assign, readwrite) BOOL shouldAutoRepeat;
@property (nonatomic, assign, readwrite) BOOL muted;
@property (nonatomic, assign, readonly) A_SVideoNodePlayerState playerState;
@property (nonatomic, assign, readwrite) BOOL shouldAggressivelyRecoverFromStall;
@property (nullable, nonatomic, strong, readwrite) NSURL *placeholderImageURL;

@property (nullable, nonatomic, strong, readwrite) AVAsset *asset;
/**
 ** @abstract The URL with which the asset was initialized.
 ** @discussion Setting the URL will override the current asset with a newly created AVURLAsset created from the given URL, and AVAsset *asset will point to that newly created AVURLAsset.  Please don't set both assetURL and asset.
 ** @return Current URL the asset was initialized or nil if no URL was given.
 **/
@property (nullable, nonatomic, strong, readwrite) NSURL *assetURL;

/// You should never set any value on the backing video node. Use exclusivively the video player node to set properties
@property (nonatomic, strong, readonly) A_SVideoNode *videoNode;

//! Defaults to 100
@property (nonatomic, assign) int32_t periodicTimeObserverTimescale;
//! Defaults to AVLayerVideoGravityResizeAspect
@property (nonatomic, copy) NSString *gravity;

#pragma mark - Lifecycle
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix;

#pragma mark - Public API
- (void)seekToTime:(CGFloat)percentComplete;
- (void)play;
- (void)pause;
- (BOOL)isPlaying;
- (void)resetToPlaceholder;

@end

#pragma mark - A_SVideoPlayerNodeDelegate -
@protocol A_SVideoPlayerNodeDelegate <NSObject>
@optional
/**
 * @abstract Delegate method invoked before creating controlbar controls
 * @param videoPlayer The sender
 */
- (NSArray *)videoPlayerNodeNeededDefaultControls:(A_SVideoPlayerNode*)videoPlayer;

/**
 * @abstract Delegate method invoked before creating default controls, asks delegate for custom controls dictionary.
 * This dictionary must constain only A_SDisplayNode subclass objects.
 * @param videoPlayer The sender
 * @discussion - This method is invoked only when developer implements videoPlayerNodeLayoutSpec:forControls:forMaximumSize:
 * and gives ability to add custom constrols to A_SVideoPlayerNode, for example mute button.
 */
- (NSDictionary *)videoPlayerNodeCustomControls:(A_SVideoPlayerNode*)videoPlayer;

/**
 * @abstract Delegate method invoked in layoutSpecThatFits:
 * @param videoPlayer The sender
 * @param controls - Dictionary of controls which are used in videoPlayer; Dictionary keys are A_SVideoPlayerNodeControlType
 * @param maxSize - Maximum size for A_SVideoPlayerNode
 * @discussion - Developer can layout whole A_SVideoPlayerNode as he wants. A_SVideoNode is locked and it can't be changed
 */
- (A_SLayoutSpec *)videoPlayerNodeLayoutSpec:(A_SVideoPlayerNode *)videoPlayer
                                forControls:(NSDictionary *)controls
                             forMaximumSize:(CGSize)maxSize;

#pragma mark Text delegate methods
/**
 * @abstract Delegate method invoked before creating A_SVideoPlayerNodeControlTypeElapsedText and A_SVideoPlayerNodeControlTypeDurationText
 * @param videoPlayer The sender
 * @param timeLabelType The of the time label
 */
- (NSDictionary *)videoPlayerNodeTimeLabelAttributes:(A_SVideoPlayerNode *)videoPlayer timeLabelType:(A_SVideoPlayerNodeControlType)timeLabelType;
- (NSString *)videoPlayerNode:(A_SVideoPlayerNode *)videoPlayerNode
   timeStringForTimeLabelType:(A_SVideoPlayerNodeControlType)timeLabelType
                      forTime:(CMTime)time;

#pragma mark Scrubber delegate methods
- (UIColor *)videoPlayerNodeScrubberMaximumTrackTint:(A_SVideoPlayerNode *)videoPlayer;
- (UIColor *)videoPlayerNodeScrubberMinimumTrackTint:(A_SVideoPlayerNode *)videoPlayer;
- (UIColor *)videoPlayerNodeScrubberThumbTint:(A_SVideoPlayerNode *)videoPlayer;
- (UIImage *)videoPlayerNodeScrubberThumbImage:(A_SVideoPlayerNode *)videoPlayer;

#pragma mark - Spinner delegate methods
- (UIColor *)videoPlayerNodeSpinnerTint:(A_SVideoPlayerNode *)videoPlayer;
- (UIActivityIndicatorViewStyle)videoPlayerNodeSpinnerStyle:(A_SVideoPlayerNode *)videoPlayer;

#pragma mark - Playback button delegate methods
- (UIColor *)videoPlayerNodePlaybackButtonTint:(A_SVideoPlayerNode *)videoPlayer;

#pragma mark - Fullscreen button delegate methods

- (UIImage *)videoPlayerNodeFullScreenButtonImage:(A_SVideoPlayerNode *)videoPlayer;


#pragma mark A_SVideoNodeDelegate proxy methods
/**
 * @abstract Delegate method invoked when A_SVideoPlayerNode is taped.
 * @param videoPlayer The A_SVideoPlayerNode that was tapped.
 */
- (void)didTapVideoPlayerNode:(A_SVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when fullcreen button is taped.
 * @param buttonNode The fullscreen button node that was tapped.
 */
- (void)didTapFullScreenButtonNode:(A_SButtonNode *)buttonNode;

/**
 * @abstract Delegate method invoked when A_SVideoNode playback time is updated.
 * @param videoPlayer The video player node
 * @param time current playback time.
 */
- (void)videoPlayerNode:(A_SVideoPlayerNode *)videoPlayer didPlayToTime:(CMTime)time;

/**
 * @abstract Delegate method invoked when A_SVideoNode changes state.
 * @param videoPlayer The A_SVideoPlayerNode whose A_SVideoNode is changing state.
 * @param state A_SVideoNode state before this change.
 * @param toState A_SVideoNode new state.
 * @discussion This method is called after each state change
 */
- (void)videoPlayerNode:(A_SVideoPlayerNode *)videoPlayer willChangeVideoNodeState:(A_SVideoNodePlayerState)state toVideoNodeState:(A_SVideoNodePlayerState)toState;

/**
 * @abstract Delegate method is invoked when A_SVideoNode decides to change state.
 * @param videoPlayer The A_SVideoPlayerNode whose A_SVideoNode is changing state.
 * @param state A_SVideoNode that is going to be set.
 * @discussion Delegate method invoked when player changes it's state to
 * A_SVideoNodePlayerStatePlaying or A_SVideoNodePlayerStatePaused
 * and asks delegate if state change is valid
 */
- (BOOL)videoPlayerNode:(A_SVideoPlayerNode*)videoPlayer shouldChangeVideoNodeStateTo:(A_SVideoNodePlayerState)state;

/**
 * @abstract Delegate method invoked when the A_SVideoNode has played to its end time.
 * @param videoPlayer The video node has played to its end time.
 */
- (void)videoPlayerNodeDidPlayToEnd:(A_SVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the A_SVideoNode has constructed its AVPlayerItem for the asset.
 * @param videoPlayer The video player node.
 * @param currentItem The AVPlayerItem that was constructed from the asset.
 */
- (void)videoPlayerNode:(A_SVideoPlayerNode *)videoPlayer didSetCurrentItem:(AVPlayerItem *)currentItem;

/**
 * @abstract Delegate method invoked when the A_SVideoNode stalls.
 * @param videoPlayer The video player node that has experienced the stall
 * @param timeInterval Current playback time when the stall happens
 */
- (void)videoPlayerNode:(A_SVideoPlayerNode *)videoPlayer didStallAtTimeInterval:(NSTimeInterval)timeInterval;

/**
 * @abstract Delegate method invoked when the A_SVideoNode starts the inital asset loading
 * @param videoPlayer The videoPlayer
 */
- (void)videoPlayerNodeDidStartInitialLoading:(A_SVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the A_SVideoNode is done loading the asset and can start the playback
 * @param videoPlayer The videoPlayer
 */
- (void)videoPlayerNodeDidFinishInitialLoading:(A_SVideoPlayerNode *)videoPlayer;

/**
 * @abstract Delegate method invoked when the A_SVideoNode has recovered from the stall
 * @param videoPlayer The videoplayer
 */
- (void)videoPlayerNodeDidRecoverFromStall:(A_SVideoPlayerNode *)videoPlayer;


@end
NS_ASSUME_NONNULL_END
#endif
