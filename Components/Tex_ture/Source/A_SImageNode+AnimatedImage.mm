//
//  A_SImageNode+AnimatedImage.mm
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

#import <Async_DisplayKit/A_SImageNode.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SImageNode+Private.h>
#import <Async_DisplayKit/A_SImageNode+AnimatedImagePrivate.h>
#import <Async_DisplayKit/A_SImageProtocols.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SNetworkImageNode.h>
#import <Async_DisplayKit/A_SWeakProxy.h>

#define A_SAnimatedImageDebug  0

@interface A_SNetworkImageNode (Private)
- (void)_locked_setDefaultImage:(UIImage *)image;
@end

NSString *const A_SAnimatedImageDefaultRunLoopMode = NSRunLoopCommonModes;

@implementation A_SImageNode (AnimatedImage)

#pragma mark - GIF support

- (void)setAnimatedImage:(id <A_SAnimatedImageProtocol>)animatedImage
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setAnimatedImage:animatedImage];
}

- (void)_locked_setAnimatedImage:(id <A_SAnimatedImageProtocol>)animatedImage
{
  if (A_SObjectIsEqual(_animatedImage, animatedImage)) {
    return;
  }
  
  id <A_SAnimatedImageProtocol> previousAnimatedImage = _animatedImage;
  _animatedImage = animatedImage;
  
  if (animatedImage != nil) {
    __weak A_SImageNode *weakSelf = self;
    if ([animatedImage respondsToSelector:@selector(setCoverImageReadyCallback:)]) {
      animatedImage.coverImageReadyCallback = ^(UIImage *coverImage) {
        // In this case the lock is already gone we have to call the unlocked version therefore
        [weakSelf setCoverImageCompleted:coverImage];
      };
    }
    
    animatedImage.playbackReadyCallback = ^{
      // In this case the lock is already gone we have to call the unlocked version therefore
      [weakSelf setShouldAnimate:YES];
    };
    if (animatedImage.playbackReady) {
      [self _locked_setShouldAnimate:YES];
    }
  } else {
      // Clean up after ourselves.
      self.contents = nil;
      [self setCoverImage:nil];
  }
  
  [self animatedImageSet:_animatedImage previousAnimatedImage:previousAnimatedImage];
}

- (void)animatedImageSet:(id <A_SAnimatedImageProtocol>)newAnimatedImage previousAnimatedImage:(id <A_SAnimatedImageProtocol>)previousAnimatedImage
{
  //Subclasses may override
}

- (id <A_SAnimatedImageProtocol>)animatedImage
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _animatedImage;
}

- (void)setAnimatedImagePaused:(BOOL)animatedImagePaused
{
  A_SDN::MutexLocker l(__instanceLock__);

  _animatedImagePaused = animatedImagePaused;

  [self _locked_setShouldAnimate:!animatedImagePaused];
}

- (BOOL)animatedImagePaused
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _animatedImagePaused;
}

- (void)setCoverImageCompleted:(UIImage *)coverImage
{
  if (A_SInterfaceStateIncludesDisplay(self.interfaceState)) {
    A_SDN::MutexLocker l(__instanceLock__);
    [self _locked_setCoverImageCompleted:coverImage];
  }
}

- (void)_locked_setCoverImageCompleted:(UIImage *)coverImage
{
  _displayLinkLock.lock();
  BOOL setCoverImage = (_displayLink == nil) || _displayLink.paused;
  _displayLinkLock.unlock();
  
  if (setCoverImage) {
    [self _locked_setCoverImage:coverImage];
  }
}

- (void)setCoverImage:(UIImage *)coverImage
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setCoverImage:coverImage];
}

- (void)_locked_setCoverImage:(UIImage *)coverImage
{
  //If we're a network image node, we want to set the default image so
  //that it will correctly be restored if it exits the range.
#if A_SAnimatedImageDebug
    NSLog(@"setting cover image: %p", self);
#endif
  if ([self isKindOfClass:[A_SNetworkImageNode class]]) {
    [(A_SNetworkImageNode *)self _locked_setDefaultImage:coverImage];
  } else if (_displayLink == nil || _displayLink.paused == YES) {
    [self _locked_setImage:coverImage];
  }
}

- (NSString *)animatedImageRunLoopMode
{
  A_SDN::MutexLocker l(_displayLinkLock);
  return _animatedImageRunLoopMode;
}

- (void)setAnimatedImageRunLoopMode:(NSString *)runLoopMode
{
  A_SDN::MutexLocker l(_displayLinkLock);

  if (runLoopMode == nil) {
    runLoopMode = A_SAnimatedImageDefaultRunLoopMode;
  }

  if (_displayLink != nil) {
    [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_animatedImageRunLoopMode];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:runLoopMode];
  }
  _animatedImageRunLoopMode = runLoopMode;
}

- (void)setShouldAnimate:(BOOL)shouldAnimate
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setShouldAnimate:shouldAnimate];
}

- (void)_locked_setShouldAnimate:(BOOL)shouldAnimate
{
  // This test is explicitly done and not A_SPerformBlockOnMainThread as this would perform the block immediately
  // on main if called on main thread and we have to call methods locked or unlocked based on which thread we are on
  if (A_SDisplayNodeThreadIsMain()) {
    if (shouldAnimate) {
      [self _locked_startAnimating];
    } else {
      [self _locked_stopAnimating];
    }
  } else {
    // We have to dispatch to the main thread and call the regular methods as the lock is already gone if the
    // block is called
    dispatch_async(dispatch_get_main_queue(), ^{
      if (shouldAnimate) {
        [self startAnimating];
      } else {
        [self stopAnimating];
      }
    });
  }
}

#pragma mark - Animating

- (void)startAnimating
{
  A_SDisplayNodeAssertMainThread();

  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_startAnimating];
}

- (void)_locked_startAnimating
{
  // It should be safe to call self.interfaceState in this case as it will only grab the lock of the superclass
  if (!A_SInterfaceStateIncludesVisible(self.interfaceState)) {
    return;
  }
  
  if (_animatedImagePaused) {
    return;
  }
  
  if (_animatedImage.playbackReady == NO) {
    return;
  }
  
#if A_SAnimatedImageDebug
  NSLog(@"starting animation: %p", self);
#endif

  // Get frame interval before holding display link lock to avoid deadlock
  NSUInteger frameInterval = self.animatedImage.frameInterval;
  A_SDN::MutexLocker l(_displayLinkLock);
  if (_displayLink == nil) {
    _playHead = 0;
    _displayLink = [CADisplayLink displayLinkWithTarget:[A_SWeakProxy weakProxyWithTarget:self] selector:@selector(displayLinkFired:)];
    _displayLink.frameInterval = frameInterval;
    _lastSuccessfulFrameIndex = NSUIntegerMax;
    
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:_animatedImageRunLoopMode];
  } else {
    _displayLink.paused = NO;
  }
}

- (void)stopAnimating
{
  A_SDisplayNodeAssertMainThread();
  
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_stopAnimating];
}

- (void)_locked_stopAnimating
{
  A_SDisplayNodeAssertMainThread();
  
#if A_SAnimatedImageDebug
  NSLog(@"stopping animation: %p", self);
#endif
  A_SDisplayNodeAssertMainThread();
  A_SDN::MutexLocker l(_displayLinkLock);
  _displayLink.paused = YES;
  self.lastDisplayLinkFire = 0;
  
  [_animatedImage clearAnimatedImageCache];
}

#pragma mark - A_SDisplayNode

- (void)didEnterVisibleState
{
  A_SDisplayNodeAssertMainThread();
  [super didEnterVisibleState];
  
  if (self.animatedImage.coverImageReady) {
    [self setCoverImage:self.animatedImage.coverImage];
  }
  if (self.animatedImage.playbackReady) {
    [self startAnimating];
  }
}

- (void)didExitVisibleState
{
  A_SDisplayNodeAssertMainThread();
  [super didExitVisibleState];
  
  [self stopAnimating];
}

- (void)didExitDisplayState
{
  A_SDisplayNodeAssertMainThread();
#if A_SAnimatedImageDebug
    NSLog(@"exiting display state: %p", self);
#endif
    
  // Check to see if we're an animated image before calling super in case someone
  // decides they want to clear out the animatedImage itself on exiting the display
  // state
  BOOL isAnimatedImage = self.animatedImage != nil;
  [super didExitDisplayState];
  
  // Also clear out the contents we've set to be good citizens, we'll put it back in when we become visible.
  if (isAnimatedImage) {
    self.contents = nil;
    [self setCoverImage:nil];
  }
}

#pragma mark - Display Link Callbacks

- (void)displayLinkFired:(CADisplayLink *)displayLink
{
  A_SDisplayNodeAssertMainThread();

  CFTimeInterval timeBetweenLastFire;
  if (self.lastDisplayLinkFire == 0) {
    timeBetweenLastFire = 0;
  } else if (A_S_AT_LEA_ST_IOS10){
    timeBetweenLastFire = displayLink.targetTimestamp - displayLink.timestamp;
  } else {
    timeBetweenLastFire = CACurrentMediaTime() - self.lastDisplayLinkFire;
  }
  self.lastDisplayLinkFire = CACurrentMediaTime();
  
  _playHead += timeBetweenLastFire;
  
  while (_playHead > self.animatedImage.totalDuration) {
      // Set playhead to zero to keep from showing different frames on different playthroughs
    _playHead = 0;
    _playedLoops++;
  }
  
  if (self.animatedImage.loopCount > 0 && _playedLoops >= self.animatedImage.loopCount) {
    [self stopAnimating];
    return;
  }
  
  NSUInteger frameIndex = [self frameIndexAtPlayHeadPosition:_playHead];
  if (frameIndex == _lastSuccessfulFrameIndex) {
    return;
  }
  CGImageRef frameImage = [self.animatedImage imageAtIndex:frameIndex];
  
  if (frameImage == nil) {
    //Pause the display link until we get a file ready notification
    displayLink.paused = YES;
    self.lastDisplayLinkFire = 0;
  } else {
    self.contents = (__bridge id)frameImage;
    _lastSuccessfulFrameIndex = frameIndex;
    [self displayDidFinish];
  }
}

- (NSUInteger)frameIndexAtPlayHeadPosition:(CFTimeInterval)playHead
{
  A_SDisplayNodeAssertMainThread();
  NSUInteger frameIndex = 0;
  for (NSUInteger durationIndex = 0; durationIndex < self.animatedImage.frameCount; durationIndex++) {
    playHead -= [self.animatedImage durationAtIndex:durationIndex];
    if (playHead < 0) {
      return frameIndex;
    }
    frameIndex++;
  }
  
  return frameIndex;
}

@end

#pragma mark - A_SImageNode(AnimatedImageInvalidation)

@implementation A_SImageNode(AnimatedImageInvalidation)

- (void)invalidateAnimatedImage
{
  A_SDN::MutexLocker l(_displayLinkLock);
#if A_SAnimatedImageDebug
  if (_displayLink) {
    NSLog(@"invalidating display link");
  }
#endif
  [_displayLink invalidate];
  _displayLink = nil;
}

@end
