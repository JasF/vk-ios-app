//
//  A_SDimension.mm
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

#import <Async_DisplayKit/A_SDimension.h>

#import <Async_DisplayKit/CoreGraphics+A_SConvenience.h>

#import <Async_DisplayKit/A_SAssert.h>

#pragma mark - A_SDimension

A_SDimension const A_SDimensionAuto = {A_SDimensionUnitAuto, 0};

A_SOVERLOADABLE A_SDimension A_SDimensionMake(NSString *dimension)
{
  if (dimension.length > 0) {
    
    // Handle points
    if ([dimension hasSuffix:@"pt"]) {
      return A_SDimensionMake(A_SDimensionUnitPoints, A_SCGFloatFromString(dimension));
    }
    
    // Handle auto
    if ([dimension isEqualToString:@"auto"]) {
      return A_SDimensionAuto;
    }
  
    // Handle percent
    if ([dimension hasSuffix:@"%"]) {
      return A_SDimensionMake(A_SDimensionUnitFraction, (A_SCGFloatFromString(dimension) / 100.0));
    }
  }
  
  return A_SDimensionAuto;
}

NSString *NSStringFromA_SDimension(A_SDimension dimension)
{
  switch (dimension.unit) {
    case A_SDimensionUnitPoints:
      return [NSString stringWithFormat:@"%.0fpt", dimension.value];
    case A_SDimensionUnitFraction:
      return [NSString stringWithFormat:@"%.0f%%", dimension.value * 100.0];
    case A_SDimensionUnitAuto:
      return @"Auto";
  }
}

#pragma mark - A_SLayoutSize

A_SLayoutSize const A_SLayoutSizeAuto = {A_SDimensionAuto, A_SDimensionAuto};

#pragma mark - A_SSizeRange

A_SSizeRange const A_SSizeRangeZero = {};

A_SSizeRange const A_SSizeRangeUnconstrained = { {0, 0}, { INFINITY, INFINITY }};

struct _Range {
  CGFloat min;
  CGFloat max;
  
  /**
   Intersects another dimension range. If the other range does not overlap, this size range "wins" by returning a
   single point within its own range that is closest to the non-overlapping range.
   */
  _Range intersect(const _Range &other) const
  {
  CGFloat newMin = MAX(min, other.min);
  CGFloat newMax = MIN(max, other.max);
  if (newMin <= newMax) {
    return {newMin, newMax};
  } else {
    // No intersection. If we're before the other range, return our max; otherwise our min.
    if (min < other.min) {
      return {max, max};
    } else {
      return {min, min};
    }
  }
  }
};

A_SSizeRange A_SSizeRangeIntersect(A_SSizeRange sizeRange, A_SSizeRange otherSizeRange)
{
  auto w = _Range({sizeRange.min.width, sizeRange.max.width}).intersect({otherSizeRange.min.width, otherSizeRange.max.width});
  auto h = _Range({sizeRange.min.height, sizeRange.max.height}).intersect({otherSizeRange.min.height, otherSizeRange.max.height});
  return {{w.min, h.min}, {w.max, h.max}};
}

NSString *NSStringFromA_SSizeRange(A_SSizeRange sizeRange)
{
  // 17 field length copied from iOS 10.3 impl of NSStringFromCGSize.
  if (CGSizeEqualToSize(sizeRange.min, sizeRange.max)) {
    return [NSString stringWithFormat:@"{{%.*g, %.*g}}",
            17, sizeRange.min.width,
            17, sizeRange.min.height];
  }
  return [NSString stringWithFormat:@"{{%.*g, %.*g}, {%.*g, %.*g}}",
          17, sizeRange.min.width,
          17, sizeRange.min.height,
          17, sizeRange.max.width,
          17, sizeRange.max.height];
}

#if YOGA
#pragma mark - Yoga - A_SEdgeInsets
A_SEdgeInsets const A_SEdgeInsetsZero = {};

extern A_SEdgeInsets A_SEdgeInsetsMake(UIEdgeInsets edgeInsets)
{
  A_SEdgeInsets asEdgeInsets = A_SEdgeInsetsZero;
  asEdgeInsets.top = A_SDimensionMake(edgeInsets.top);
  asEdgeInsets.left = A_SDimensionMake(edgeInsets.left);
  asEdgeInsets.bottom = A_SDimensionMake(edgeInsets.bottom);
  asEdgeInsets.right = A_SDimensionMake(edgeInsets.right);
  return asEdgeInsets;
}
#endif
