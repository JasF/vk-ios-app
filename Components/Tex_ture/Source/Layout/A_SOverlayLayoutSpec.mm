//
//  A_SOverlayLayoutSpec.mm
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

#import <Async_DisplayKit/A_SOverlayLayoutSpec.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>
#import <Async_DisplayKit/A_SAssert.h>

static NSUInteger const kUnderlayChildIndex = 0;
static NSUInteger const kOverlayChildIndex = 1;

@implementation A_SOverlayLayoutSpec

#pragma mark - Class

+ (instancetype)overlayLayoutSpecWithChild:(id<A_SLayoutElement>)child overlay:(id<A_SLayoutElement>)overlay
{
  return [[self alloc] initWithChild:child overlay:overlay];
}

#pragma mark - Lifecycle

- (instancetype)initWithChild:(id<A_SLayoutElement>)child overlay:(id<A_SLayoutElement>)overlay
{
  if (!(self = [super init])) {
    return nil;
  }
  self.child = child;
  self.overlay = overlay;
  return self;
}

#pragma mark - Setter / Getter

- (void)setChild:(id<A_SLayoutElement>)child
{
  A_SDisplayNodeAssertNotNil(child, @"Child that will be overlayed on shouldn't be nil");
  [super setChild:child atIndex:kUnderlayChildIndex];
}

- (id<A_SLayoutElement>)child
{
  return [super childAtIndex:kUnderlayChildIndex];
}

- (void)setOverlay:(id<A_SLayoutElement>)overlay
{
  A_SDisplayNodeAssertNotNil(overlay, @"Overlay cannot be nil");
  [super setChild:overlay atIndex:kOverlayChildIndex];
}

- (id<A_SLayoutElement>)overlay
{
  return [super childAtIndex:kOverlayChildIndex];
}

#pragma mark - A_SLayoutSpec

/**
 First layout the contents, then fit the overlay on top of it.
 */
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize
{
  A_SLayout *contentsLayout = [self.child layoutThatFits:constrainedSize parentSize:parentSize];
  contentsLayout.position = CGPointZero;
  NSMutableArray *sublayouts = [NSMutableArray arrayWithObject:contentsLayout];
  if (self.overlay) {
    A_SLayout *overlayLayout = [self.overlay layoutThatFits:A_SSizeRangeMake(contentsLayout.size)
                                                parentSize:contentsLayout.size];
    overlayLayout.position = CGPointZero;
    [sublayouts addObject:overlayLayout];
  }
  
  return [A_SLayout layoutWithLayoutElement:self size:contentsLayout.size sublayouts:sublayouts];
}

@end
