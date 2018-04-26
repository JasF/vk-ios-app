//
//  A_SStackPositionedLayout.mm
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

#import <Async_DisplayKit/A_SStackPositionedLayout.h>

#import <tgmath.h>
#import <numeric>

#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

static CGFloat crossOffsetForItem(const A_SStackLayoutSpecItem &item,
                                  const A_SStackLayoutSpecStyle &style,
                                  const CGFloat crossSize,
                                  const CGFloat baseline)
{
  switch (alignment(item.child.style.alignSelf, style.alignItems)) {
    case A_SStackLayoutAlignItemsEnd:
      return crossSize - crossDimension(style.direction, item.layout.size);
    case A_SStackLayoutAlignItemsCenter:
      return A_SFloorPixelValue((crossSize - crossDimension(style.direction, item.layout.size)) / 2);
    case A_SStackLayoutAlignItemsBaselineFirst:
    case A_SStackLayoutAlignItemsBaselineLast:
      return baseline - A_SStackUnpositionedLayout::baselineForItem(style, item);
    case A_SStackLayoutAlignItemsStart:
    case A_SStackLayoutAlignItemsStretch:
    case A_SStackLayoutAlignItemsNotSet:
      return 0;
  }
}

static void crossOffsetAndSpacingForEachLine(const std::size_t numOfLines,
                                             const CGFloat crossViolation,
                                             A_SStackLayoutAlignContent alignContent,
                                             CGFloat &offset,
                                             CGFloat &spacing)
{
  A_SDisplayNodeCAssertTrue(numOfLines > 0);
  
  // Handle edge cases
  if (alignContent == A_SStackLayoutAlignContentSpaceBetween && (crossViolation < kViolationEpsilon || numOfLines == 1)) {
    alignContent = A_SStackLayoutAlignContentStart;
  } else if (alignContent == A_SStackLayoutAlignContentSpaceAround && (crossViolation < kViolationEpsilon || numOfLines == 1)) {
    alignContent = A_SStackLayoutAlignContentCenter;
  }
  
  offset = 0;
  spacing = 0;
  
  switch (alignContent) {
    case A_SStackLayoutAlignContentCenter:
      offset = crossViolation / 2;
      break;
    case A_SStackLayoutAlignContentEnd:
      offset = crossViolation;
      break;
    case A_SStackLayoutAlignContentSpaceBetween:
      // Spacing between the items, no spaces at the edges, evenly distributed
      spacing = crossViolation / (numOfLines - 1);
      break;
    case A_SStackLayoutAlignContentSpaceAround: {
      // Spacing between items are twice the spacing on the edges
      CGFloat spacingUnit = crossViolation / (numOfLines * 2);
      offset = spacingUnit;
      spacing = spacingUnit * 2;
      break;
    }
    case A_SStackLayoutAlignContentStart:
    case A_SStackLayoutAlignContentStretch:
      break;
  }
}

static void stackOffsetAndSpacingForEachItem(const std::size_t numOfItems,
                                             const CGFloat stackViolation,
                                             A_SStackLayoutJustifyContent justifyContent,
                                             CGFloat &offset,
                                             CGFloat &spacing)
{
  A_SDisplayNodeCAssertTrue(numOfItems > 0);
  
  // Handle edge cases
  if (justifyContent == A_SStackLayoutJustifyContentSpaceBetween && (stackViolation < kViolationEpsilon || numOfItems == 1)) {
    justifyContent = A_SStackLayoutJustifyContentStart;
  } else if (justifyContent == A_SStackLayoutJustifyContentSpaceAround && (stackViolation < kViolationEpsilon || numOfItems == 1)) {
    justifyContent = A_SStackLayoutJustifyContentCenter;
  }
  
  offset = 0;
  spacing = 0;
  
  switch (justifyContent) {
    case A_SStackLayoutJustifyContentCenter:
      offset = stackViolation / 2;
      break;
    case A_SStackLayoutJustifyContentEnd:
      offset = stackViolation;
      break;
    case A_SStackLayoutJustifyContentSpaceBetween:
      // Spacing between the items, no spaces at the edges, evenly distributed
      spacing = stackViolation / (numOfItems - 1);
      break;
    case A_SStackLayoutJustifyContentSpaceAround: {
      // Spacing between items are twice the spacing on the edges
      CGFloat spacingUnit = stackViolation / (numOfItems * 2);
      offset = spacingUnit;
      spacing = spacingUnit * 2;
      break;
    }
    case A_SStackLayoutJustifyContentStart:
      break;
  }
}

static void positionItemsInLine(const A_SStackUnpositionedLine &line,
                                const A_SStackLayoutSpecStyle &style,
                                const CGPoint &startingPoint,
                                const CGFloat stackSpacing)
{
  CGPoint p = startingPoint;
  BOOL first = YES;
  
  for (const auto &item : line.items) {
    p = p + directionPoint(style.direction, item.child.style.spacingBefore, 0);
    if (!first) {
      p = p + directionPoint(style.direction, style.spacing + stackSpacing, 0);
    }
    first = NO;
    item.layout.position = p + directionPoint(style.direction, 0, crossOffsetForItem(item, style, line.crossSize, line.baseline));
    
    p = p + directionPoint(style.direction, stackDimension(style.direction, item.layout.size) + item.child.style.spacingAfter, 0);
  }
}

A_SStackPositionedLayout A_SStackPositionedLayout::compute(const A_SStackUnpositionedLayout &layout,
                                                         const A_SStackLayoutSpecStyle &style,
                                                         const A_SSizeRange &sizeRange)
{
  const auto &lines = layout.lines;
  if (lines.empty()) {
    return {};
  }
  
  const auto numOfLines = lines.size();
  const auto direction = style.direction;
  const auto alignContent = style.alignContent;
  const auto lineSpacing = style.lineSpacing;
  const auto justifyContent = style.justifyContent;
  const auto crossViolation = A_SStackUnpositionedLayout::computeCrossViolation(layout.crossDimensionSum, style, sizeRange);
  CGFloat crossOffset;
  CGFloat crossSpacing;
  crossOffsetAndSpacingForEachLine(numOfLines, crossViolation, alignContent, crossOffset, crossSpacing);
  
  std::vector<A_SStackLayoutSpecItem> positionedItems;
  CGPoint p = directionPoint(direction, 0, crossOffset);
  BOOL first = YES;
  for (const auto &line : lines) {
    if (!first) {
      p = p + directionPoint(direction, 0, crossSpacing + lineSpacing);
    }
    first = NO;
    
    const auto &items = line.items;
    const auto stackViolation = A_SStackUnpositionedLayout::computeStackViolation(line.stackDimensionSum, style, sizeRange);
    CGFloat stackOffset;
    CGFloat stackSpacing;
    stackOffsetAndSpacingForEachItem(items.size(), stackViolation, justifyContent, stackOffset, stackSpacing);
    
    setStackValueToPoint(direction, stackOffset, p);
    positionItemsInLine(line, style, p, stackSpacing);
    std::move(items.begin(), items.end(), std::back_inserter(positionedItems));
    
    p = p + directionPoint(direction, -stackOffset, line.crossSize);
  }

  const CGSize finalSize = directionSize(direction, layout.stackDimensionSum, layout.crossDimensionSum);
  return {std::move(positionedItems), A_SSizeRangeClamp(sizeRange, finalSize)};
}
