//
//  A_SStackLayoutSpecUtilities.h
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

#import <Async_DisplayKit/A_SStackLayoutSpec.h>

typedef struct {
  A_SStackLayoutDirection direction;
  CGFloat spacing;
  A_SStackLayoutJustifyContent justifyContent;
  A_SStackLayoutAlignItems alignItems;
  A_SStackLayoutFlexWrap flexWrap;
  A_SStackLayoutAlignContent alignContent;
  CGFloat lineSpacing;
} A_SStackLayoutSpecStyle;

inline CGFloat stackDimension(const A_SStackLayoutDirection direction, const CGSize size)
{
  return (direction == A_SStackLayoutDirectionVertical) ? size.height : size.width;
}

inline CGFloat crossDimension(const A_SStackLayoutDirection direction, const CGSize size)
{
  return (direction == A_SStackLayoutDirectionVertical) ? size.width : size.height;
}

inline BOOL compareCrossDimension(const A_SStackLayoutDirection direction, const CGSize a, const CGSize b)
{
  return crossDimension(direction, a) < crossDimension(direction, b);
}

inline CGPoint directionPoint(const A_SStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == A_SStackLayoutDirectionVertical) ? CGPointMake(cross, stack) : CGPointMake(stack, cross);
}

inline CGSize directionSize(const A_SStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == A_SStackLayoutDirectionVertical) ? CGSizeMake(cross, stack) : CGSizeMake(stack, cross);
}

inline void setStackValueToPoint(const A_SStackLayoutDirection direction, const CGFloat stack, CGPoint &point) {
  (direction == A_SStackLayoutDirectionVertical) ? (point.y = stack) : (point.x = stack);
}

inline A_SSizeRange directionSizeRange(const A_SStackLayoutDirection direction,
                                      const CGFloat stackMin,
                                      const CGFloat stackMax,
                                      const CGFloat crossMin,
                                      const CGFloat crossMax)
{
  return {directionSize(direction, stackMin, crossMin), directionSize(direction, stackMax, crossMax)};
}

inline A_SStackLayoutAlignItems alignment(A_SStackLayoutAlignSelf childAlignment, A_SStackLayoutAlignItems stackAlignment)
{
  switch (childAlignment) {
    case A_SStackLayoutAlignSelfCenter:
      return A_SStackLayoutAlignItemsCenter;
    case A_SStackLayoutAlignSelfEnd:
      return A_SStackLayoutAlignItemsEnd;
    case A_SStackLayoutAlignSelfStart:
      return A_SStackLayoutAlignItemsStart;
    case A_SStackLayoutAlignSelfStretch:
      return A_SStackLayoutAlignItemsStretch;
    case A_SStackLayoutAlignSelfAuto:
    default:
      return stackAlignment;
  }
}

inline A_SStackLayoutAlignItems alignment(A_SHorizontalAlignment alignment, A_SStackLayoutAlignItems defaultAlignment)
{
  switch (alignment) {
    case A_SHorizontalAlignmentLeft:
      return A_SStackLayoutAlignItemsStart;
    case A_SHorizontalAlignmentMiddle:
      return A_SStackLayoutAlignItemsCenter;
    case A_SHorizontalAlignmentRight:
      return A_SStackLayoutAlignItemsEnd;
    case A_SHorizontalAlignmentNone:
    default:
      return defaultAlignment;
  }
}

inline A_SStackLayoutAlignItems alignment(A_SVerticalAlignment alignment, A_SStackLayoutAlignItems defaultAlignment)
{
  switch (alignment) {
    case A_SVerticalAlignmentTop:
      return A_SStackLayoutAlignItemsStart;
    case A_SVerticalAlignmentCenter:
      return A_SStackLayoutAlignItemsCenter;
    case A_SVerticalAlignmentBottom:
      return A_SStackLayoutAlignItemsEnd;
    case A_SVerticalAlignmentNone:
    default:
      return defaultAlignment;
  }
}

inline A_SStackLayoutJustifyContent justifyContent(A_SHorizontalAlignment alignment, A_SStackLayoutJustifyContent defaultJustifyContent)
{
  switch (alignment) {
    case A_SHorizontalAlignmentLeft:
      return A_SStackLayoutJustifyContentStart;
    case A_SHorizontalAlignmentMiddle:
      return A_SStackLayoutJustifyContentCenter;
    case A_SHorizontalAlignmentRight:
      return A_SStackLayoutJustifyContentEnd;
    case A_SHorizontalAlignmentNone:
    default:
      return defaultJustifyContent;
  }
}

inline A_SStackLayoutJustifyContent justifyContent(A_SVerticalAlignment alignment, A_SStackLayoutJustifyContent defaultJustifyContent)
{
  switch (alignment) {
    case A_SVerticalAlignmentTop:
      return A_SStackLayoutJustifyContentStart;
    case A_SVerticalAlignmentCenter:
      return A_SStackLayoutJustifyContentCenter;
    case A_SVerticalAlignmentBottom:
      return A_SStackLayoutJustifyContentEnd;
    case A_SVerticalAlignmentNone:
    default:
      return defaultJustifyContent;
  }
}
