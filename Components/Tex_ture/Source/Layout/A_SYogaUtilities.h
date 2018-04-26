//
//  A_SYogaUtilities.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SAvailability.h>

#if YOGA /* YOGA */

#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>

// Should pass a string literal, not an NSString as the first argument to A_SYogaLog
#define A_SYogaLog(x, ...) as_log_verbose(A_SLayoutLog(), x, ##__VA_ARGS__);

@interface A_SDisplayNode (YogaHelpers)

+ (A_SDisplayNode *)yogaNode;
+ (A_SDisplayNode *)yogaSpacerNode;
+ (A_SDisplayNode *)yogaVerticalStack;
+ (A_SDisplayNode *)yogaHorizontalStack;

@end

extern void A_SDisplayNodePerformBlockOnEveryYogaChild(A_SDisplayNode *node, void(^block)(A_SDisplayNode *node));

A_SDISPLAYNODE_EXTERN_C_BEGIN

#pragma mark - Yoga Type Conversion Helpers

YGAlign yogaAlignItems(A_SStackLayoutAlignItems alignItems);
YGJustify yogaJustifyContent(A_SStackLayoutJustifyContent justifyContent);
YGAlign yogaAlignSelf(A_SStackLayoutAlignSelf alignSelf);
YGFlexDirection yogaFlexDirection(A_SStackLayoutDirection direction);
float yogaFloatForCGFloat(CGFloat value);
float yogaDimensionToPoints(A_SDimension dimension);
float yogaDimensionToPercent(A_SDimension dimension);
A_SDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, A_SEdgeInsets insets);

void A_SLayoutElementYogaUpdateMeasureFunc(YGNodeRef yogaNode, id <A_SLayoutElement> layoutElement);
YGSize A_SLayoutElementYogaMeasureFunc(YGNodeRef yogaNode,
                                      float width, YGMeasureMode widthMode,
                                      float height, YGMeasureMode heightMode);

#pragma mark - Yoga Style Setter Helpers

#define YGNODE_STYLE_SET_DIMENSION(yogaNode, property, dimension) \
  if (dimension.unit == A_SDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == A_SDimensionUnitFraction) { \
    YGNodeStyleSet##property##Percent(yogaNode, yogaDimensionToPercent(dimension)); \
  } else { \
    YGNodeStyleSet##property(yogaNode, YGUndefined); \
  }\

#define YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, property, dimension, edge) \
  if (dimension.unit == A_SDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, edge, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == A_SDimensionUnitFraction) { \
    YGNodeStyleSet##property##Percent(yogaNode, edge, yogaDimensionToPercent(dimension)); \
  } else { \
    YGNodeStyleSet##property(yogaNode, edge, YGUndefined); \
  } \

#define YGNODE_STYLE_SET_FLOAT_WITH_EDGE(yogaNode, property, dimension, edge) \
  if (dimension.unit == A_SDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, edge, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == A_SDimensionUnitFraction) { \
    A_SDisplayNodeAssert(NO, @"Unexpected Fraction value in applying ##property## values to YGNode"); \
  } else { \
    YGNodeStyleSet##property(yogaNode, edge, YGUndefined); \
  } \

A_SDISPLAYNODE_EXTERN_C_END

#endif /* YOGA */
