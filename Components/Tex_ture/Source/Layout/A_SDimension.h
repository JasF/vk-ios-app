//
//  A_SDimension.h
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
#import <UIKit/UIGeometry.h>
#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SAssert.h>

A_SDISPLAYNODE_EXTERN_C_BEGIN
NS_ASSUME_NONNULL_BEGIN

#pragma mark -

A_SDISPLAYNODE_INLINE BOOL A_S_WARN_UNUSED_RESULT A_SPointsValidForLayout(CGFloat points)
{
  return ((isnormal(points) || points == 0.0) && points >= 0.0 && points < (CGFLOAT_MAX / 2.0));
}

A_SDISPLAYNODE_INLINE BOOL A_S_WARN_UNUSED_RESULT A_SIsCGSizeValidForLayout(CGSize size)
{
  return (A_SPointsValidForLayout(size.width) && A_SPointsValidForLayout(size.height));
}

A_SDISPLAYNODE_INLINE BOOL A_S_WARN_UNUSED_RESULT A_SPointsValidForSize(CGFloat points)
{
  return ((isnormal(points) || points == 0.0) && points >= 0.0 && points < (FLT_MAX / 2.0));
}

A_SDISPLAYNODE_INLINE BOOL A_S_WARN_UNUSED_RESULT A_SIsCGSizeValidForSize(CGSize size)
{
  return (A_SPointsValidForSize(size.width) && A_SPointsValidForSize(size.height));
}

A_SDISPLAYNODE_INLINE BOOL A_SIsCGPositionPointsValidForLayout(CGFloat points)
{
  return ((isnormal(points) || points == 0.0) && points < (CGFLOAT_MAX / 2.0));
}

A_SDISPLAYNODE_INLINE BOOL A_SIsCGPositionValidForLayout(CGPoint point)
{
  return (A_SIsCGPositionPointsValidForLayout(point.x) && A_SIsCGPositionPointsValidForLayout(point.y));
}

A_SDISPLAYNODE_INLINE BOOL A_SIsCGRectValidForLayout(CGRect rect)
{
  return (A_SIsCGPositionValidForLayout(rect.origin) && A_SIsCGSizeValidForLayout(rect.size));
}

#pragma mark - A_SDimension

/**
 * A dimension relative to constraints to be provided in the future.
 * A A_SDimension can be one of three types:
 *
 * "Auto" - This indicated "I have no opinion" and may be resolved in whatever way makes most sense given the circumstances.
 *
 * "Points" - Just a number. It will always resolve to exactly this amount.
 *
 * "Percent" - Multiplied to a provided parent amount to resolve a final amount.
 */
typedef NS_ENUM(NSInteger, A_SDimensionUnit) {
  /** This indicates "I have no opinion" and may be resolved in whatever way makes most sense given the circumstances. */
  A_SDimensionUnitAuto,
  /** Just a number. It will always resolve to exactly this amount. This is the default type. */
  A_SDimensionUnitPoints,
  /** Multiplied to a provided parent amount to resolve a final amount. */
  A_SDimensionUnitFraction,
};

typedef struct {
  A_SDimensionUnit unit;
  CGFloat value;
} A_SDimension;

/**
 * Represents auto as A_SDimension
 */
extern A_SDimension const A_SDimensionAuto;

/**
 * Returns a dimension with the specified type and value.
 */
A_SOVERLOADABLE A_SDISPLAYNODE_INLINE A_SDimension A_SDimensionMake(A_SDimensionUnit unit, CGFloat value)
{
  if (unit == A_SDimensionUnitAuto ) {
    A_SDisplayNodeCAssert(value == 0, @"A_SDimension auto value must be 0.");
  } else if (unit == A_SDimensionUnitPoints) {
    A_SDisplayNodeCAssertPositiveReal(@"Points", value);
  } else if (unit == A_SDimensionUnitFraction) {
    A_SDisplayNodeCAssert( 0 <= value && value <= 1.0, @"A_SDimension fraction value (%f) must be between 0 and 1.", value);
  }
  A_SDimension dimension;
  dimension.unit = unit;
  dimension.value = value;
  return dimension;
}

/**
 * Returns a dimension with the specified points value.
 */
A_SOVERLOADABLE A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SDimension A_SDimensionMake(CGFloat points)
{
  return A_SDimensionMake(A_SDimensionUnitPoints, points);
}

/**
 * Returns a dimension by parsing the specified dimension string.
 * Examples: A_SDimensionMake(@"50%") = A_SDimensionMake(A_SDimensionUnitFraction, 0.5)
 *           A_SDimensionMake(@"0.5pt") = A_SDimensionMake(A_SDimensionUnitPoints, 0.5)
 */
A_SOVERLOADABLE A_S_WARN_UNUSED_RESULT extern A_SDimension A_SDimensionMake(NSString *dimension);

/**
 * Returns a dimension with the specified points value.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SDimension A_SDimensionMakeWithPoints(CGFloat points)
{
  A_SDisplayNodeCAssertPositiveReal(@"Points", points);
  return A_SDimensionMake(A_SDimensionUnitPoints, points);
}

/**
 * Returns a dimension with the specified fraction value.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SDimension A_SDimensionMakeWithFraction(CGFloat fraction)
{
  A_SDisplayNodeCAssert( 0 <= fraction && fraction <= 1.0, @"A_SDimension fraction value (%f) must be between 0 and 1.", fraction);
  return A_SDimensionMake(A_SDimensionUnitFraction, fraction);
}

/**
 * Returns whether two dimensions are equal.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SDimensionEqualToDimension(A_SDimension lhs, A_SDimension rhs)
{
  return (lhs.unit == rhs.unit && lhs.value == rhs.value);
}

/**
 * Returns a NSString representation of a dimension.
 */
extern A_S_WARN_UNUSED_RESULT NSString *NSStringFromA_SDimension(A_SDimension dimension);

/**
 * Resolve this dimension to a parent size.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT CGFloat A_SDimensionResolve(A_SDimension dimension, CGFloat parentSize, CGFloat autoSize)
{
  switch (dimension.unit) {
    case A_SDimensionUnitAuto:
      return autoSize;
    case A_SDimensionUnitPoints:
      return dimension.value;
    case A_SDimensionUnitFraction:
      return dimension.value * parentSize;
  }
}

#pragma mark - A_SLayoutSize

/**
 * Expresses a size with relative dimensions. Only used for calculations internally in A_SDimension.h
 */
typedef struct {
  A_SDimension width;
  A_SDimension height;
} A_SLayoutSize;

extern A_SLayoutSize const A_SLayoutSizeAuto;

/*
 * Creates an A_SLayoutSize with provided min and max dimensions.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SLayoutSize A_SLayoutSizeMake(A_SDimension width, A_SDimension height)
{
  A_SLayoutSize size;
  size.width = width;
  size.height = height;
  return size;
}

/**
 * Resolve this relative size relative to a parent size.
 */
A_SDISPLAYNODE_INLINE CGSize A_SLayoutSizeResolveSize(A_SLayoutSize layoutSize, CGSize parentSize, CGSize autoSize)
{
  return CGSizeMake(A_SDimensionResolve(layoutSize.width, parentSize.width, autoSize.width),
                    A_SDimensionResolve(layoutSize.height, parentSize.height, autoSize.height));
}

/*
 * Returns a string representation of a relative size.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT NSString *NSStringFromA_SLayoutSize(A_SLayoutSize size)
{
  return [NSString stringWithFormat:@"{%@, %@}",
          NSStringFromA_SDimension(size.width),
          NSStringFromA_SDimension(size.height)];
}

#pragma mark - A_SSizeRange

/**
 * Expresses an inclusive range of sizes. Used to provide a simple constraint to layout.
 */
typedef struct {
  CGSize min;
  CGSize max;
} A_SSizeRange;

/**
 * A size range with all dimensions zero.
 */
extern A_SSizeRange const A_SSizeRangeZero;

/**
 * A size range from zero to infinity in both directions.
 */
extern A_SSizeRange const A_SSizeRangeUnconstrained;

/**
 * Returns whether a size range has > 0.1 max width and max height.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SSizeRangeHasSignificantArea(A_SSizeRange sizeRange)
{
  static CGFloat const limit = 0.1f;
  return (sizeRange.max.width > limit && sizeRange.max.height > limit);
}

/**
 * Creates an A_SSizeRange with provided min and max size.
 */
A_SOVERLOADABLE A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SSizeRange A_SSizeRangeMake(CGSize min, CGSize max)
{
  A_SDisplayNodeCAssertPositiveReal(@"Range min width", min.width);
  A_SDisplayNodeCAssertPositiveReal(@"Range min height", min.height);
  A_SDisplayNodeCAssertInfOrPositiveReal(@"Range max width", max.width);
  A_SDisplayNodeCAssertInfOrPositiveReal(@"Range max height", max.height);
  A_SDisplayNodeCAssert(min.width <= max.width,
                       @"Range min width (%f) must not be larger than max width (%f).", min.width, max.width);
  A_SDisplayNodeCAssert(min.height <= max.height,
                       @"Range min height (%f) must not be larger than max height (%f).", min.height, max.height);
  A_SSizeRange sizeRange;
  sizeRange.min = min;
  sizeRange.max = max;
  return sizeRange;
}

/**
 * Creates an A_SSizeRange with provided size as both min and max.
 */
A_SOVERLOADABLE A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT A_SSizeRange A_SSizeRangeMake(CGSize exactSize)
{
  return A_SSizeRangeMake(exactSize, exactSize);
}

/**
 * Clamps the provided CGSize between the [min, max] bounds of this A_SSizeRange.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT CGSize A_SSizeRangeClamp(A_SSizeRange sizeRange, CGSize size)
{
  return CGSizeMake(MAX(sizeRange.min.width, MIN(sizeRange.max.width, size.width)),
                    MAX(sizeRange.min.height, MIN(sizeRange.max.height, size.height)));
}

/**
 * Intersects another size range. If the other size range does not overlap in either dimension, this size range
 * "wins" by returning a single point within its own range that is closest to the non-overlapping range.
 */
extern A_S_WARN_UNUSED_RESULT A_SSizeRange A_SSizeRangeIntersect(A_SSizeRange sizeRange, A_SSizeRange otherSizeRange);

/**
 * Returns whether two size ranges are equal in min and max size.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SSizeRangeEqualToSizeRange(A_SSizeRange lhs, A_SSizeRange rhs)
{
  return CGSizeEqualToSize(lhs.min, rhs.min) && CGSizeEqualToSize(lhs.max, rhs.max);
}

/**
 * Returns a string representation of a size range
 */
extern A_S_WARN_UNUSED_RESULT NSString *NSStringFromA_SSizeRange(A_SSizeRange sizeRange);

#if YOGA

#pragma mark - A_SEdgeInsets

typedef struct {
  A_SDimension top;
  A_SDimension left;
  A_SDimension bottom;
  A_SDimension right;
  A_SDimension start;
  A_SDimension end;
  A_SDimension horizontal;
  A_SDimension vertical;
  A_SDimension all;
} A_SEdgeInsets;

extern A_SEdgeInsets const A_SEdgeInsetsZero;

extern A_SEdgeInsets A_SEdgeInsetsMake(UIEdgeInsets edgeInsets);

#endif

NS_ASSUME_NONNULL_END
A_SDISPLAYNODE_EXTERN_C_END
