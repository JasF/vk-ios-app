//
//  A_SCollectionLayoutDefines.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SCollectionLayoutDefines.h>

extern A_SSizeRange A_SSizeRangeForCollectionLayoutThatFitsViewportSize(CGSize viewportSize, A_SScrollDirection scrollableDirections)
{
  A_SSizeRange sizeRange = A_SSizeRangeUnconstrained;
  if (A_SScrollDirectionContainsVerticalDirection(scrollableDirections) == NO) {
    sizeRange.min.height = viewportSize.height;
    sizeRange.max.height = viewportSize.height;
  }
  if (A_SScrollDirectionContainsHorizontalDirection(scrollableDirections) == NO) {
    sizeRange.min.width = viewportSize.width;
    sizeRange.max.width = viewportSize.width;
  }
  return sizeRange;
}
