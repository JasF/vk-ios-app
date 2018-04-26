//
//  _A_STransitionContext.m
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

#import <Async_DisplayKit/_A_STransitionContext.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayout.h>


NSString * const A_STransitionContextFromLayoutKey = @"org.asyncdisplaykit.A_STransitionContextFromLayoutKey";
NSString * const A_STransitionContextToLayoutKey = @"org.asyncdisplaykit.A_STransitionContextToLayoutKey";

@interface _A_STransitionContext ()

@property (weak, nonatomic) id<_A_STransitionContextLayoutDelegate> layoutDelegate;
@property (weak, nonatomic) id<_A_STransitionContextCompletionDelegate> completionDelegate;

@end

@implementation _A_STransitionContext

- (instancetype)initWithAnimation:(BOOL)animated
                     layoutDelegate:(id<_A_STransitionContextLayoutDelegate>)layoutDelegate
                 completionDelegate:(id<_A_STransitionContextCompletionDelegate>)completionDelegate
{
  self = [super init];
  if (self) {
    _animated = animated;
    _layoutDelegate = layoutDelegate;
    _completionDelegate = completionDelegate;
  }
  return self;
}

#pragma mark - A_SContextTransitioning Protocol Implementation

- (A_SLayout *)layoutForKey:(NSString *)key
{
  return [_layoutDelegate transitionContext:self layoutForKey:key];
}

- (A_SSizeRange)constrainedSizeForKey:(NSString *)key
{
  return [_layoutDelegate transitionContext:self constrainedSizeForKey:key];
}

- (CGRect)initialFrameForNode:(A_SDisplayNode *)node
{
  return [[self layoutForKey:A_STransitionContextFromLayoutKey] frameForElement:node];
}

- (CGRect)finalFrameForNode:(A_SDisplayNode *)node
{
  return [[self layoutForKey:A_STransitionContextToLayoutKey] frameForElement:node];
}

- (NSArray<A_SDisplayNode *> *)subnodesForKey:(NSString *)key
{
  NSMutableArray<A_SDisplayNode *> *subnodes = [NSMutableArray array];
  for (A_SLayout *sublayout in [self layoutForKey:key].sublayouts) {
    [subnodes addObject:(A_SDisplayNode *)sublayout.layoutElement];
  }
  return subnodes;
}

- (NSArray<A_SDisplayNode *> *)insertedSubnodes
{
  return [_layoutDelegate insertedSubnodesWithTransitionContext:self];
}

- (NSArray<A_SDisplayNode *> *)removedSubnodes
{
  return [_layoutDelegate removedSubnodesWithTransitionContext:self];
}

- (void)completeTransition:(BOOL)didComplete
{
  [_completionDelegate transitionContext:self didComplete:didComplete];
}

@end


@interface _A_SAnimatedTransitionContext ()
@property (nonatomic, strong, readwrite) A_SDisplayNode *node;
@property (nonatomic, assign, readwrite) CGFloat alpha;
@end

@implementation _A_SAnimatedTransitionContext

+ (instancetype)contextForNode:(A_SDisplayNode *)node alpha:(CGFloat)alpha
{
  _A_SAnimatedTransitionContext *context = [[_A_SAnimatedTransitionContext alloc] init];
  context.node = node;
  context.alpha = alpha;
  return context;
}

@end
