//
//  A_SAbstractLayoutController.mm
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

#import <Async_DisplayKit/A_SAbstractLayoutController.h>

#import <Async_DisplayKit/A_SAssert.h>

#include <vector>

extern A_SRangeTuningParameters const A_SRangeTuningParametersZero = {};

extern BOOL A_SRangeTuningParametersEqualToRangeTuningParameters(A_SRangeTuningParameters lhs, A_SRangeTuningParameters rhs)
{
  return lhs.leadingBufferScreenfuls == rhs.leadingBufferScreenfuls && lhs.trailingBufferScreenfuls == rhs.trailingBufferScreenfuls;
}

extern A_SDirectionalScreenfulBuffer A_SDirectionalScreenfulBufferHorizontal(A_SScrollDirection scrollDirection,
                                                                    A_SRangeTuningParameters rangeTuningParameters)
{
  A_SDirectionalScreenfulBuffer horizontalBuffer = {0, 0};
  BOOL movingRight = A_SScrollDirectionContainsRight(scrollDirection);
  
  horizontalBuffer.positiveDirection = movingRight ? rangeTuningParameters.leadingBufferScreenfuls
                                                   : rangeTuningParameters.trailingBufferScreenfuls;
  horizontalBuffer.negativeDirection = movingRight ? rangeTuningParameters.trailingBufferScreenfuls
                                                   : rangeTuningParameters.leadingBufferScreenfuls;
  return horizontalBuffer;
}

extern A_SDirectionalScreenfulBuffer A_SDirectionalScreenfulBufferVertical(A_SScrollDirection scrollDirection,
                                                                  A_SRangeTuningParameters rangeTuningParameters)
{
  A_SDirectionalScreenfulBuffer verticalBuffer = {0, 0};
  BOOL movingDown = A_SScrollDirectionContainsDown(scrollDirection);
  
  verticalBuffer.positiveDirection = movingDown ? rangeTuningParameters.leadingBufferScreenfuls
                                                : rangeTuningParameters.trailingBufferScreenfuls;
  verticalBuffer.negativeDirection = movingDown ? rangeTuningParameters.trailingBufferScreenfuls
                                                : rangeTuningParameters.leadingBufferScreenfuls;
  return verticalBuffer;
}

extern CGRect CGRectExpandHorizontally(CGRect rect, A_SDirectionalScreenfulBuffer buffer)
{
  CGFloat negativeDirectionWidth = buffer.negativeDirection * rect.size.width;
  CGFloat positiveDirectionWidth = buffer.positiveDirection * rect.size.width;
  rect.size.width = negativeDirectionWidth + rect.size.width + positiveDirectionWidth;
  rect.origin.x -= negativeDirectionWidth;
  return rect;
}

extern CGRect CGRectExpandVertically(CGRect rect, A_SDirectionalScreenfulBuffer buffer)
{
  CGFloat negativeDirectionHeight = buffer.negativeDirection * rect.size.height;
  CGFloat positiveDirectionHeight = buffer.positiveDirection * rect.size.height;
  rect.size.height = negativeDirectionHeight + rect.size.height + positiveDirectionHeight;
  rect.origin.y -= negativeDirectionHeight;
  return rect;
}

extern CGRect CGRectExpandToRangeWithScrollableDirections(CGRect rect, A_SRangeTuningParameters tuningParameters,
                                                   A_SScrollDirection scrollableDirections, A_SScrollDirection scrollDirection)
{
  // Can scroll horizontally - expand the range appropriately
  if (A_SScrollDirectionContainsHorizontalDirection(scrollableDirections)) {
    A_SDirectionalScreenfulBuffer horizontalBuffer = A_SDirectionalScreenfulBufferHorizontal(scrollDirection, tuningParameters);
    rect = CGRectExpandHorizontally(rect, horizontalBuffer);
  }

  // Can scroll vertically - expand the range appropriately
  if (A_SScrollDirectionContainsVerticalDirection(scrollableDirections)) {
    A_SDirectionalScreenfulBuffer verticalBuffer = A_SDirectionalScreenfulBufferVertical(scrollDirection, tuningParameters);
    rect = CGRectExpandVertically(rect, verticalBuffer);
  }
  
  return rect;
}

@interface A_SAbstractLayoutController () {
  std::vector<std::vector<A_SRangeTuningParameters>> _tuningParameters;
}
@end

@implementation A_SAbstractLayoutController

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  A_SDisplayNodeAssert(self.class != [A_SAbstractLayoutController class], @"Should never create instances of abstract class A_SAbstractLayoutController.");
  
  _tuningParameters = std::vector<std::vector<A_SRangeTuningParameters>> (A_SLayoutRangeModeCount, std::vector<A_SRangeTuningParameters> (A_SLayoutRangeTypeCount));
  
  _tuningParameters[A_SLayoutRangeModeFull][A_SLayoutRangeTypeDisplay] = {
    .leadingBufferScreenfuls = 1.0,
    .trailingBufferScreenfuls = 0.5
  };
  _tuningParameters[A_SLayoutRangeModeFull][A_SLayoutRangeTypePreload] = {
    .leadingBufferScreenfuls = 2.5,
    .trailingBufferScreenfuls = 1.5
  };
  
  _tuningParameters[A_SLayoutRangeModeMinimum][A_SLayoutRangeTypeDisplay] = {
    .leadingBufferScreenfuls = 0.25,
    .trailingBufferScreenfuls = 0.25
  };
  _tuningParameters[A_SLayoutRangeModeMinimum][A_SLayoutRangeTypePreload] = {
    .leadingBufferScreenfuls = 0.5,
    .trailingBufferScreenfuls = 0.25
  };

  _tuningParameters[A_SLayoutRangeModeVisibleOnly][A_SLayoutRangeTypeDisplay] = {
    .leadingBufferScreenfuls = 0,
    .trailingBufferScreenfuls = 0
  };
  _tuningParameters[A_SLayoutRangeModeVisibleOnly][A_SLayoutRangeTypePreload] = {
    .leadingBufferScreenfuls = 0,
    .trailingBufferScreenfuls = 0
  };
  
  // The Low Memory range mode has special handling. Because a zero range still includes the visible area / bounds,
  // in order to implement the behavior of releasing all graphics memory (backing stores), A_SRangeController must check
  // for this range mode and use an empty set for displayIndexPaths rather than querying the A_SLayoutController for the indexPaths.
  _tuningParameters[A_SLayoutRangeModeLowMemory][A_SLayoutRangeTypeDisplay] = {
    .leadingBufferScreenfuls = 0,
    .trailingBufferScreenfuls = 0
  };
  _tuningParameters[A_SLayoutRangeModeLowMemory][A_SLayoutRangeTypePreload] = {
    .leadingBufferScreenfuls = 0,
    .trailingBufferScreenfuls = 0
  };
  
  return self;
}

#pragma mark - Tuning Parameters

- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType
{
  return [self tuningParametersForRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType
{
  return [self setTuningParameters:tuningParameters forRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  A_SDisplayNodeAssert(rangeMode < _tuningParameters.size() && rangeType < _tuningParameters[rangeMode].size(), @"Requesting a range that is OOB for the configured tuning parameters");
  return _tuningParameters[rangeMode][rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  A_SDisplayNodeAssert(rangeMode < _tuningParameters.size() && rangeType < _tuningParameters[rangeMode].size(), @"Setting a range that is OOB for the configured tuning parameters");
  _tuningParameters[rangeMode][rangeType] = tuningParameters;
}

#pragma mark - Abstract Index Path Range Support

- (NSHashTable<A_SCollectionElement *> *)elementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType map:(A_SElementMap *)map
{
  A_SDisplayNodeAssertNotSupported();
  return nil;
}

- (void)allElementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode displaySet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)displaySet preloadSet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)preloadSet map:(A_SElementMap *)map
{
  A_SDisplayNodeAssertNotSupported();
}

@end
