//
//  A_SImageNode+AnimatedImagePrivate.h
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

#import <Async_DisplayKit/A_SThread.h>

extern NSString *const A_SAnimatedImageDefaultRunLoopMode;

@interface A_SImageNode ()
{
  A_SDN::Mutex _displayLinkLock;
  id <A_SAnimatedImageProtocol> _animatedImage;
  BOOL _animatedImagePaused;
  NSString *_animatedImageRunLoopMode;
  CADisplayLink *_displayLink;
  NSUInteger _lastSuccessfulFrameIndex;
  
  //accessed on main thread only
  CFTimeInterval _playHead;
  NSUInteger _playedLoops;
}

@property (nonatomic, assign) CFTimeInterval lastDisplayLinkFire;

@end

@interface A_SImageNode (AnimatedImagePrivate)

- (void)_locked_setAnimatedImage:(id <A_SAnimatedImageProtocol>)animatedImage;

@end


@interface A_SImageNode (AnimatedImageInvalidation)

- (void)invalidateAnimatedImage;

@end
