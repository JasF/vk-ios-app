//
//  A_SDimensionInternal.h
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

#pragma once
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SDimension.h>

A_SDISPLAYNODE_EXTERN_C_BEGIN
NS_ASSUME_NONNULL_BEGIN

#pragma mark - A_SLayoutElementSize

/**
 * A struct specifying a A_SLayoutElement's size. Example:
 *
 *  A_SLayoutElementSize size = (A_SLayoutElementSize){
 *    .width = A_SDimensionMakeWithFraction(0.25),
 *    .maxWidth = A_SDimensionMakeWithPoints(200),
 *    .minHeight = A_SDimensionMakeWithFraction(0.50)
 *  };
 *
 *  Description: <A_SLayoutElementSize: exact={25%, Auto}, min={Auto, 50%}, max={200pt, Auto}>
 *
 */
typedef struct {
  A_SDimension width;
  A_SDimension height;
  A_SDimension minWidth;
  A_SDimension maxWidth;
  A_SDimension minHeight;
  A_SDimension maxHeight;
} A_SLayoutElementSize;

/**
 * Returns an A_SLayoutElementSize with default values.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SLayoutElementSize A_SLayoutElementSizeMake()
{
  return (A_SLayoutElementSize){
    .width = A_SDimensionAuto,
    .height = A_SDimensionAuto,
    .minWidth = A_SDimensionAuto,
    .maxWidth = A_SDimensionAuto,
    .minHeight = A_SDimensionAuto,
    .maxHeight = A_SDimensionAuto
  };
}

/**
 * Returns an A_SLayoutElementSize with the specified CGSize values as width and height.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SLayoutElementSize A_SLayoutElementSizeMakeFromCGSize(CGSize size)
{
  A_SLayoutElementSize s = A_SLayoutElementSizeMake();
  s.width = A_SDimensionMakeWithPoints(size.width);
  s.height = A_SDimensionMakeWithPoints(size.height);
  return s;
}

/**
 * Returns whether two sizes are equal.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SLayoutElementSizeEqualToLayoutElementSize(A_SLayoutElementSize lhs, A_SLayoutElementSize rhs)
{
  return (A_SDimensionEqualToDimension(lhs.width, rhs.width)
  && A_SDimensionEqualToDimension(lhs.height, rhs.height)
  && A_SDimensionEqualToDimension(lhs.minWidth, rhs.minWidth)
  && A_SDimensionEqualToDimension(lhs.maxWidth, rhs.maxWidth)
  && A_SDimensionEqualToDimension(lhs.minHeight, rhs.minHeight)
  && A_SDimensionEqualToDimension(lhs.maxHeight, rhs.maxHeight));
}

/**
 * Returns a string formatted to contain the data from an A_SLayoutElementSize.
 */
extern A_S_WARN_UNUSED_RESULT NSString *NSStringFromA_SLayoutElementSize(A_SLayoutElementSize size);

/**
 * Resolve the given size relative to a parent size and an auto size.
 * From the given size uses width, height to resolve the exact size constraint, uses the minHeight and minWidth to
 * resolve the min size constraint and the maxHeight and maxWidth to resolve the max size constraint. For every
 * dimension with unit A_SDimensionUnitAuto the given autoA_SSizeRange value will be used.
 * Based on the calculated exact, min and max size constraints the final size range will be calculated.
 */
extern A_S_WARN_UNUSED_RESULT A_SSizeRange A_SLayoutElementSizeResolveAutoSize(A_SLayoutElementSize size, const CGSize parentSize, A_SSizeRange autoA_SSizeRange);

/**
 * Resolve the given size to a parent size. Uses internally A_SLayoutElementSizeResolveAutoSize with {INFINITY, INFINITY} as
 * as autoA_SSizeRange. For more information look at A_SLayoutElementSizeResolveAutoSize.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SSizeRange A_SLayoutElementSizeResolve(A_SLayoutElementSize size, const CGSize parentSize)
{
  return A_SLayoutElementSizeResolveAutoSize(size, parentSize, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
}


NS_ASSUME_NONNULL_END
A_SDISPLAYNODE_EXTERN_C_END
