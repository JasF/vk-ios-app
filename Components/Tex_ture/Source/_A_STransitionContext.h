//
//  _A_STransitionContext.h
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

#import <Async_DisplayKit/A_SContextTransitioning.h>

@class A_SLayout;
@class _A_STransitionContext;

@protocol _A_STransitionContextLayoutDelegate <NSObject>

- (NSArray<A_SDisplayNode *> *)currentSubnodesWithTransitionContext:(_A_STransitionContext *)context;

- (NSArray<A_SDisplayNode *> *)insertedSubnodesWithTransitionContext:(_A_STransitionContext *)context;
- (NSArray<A_SDisplayNode *> *)removedSubnodesWithTransitionContext:(_A_STransitionContext *)context;

- (A_SLayout *)transitionContext:(_A_STransitionContext *)context layoutForKey:(NSString *)key;
- (A_SSizeRange)transitionContext:(_A_STransitionContext *)context constrainedSizeForKey:(NSString *)key;

@end

@protocol _A_STransitionContextCompletionDelegate <NSObject>

- (void)transitionContext:(_A_STransitionContext *)context didComplete:(BOOL)didComplete;

@end

@interface _A_STransitionContext : NSObject <A_SContextTransitioning>

@property (assign, readonly, nonatomic, getter=isAnimated) BOOL animated;

- (instancetype)initWithAnimation:(BOOL)animated
                   layoutDelegate:(id<_A_STransitionContextLayoutDelegate>)layoutDelegate
               completionDelegate:(id<_A_STransitionContextCompletionDelegate>)completionDelegate;

@end

@interface _A_SAnimatedTransitionContext : NSObject
@property (nonatomic, strong, readonly) A_SDisplayNode *node;
@property (nonatomic, assign, readonly) CGFloat alpha;
+ (instancetype)contextForNode:(A_SDisplayNode *)node alpha:(CGFloat)alphaValue;
@end
