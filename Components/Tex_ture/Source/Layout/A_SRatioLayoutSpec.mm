//
//  A_SRatioLayoutSpec.mm
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

#import <Async_DisplayKit/A_SRatioLayoutSpec.h>

#import <algorithm>
#import <tgmath.h>
#import <vector>

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>

#pragma mark - A_SRatioLayoutSpec

@implementation A_SRatioLayoutSpec
{
  CGFloat _ratio;
}

#pragma mark - Lifecycle

+ (instancetype)ratioLayoutSpecWithRatio:(CGFloat)ratio child:(id<A_SLayoutElement>)child
{
  return [[self alloc] initWithRatio:ratio child:child];
}

- (instancetype)initWithRatio:(CGFloat)ratio child:(id<A_SLayoutElement>)child;
{
  if (!(self = [super init])) {
    return nil;
  }

  A_SDisplayNodeAssertNotNil(child, @"Child cannot be nil");
  A_SDisplayNodeAssert(ratio > 0, @"Ratio should be strictly positive, but received %f", ratio);
  _ratio = ratio;
  self.child = child;

  return self;
}

#pragma mark - Setter / Getter

- (void)setRatio:(CGFloat)ratio
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _ratio = ratio;
}

#pragma mark - A_SLayoutElement

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  std::vector<CGSize> sizeOptions;
  
  if (A_SPointsValidForSize(constrainedSize.max.width)) {
    sizeOptions.push_back(A_SSizeRangeClamp(constrainedSize, {
      constrainedSize.max.width,
      A_SFloorPixelValue(_ratio * constrainedSize.max.width)
    }));
  }
  
  if (A_SPointsValidForSize(constrainedSize.max.height)) {
    sizeOptions.push_back(A_SSizeRangeClamp(constrainedSize, {
      A_SFloorPixelValue(constrainedSize.max.height / _ratio),
      constrainedSize.max.height
    }));
  }

  // Choose the size closest to the desired ratio.
  const auto &bestSize = std::max_element(sizeOptions.begin(), sizeOptions.end(), [&](const CGSize &a, const CGSize &b){
    return std::fabs((a.height / a.width) - _ratio) > std::fabs((b.height / b.width) - _ratio);
  });

  // If there is no max size in *either* dimension, we can't apply the ratio, so just pass our size range through.
  const A_SSizeRange childRange = (bestSize == sizeOptions.end()) ? constrainedSize : A_SSizeRangeIntersect(constrainedSize, A_SSizeRangeMake(*bestSize, *bestSize));
  const CGSize parentSize = (bestSize == sizeOptions.end()) ? A_SLayoutElementParentSizeUndefined : *bestSize;
  A_SLayout *sublayout = [self.child layoutThatFits:childRange parentSize:parentSize];
  sublayout.position = CGPointZero;
  return [A_SLayout layoutWithLayoutElement:self size:sublayout.size sublayouts:@[sublayout]];
}

@end

#pragma mark - A_SRatioLayoutSpec (Debugging)

@implementation A_SRatioLayoutSpec (Debugging)

#pragma mark - A_SLayoutElementAsciiArtProtocol

- (NSString *)asciiArtName
{
  return [NSString stringWithFormat:@"%@ (%.1f)", NSStringFromClass([self class]), self.ratio];
}

@end
