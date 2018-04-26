//
//  A_SAbsoluteLayoutSpec.mm
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

#import <Async_DisplayKit/A_SAbsoluteLayoutSpec.h>

#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>
#import <Async_DisplayKit/A_SLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>

#pragma mark - A_SAbsoluteLayoutSpec

@implementation A_SAbsoluteLayoutSpec

#pragma mark - Class

+ (instancetype)absoluteLayoutSpecWithChildren:(NSArray *)children
{
  return [[self alloc] initWithChildren:children];
}

+ (instancetype)absoluteLayoutSpecWithSizing:(A_SAbsoluteLayoutSpecSizing)sizing children:(NSArray<id<A_SLayoutElement>> *)children
{
  return [[self alloc] initWithSizing:sizing children:children];
}

#pragma mark - Lifecycle

- (instancetype)init
{
  return [self initWithChildren:nil];
}

- (instancetype)initWithChildren:(NSArray *)children
{
  return [self initWithSizing:A_SAbsoluteLayoutSpecSizingDefault children:children];
}

- (instancetype)initWithSizing:(A_SAbsoluteLayoutSpecSizing)sizing children:(NSArray<id<A_SLayoutElement>> *)children
{
  if (!(self = [super init])) {
    return nil;
  }

  _sizing = sizing;
  self.children = children;

  return self;
}

#pragma mark - A_SLayoutSpec

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  CGSize size = {
    A_SPointsValidForSize(constrainedSize.max.width) == NO ? A_SLayoutElementParentDimensionUndefined : constrainedSize.max.width,
    A_SPointsValidForSize(constrainedSize.max.height) == NO ? A_SLayoutElementParentDimensionUndefined : constrainedSize.max.height
  };
  
  NSArray *children = self.children;
  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:children.count];

  for (id<A_SLayoutElement> child in children) {
    CGPoint layoutPosition = child.style.layoutPosition;
    CGSize autoMaxSize = {
      constrainedSize.max.width  - layoutPosition.x,
      constrainedSize.max.height - layoutPosition.y
    };

    const A_SSizeRange childConstraint = A_SLayoutElementSizeResolveAutoSize(child.style.size, size, {{0,0}, autoMaxSize});
    
    A_SLayout *sublayout = [child layoutThatFits:childConstraint parentSize:size];
    sublayout.position = layoutPosition;
    [sublayouts addObject:sublayout];
  }
  
  if (_sizing == A_SAbsoluteLayoutSpecSizingSizeToFit || isnan(size.width)) {
    size.width = constrainedSize.min.width;
    for (A_SLayout *sublayout in sublayouts) {
      size.width  = MAX(size.width,  sublayout.position.x + sublayout.size.width);
    }
  }
  
  if (_sizing == A_SAbsoluteLayoutSpecSizingSizeToFit || isnan(size.height)) {
    size.height = constrainedSize.min.height;
    for (A_SLayout *sublayout in sublayouts) {
      size.height = MAX(size.height, sublayout.position.y + sublayout.size.height);
    }
  }
  
  return [A_SLayout layoutWithLayoutElement:self size:A_SSizeRangeClamp(constrainedSize, size) sublayouts:sublayouts];
}

@end

