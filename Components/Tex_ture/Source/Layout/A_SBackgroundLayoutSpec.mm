//
//  A_SBackgroundLayoutSpec.mm
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

#import <Async_DisplayKit/A_SBackgroundLayoutSpec.h>

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SAssert.h>

static NSUInteger const kForegroundChildIndex = 0;
static NSUInteger const kBackgroundChildIndex = 1;

@implementation A_SBackgroundLayoutSpec

#pragma mark - Class

+ (instancetype)backgroundLayoutSpecWithChild:(id<A_SLayoutElement>)child background:(id<A_SLayoutElement>)background;
{
  return [[self alloc] initWithChild:child background:background];
}

#pragma mark - Lifecycle

- (instancetype)initWithChild:(id<A_SLayoutElement>)child background:(id<A_SLayoutElement>)background
{
  if (!(self = [super init])) {
    return nil;
  }
  self.child = child;
  self.background = background;
  return self;
}

#pragma mark - A_SLayoutSpec

/**
 * First layout the contents, then fit the background image.
 */
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize
{
  A_SLayout *contentsLayout = [self.child layoutThatFits:constrainedSize parentSize:parentSize];

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:2];
  if (self.background) {
    // Size background to exactly the same size.
    A_SLayout *backgroundLayout = [self.background layoutThatFits:A_SSizeRangeMake(contentsLayout.size)
                                                      parentSize:parentSize];
    backgroundLayout.position = CGPointZero;
    [sublayouts addObject:backgroundLayout];
  }
  contentsLayout.position = CGPointZero;
  [sublayouts addObject:contentsLayout];

  return [A_SLayout layoutWithLayoutElement:self size:contentsLayout.size sublayouts:sublayouts];
}

#pragma mark - Background

- (void)setChild:(id<A_SLayoutElement>)child
{
  A_SDisplayNodeAssertNotNil(child, @"Child cannot be nil");
  [super setChild:child atIndex:kForegroundChildIndex];
}

- (id<A_SLayoutElement>)child
{
  return [super childAtIndex:kForegroundChildIndex];
}

- (void)setBackground:(id<A_SLayoutElement>)background
{
  A_SDisplayNodeAssertNotNil(background, @"Background cannot be nil");
  [super setChild:background atIndex:kBackgroundChildIndex];
}

- (id<A_SLayoutElement>)background
{
  return [super childAtIndex:kBackgroundChildIndex];
}

@end
