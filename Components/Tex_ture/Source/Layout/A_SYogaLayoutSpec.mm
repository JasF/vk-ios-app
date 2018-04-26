//
//  A_SYogaLayoutSpec.mm
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

#import <Async_DisplayKit/A_SYogaLayoutSpec.h>
#import <Async_DisplayKit/A_SYogaUtilities.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#define YOGA_LAYOUT_LOGGING 0

@implementation A_SYogaLayoutSpec

- (A_SLayout *)layoutForYogaNode:(YGNodeRef)yogaNode
{
  BOOL isRootNode = (YGNodeGetParent(yogaNode) == NULL);
  uint32_t childCount = YGNodeGetChildCount(yogaNode);

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:childCount];
  for (uint32_t i = 0; i < childCount; i++) {
    [sublayouts addObject:[self layoutForYogaNode:YGNodeGetChild(yogaNode, i)]];
  }

  id <A_SLayoutElement> layoutElement = (__bridge id <A_SLayoutElement>)YGNodeGetContext(yogaNode);
  CGSize size = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));

  if (isRootNode) {
    // The layout for root should have position CGPointNull, but include the calculated size.
    return [A_SLayout layoutWithLayoutElement:layoutElement size:size sublayouts:sublayouts];
  } else {
    CGPoint position = CGPointMake(YGNodeLayoutGetLeft(yogaNode), YGNodeLayoutGetTop(yogaNode));
    return [A_SLayout layoutWithLayoutElement:layoutElement size:size position:position sublayouts:nil];
  }
}

- (void)destroyYogaNode:(YGNodeRef)yogaNode
{
  // Release the __bridge_retained Context object.
  __unused id <A_SLayoutElement> element = (__bridge_transfer id)YGNodeGetContext(yogaNode);
  YGNodeFree(yogaNode);
}

- (void)setupYogaNode:(YGNodeRef)yogaNode forElement:(id <A_SLayoutElement>)element withParentYogaNode:(YGNodeRef)parentYogaNode
{
  A_SLayoutElementStyle *style = element.style;

  // Retain the Context object. This must be explicitly released with a __bridge_transfer; YGNodeFree() is not sufficient.
  YGNodeSetContext(yogaNode, (__bridge_retained void *)element);

  YGNodeStyleSetDirection     (yogaNode, style.direction);

  YGNodeStyleSetFlexWrap      (yogaNode, style.flexWrap);
  YGNodeStyleSetFlexGrow      (yogaNode, style.flexGrow);
  YGNodeStyleSetFlexShrink    (yogaNode, style.flexShrink);
  YGNODE_STYLE_SET_DIMENSION  (yogaNode, FlexBasis, style.flexBasis);

  YGNodeStyleSetFlexDirection (yogaNode, yogaFlexDirection(style.flexDirection));
  YGNodeStyleSetJustifyContent(yogaNode, yogaJustifyContent(style.justifyContent));
  YGNodeStyleSetAlignSelf     (yogaNode, yogaAlignSelf(style.alignSelf));
  A_SStackLayoutAlignItems alignItems = style.alignItems;
  if (alignItems != A_SStackLayoutAlignItemsNotSet) {
    YGNodeStyleSetAlignItems(yogaNode, yogaAlignItems(alignItems));
  }

  YGNodeStyleSetPositionType  (yogaNode, style.positionType);
  A_SEdgeInsets position = style.position;
  A_SEdgeInsets margin   = style.margin;
  A_SEdgeInsets padding  = style.padding;
  A_SEdgeInsets border   = style.border;

  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
    YGNODE_STYLE_SET_FLOAT_WITH_EDGE(yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
    edge = (YGEdge)(edge + 1);
  }

  CGFloat aspectRatio = style.aspectRatio;
  if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
    YGNodeStyleSetAspectRatio(yogaNode, aspectRatio);
  }

  // For the root node, we use rootConstrainedSize above. For children, consult the style for their size.
  if (parentYogaNode != NULL) {
    YGNodeInsertChild(parentYogaNode, yogaNode, YGNodeGetChildCount(parentYogaNode));

    YGNODE_STYLE_SET_DIMENSION(yogaNode, Width, style.width);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, Height, style.height);

    YGNODE_STYLE_SET_DIMENSION(yogaNode, MinWidth, style.minWidth);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, MinHeight, style.minHeight);

    YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxWidth, style.maxWidth);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxHeight, style.maxHeight);

    YGNodeSetMeasureFunc(yogaNode, &A_SLayoutElementYogaMeasureFunc);
  }

  // TODO(appleguy): STYLE SETTER METHODS LEFT TO IMPLEMENT: YGNodeStyleSetOverflow, YGNodeStyleSetFlex
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)layoutElementSize
                 relativeToParentSize:(CGSize)parentSize
{
  A_SSizeRange styleAndParentSize = A_SLayoutElementSizeResolve(layoutElementSize, parentSize);
  const A_SSizeRange rootConstrainedSize = A_SSizeRangeIntersect(constrainedSize, styleAndParentSize);

  YGNodeRef rootYogaNode = YGNodeNew();

  // YGNodeCalculateLayout currently doesn't offer the ability to pass a minimum size (max is passed there).
  // Apply the constrainedSize.min directly to the root node so that layout accounts for it.
  YGNodeStyleSetMinWidth (rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.width));
  YGNodeStyleSetMinHeight(rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.height));

  // It's crucial to set these values. YGNodeCalculateLayout has unusual behavior for its width and height parameters:
  // 1. If no maximum size set, infer this means YGMeasureModeExactly. Even if a small minWidth & minHeight are set,
  //    these will never be used because the output size of the root will always exactly match this value.
  // 2. If a maximum size is set, infer that this means YGMeasureModeAtMost, and allow down to the min* values in output.
  YGNodeStyleSetMaxWidthPercent(rootYogaNode, 100.0);
  YGNodeStyleSetMaxHeightPercent(rootYogaNode, 100.0);

  [self setupYogaNode:rootYogaNode forElement:self.rootNode withParentYogaNode:NULL];
  for (id <A_SLayoutElement> child in self.children) {
    YGNodeRef yogaNode = YGNodeNew();
    [self setupYogaNode:yogaNode forElement:child withParentYogaNode:rootYogaNode];
  }

  // It is crucial to use yogaFloat... to convert CGFLOAT_MAX into YGUndefined here.
  YGNodeCalculateLayout(rootYogaNode,
                        yogaFloatForCGFloat(rootConstrainedSize.max.width),
                        yogaFloatForCGFloat(rootConstrainedSize.max.height),
                        YGDirectionInherit);

  A_SLayout *layout = [self layoutForYogaNode:rootYogaNode];

#if YOGA_LAYOUT_LOGGING
  // Concurrent layouts will interleave the NSLog messages unless we serialize.
  // Use @synchornize rather than trampolining to the main thread so the tree state isn't changed.
  @synchronized ([A_SDisplayNode class]) {
    NSLog(@"****************************************************************************");
    NSLog(@"******************** STARTING YOGA -> A_SLAYOUT CREATION ********************");
    NSLog(@"****************************************************************************");
      NSLog(@"node = %@", self.rootNode);
      NSLog(@"style = %@", self.rootNode.style);
      YGNodePrint(rootYogaNode, (YGPrintOptions)(YGPrintOptionsStyle | YGPrintOptionsLayout));
  }
  NSLog(@"rootConstraint = (%@, %@), layout = %@, sublayouts = %@", NSStringFromCGSize(rootConstrainedSize.min), NSStringFromCGSize(rootConstrainedSize.max), layout, layout.sublayouts);
#endif

  while(YGNodeGetChildCount(rootYogaNode) > 0) {
    YGNodeRef yogaNode = YGNodeGetChild(rootYogaNode, 0);
    [self destroyYogaNode:yogaNode];
  }
  [self destroyYogaNode:rootYogaNode];

  return layout;
}

@end

#endif /* YOGA */
