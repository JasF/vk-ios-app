//
//  A_SDimensionInternal.mm
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

#import <Async_DisplayKit/A_SDimensionInternal.h>

#pragma mark - A_SLayoutElementSize

NSString *NSStringFromA_SLayoutElementSize(A_SLayoutElementSize size)
{
  return [NSString stringWithFormat:
          @"<A_SLayoutElementSize: exact=%@, min=%@, max=%@>",
          NSStringFromA_SLayoutSize(A_SLayoutSizeMake(size.width, size.height)),
          NSStringFromA_SLayoutSize(A_SLayoutSizeMake(size.minWidth, size.minHeight)),
          NSStringFromA_SLayoutSize(A_SLayoutSizeMake(size.maxWidth, size.maxHeight))];
}

A_SDISPLAYNODE_INLINE void A_SLayoutElementSizeConstrain(CGFloat minVal, CGFloat exactVal, CGFloat maxVal, CGFloat *outMin, CGFloat *outMax)
{
    NSCAssert(!isnan(minVal), @"minVal must not be NaN");
    NSCAssert(!isnan(maxVal), @"maxVal must not be NaN");
    // Avoid use of min/max primitives since they're harder to reason
    // about in the presence of NaN (in exactVal)
    // Follow CSS: min overrides max overrides exact.

    // Begin with the min/max range
    *outMin = minVal;
    *outMax = maxVal;
    if (maxVal <= minVal) {
        // min overrides max and exactVal is irrelevant
        *outMax = minVal;
        return;
    }
    if (isnan(exactVal)) {
        // no exact value, so leave as a min/max range
        return;
    }
    if (exactVal > maxVal) {
        // clip to max value
        *outMin = maxVal;
    } else if (exactVal < minVal) {
        // clip to min value
        *outMax = minVal;
    } else {
        // use exact value
        *outMin = *outMax = exactVal;
    }
}

A_SSizeRange A_SLayoutElementSizeResolveAutoSize(A_SLayoutElementSize size, const CGSize parentSize, A_SSizeRange autoA_SSizeRange)
{
  CGSize resolvedExact = A_SLayoutSizeResolveSize(A_SLayoutSizeMake(size.width, size.height), parentSize, {NAN, NAN});
  CGSize resolvedMin = A_SLayoutSizeResolveSize(A_SLayoutSizeMake(size.minWidth, size.minHeight), parentSize, autoA_SSizeRange.min);
  CGSize resolvedMax = A_SLayoutSizeResolveSize(A_SLayoutSizeMake(size.maxWidth, size.maxHeight), parentSize, autoA_SSizeRange.max);
  
  CGSize rangeMin, rangeMax;
  A_SLayoutElementSizeConstrain(resolvedMin.width, resolvedExact.width, resolvedMax.width, &rangeMin.width, &rangeMax.width);
  A_SLayoutElementSizeConstrain(resolvedMin.height, resolvedExact.height, resolvedMax.height, &rangeMin.height, &rangeMax.height);
  return {rangeMin, rangeMax};
}
