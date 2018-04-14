//
//  A_SYogaUtilities.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SYogaUtilities.h>

#if YOGA /* YOGA */

@implementation A_SDisplayNode (YogaHelpers)

+ (A_SDisplayNode *)yogaNode
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  [node.style yogaNodeCreateIfNeeded];
  return node;
}

+ (A_SDisplayNode *)yogaSpacerNode
{
  A_SDisplayNode *node = [A_SDisplayNode yogaNode];
  node.style.flexGrow = 1.0f;
  return node;
}

+ (A_SDisplayNode *)yogaVerticalStack
{
  A_SDisplayNode *node = [self yogaNode];
  node.style.flexDirection = A_SStackLayoutDirectionVertical;
  return node;
}

+ (A_SDisplayNode *)yogaHorizontalStack
{
  A_SDisplayNode *node = [self yogaNode];
  node.style.flexDirection = A_SStackLayoutDirectionHorizontal;
  return node;
}

@end

extern void A_SDisplayNodePerformBlockOnEveryYogaChild(A_SDisplayNode *node, void(^block)(A_SDisplayNode *node))
{
  if (node == nil) {
    return;
  }
  block(node);
  for (A_SDisplayNode *child in [node yogaChildren]) {
    A_SDisplayNodePerformBlockOnEveryYogaChild(child, block);
  }
}

#pragma mark - Yoga Type Conversion Helpers

YGAlign yogaAlignItems(A_SStackLayoutAlignItems alignItems)
{
  switch (alignItems) {
    case A_SStackLayoutAlignItemsNotSet:         return YGAlignAuto;
    case A_SStackLayoutAlignItemsStart:          return YGAlignFlexStart;
    case A_SStackLayoutAlignItemsEnd:            return YGAlignFlexEnd;
    case A_SStackLayoutAlignItemsCenter:         return YGAlignCenter;
    case A_SStackLayoutAlignItemsStretch:        return YGAlignStretch;
    case A_SStackLayoutAlignItemsBaselineFirst:  return YGAlignBaseline;
      // FIXME: WARNING, Yoga does not currently support last-baseline item alignment.
    case A_SStackLayoutAlignItemsBaselineLast:   return YGAlignBaseline;
  }
}

YGJustify yogaJustifyContent(A_SStackLayoutJustifyContent justifyContent)
{
  switch (justifyContent) {
    case A_SStackLayoutJustifyContentStart:        return YGJustifyFlexStart;
    case A_SStackLayoutJustifyContentCenter:       return YGJustifyCenter;
    case A_SStackLayoutJustifyContentEnd:          return YGJustifyFlexEnd;
    case A_SStackLayoutJustifyContentSpaceBetween: return YGJustifySpaceBetween;
    case A_SStackLayoutJustifyContentSpaceAround:  return YGJustifySpaceAround;
  }
}

YGAlign yogaAlignSelf(A_SStackLayoutAlignSelf alignSelf)
{
  switch (alignSelf) {
    case A_SStackLayoutAlignSelfStart:   return YGAlignFlexStart;
    case A_SStackLayoutAlignSelfCenter:  return YGAlignCenter;
    case A_SStackLayoutAlignSelfEnd:     return YGAlignFlexEnd;
    case A_SStackLayoutAlignSelfStretch: return YGAlignStretch;
    case A_SStackLayoutAlignSelfAuto:    return YGAlignAuto;
  }
}

YGFlexDirection yogaFlexDirection(A_SStackLayoutDirection direction)
{
  return direction == A_SStackLayoutDirectionVertical ? YGFlexDirectionColumn : YGFlexDirectionRow;
}

float yogaFloatForCGFloat(CGFloat value)
{
  if (value < CGFLOAT_MAX / 2) {
    return value;
  } else {
    return YGUndefined;
  }
}

float yogaDimensionToPoints(A_SDimension dimension)
{
  A_SDisplayNodeCAssert(dimension.unit == A_SDimensionUnitPoints,
                       @"Dimensions should not be type Fraction for this method: %f", dimension.value);
  return yogaFloatForCGFloat(dimension.value);
}

float yogaDimensionToPercent(A_SDimension dimension)
{
  A_SDisplayNodeCAssert(dimension.unit == A_SDimensionUnitFraction,
                       @"Dimensions should not be type Points for this method: %f", dimension.value);
  return 100.0 * yogaFloatForCGFloat(dimension.value);

}

A_SDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, A_SEdgeInsets insets)
{
  switch (edge) {
    case YGEdgeLeft:          return insets.left;
    case YGEdgeTop:           return insets.top;
    case YGEdgeRight:         return insets.right;
    case YGEdgeBottom:        return insets.bottom;
    case YGEdgeStart:         return insets.start;
    case YGEdgeEnd:           return insets.end;
    case YGEdgeHorizontal:    return insets.horizontal;
    case YGEdgeVertical:      return insets.vertical;
    case YGEdgeAll:           return insets.all;
    default: A_SDisplayNodeCAssert(NO, @"YGEdge other than A_SEdgeInsets is not supported.");
      return A_SDimensionAuto;
  }
}

void A_SLayoutElementYogaUpdateMeasureFunc(YGNodeRef yogaNode, id <A_SLayoutElement> layoutElement)
{
  if (yogaNode == NULL) {
    return;
  }
  BOOL hasMeasureFunc = (YGNodeGetMeasureFunc(yogaNode) != NULL);

  if (layoutElement != nil && [layoutElement implementsLayoutMethod]) {
    if (hasMeasureFunc == NO) {
      // Retain the Context object. This must be explicitly released with a
      // __bridge_transfer - YGNodeFree() is not sufficient.
      YGNodeSetContext(yogaNode, (__bridge_retained void *)layoutElement);
      YGNodeSetMeasureFunc(yogaNode, &A_SLayoutElementYogaMeasureFunc);
    }
    A_SDisplayNodeCAssert(YGNodeGetContext(yogaNode) == (__bridge void *)layoutElement,
                         @"Yoga node context should contain layoutElement: %@", layoutElement);
  } else if (hasMeasureFunc == YES) {
    // If we lack any of the conditions above, and currently have a measure func, get rid of it.
    // Release the __bridge_retained Context object.
    __unused id <A_SLayoutElement> element = (__bridge_transfer id)YGNodeGetContext(yogaNode);
    YGNodeSetContext(yogaNode, NULL);
    YGNodeSetMeasureFunc(yogaNode, NULL);
  }
}

YGSize A_SLayoutElementYogaMeasureFunc(YGNodeRef yogaNode, float width, YGMeasureMode widthMode,
                                      float height, YGMeasureMode heightMode)
{
  id <A_SLayoutElement> layoutElement = (__bridge id <A_SLayoutElement>)YGNodeGetContext(yogaNode);
  A_SDisplayNodeCAssert([layoutElement conformsToProtocol:@protocol(A_SLayoutElement)], @"Yoga context must be <A_SLayoutElement>");

  A_SSizeRange sizeRange;
  sizeRange.min = CGSizeZero;
  sizeRange.max = CGSizeMake(width, height);
  if (widthMode == YGMeasureModeExactly) {
    sizeRange.min.width = sizeRange.max.width;
  } else {
    // Mode is (YGMeasureModeAtMost | YGMeasureModeUndefined)
    A_SDimension minWidth = layoutElement.style.minWidth;
    sizeRange.min.width = (minWidth.unit == A_SDimensionUnitPoints ? yogaDimensionToPoints(minWidth) : 0.0);
  }
  if (heightMode == YGMeasureModeExactly) {
    sizeRange.min.height = sizeRange.max.height;
  } else {
    // Mode is (YGMeasureModeAtMost | YGMeasureModeUndefined)
    A_SDimension minHeight = layoutElement.style.minHeight;
    sizeRange.min.height = (minHeight.unit == A_SDimensionUnitPoints ? yogaDimensionToPoints(minHeight) : 0.0);
  }

  A_SDisplayNodeCAssert(isnan(sizeRange.min.width) == NO && isnan(sizeRange.min.height) == NO, @"Yoga size range for measurement should not have NaN in minimum");
  if (isnan(sizeRange.max.width)) {
    sizeRange.max.width = CGFLOAT_MAX;
  }
  if (isnan(sizeRange.max.height)) {
    sizeRange.max.height = CGFLOAT_MAX;
  }

  CGSize size = [[layoutElement layoutThatFits:sizeRange] size];
  return (YGSize){ .width = (float)size.width, .height = (float)size.height };
}

#endif /* YOGA */
