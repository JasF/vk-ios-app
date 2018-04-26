//
//  A_SStackLayoutDefines.h
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

#import <Async_DisplayKit/A_SBaseDefines.h>

/** The direction children are stacked in */
typedef NS_ENUM(NSUInteger, A_SStackLayoutDirection) {
  /** Children are stacked vertically */
  A_SStackLayoutDirectionVertical,
  /** Children are stacked horizontally */
  A_SStackLayoutDirectionHorizontal,
};

/** If no children are flexible, how should this spec justify its children in the available space? */
typedef NS_ENUM(NSUInteger, A_SStackLayoutJustifyContent) {
  /**
   On overflow, children overflow out of this spec's bounds on the right/bottom side.
   On underflow, children are left/top-aligned within this spec's bounds.
   */
  A_SStackLayoutJustifyContentStart,
  /**
   On overflow, children are centered and overflow on both sides.
   On underflow, children are centered within this spec's bounds in the stacking direction.
   */
  A_SStackLayoutJustifyContentCenter,
  /**
   On overflow, children overflow out of this spec's bounds on the left/top side.
   On underflow, children are right/bottom-aligned within this spec's bounds.
   */
  A_SStackLayoutJustifyContentEnd,
  /**
   On overflow or if the stack has only 1 child, this value is identical to A_SStackLayoutJustifyContentStart.
   Otherwise, the starting edge of the first child is at the starting edge of the stack, 
   the ending edge of the last child is at the ending edge of the stack, and the remaining children
   are distributed so that the spacing between any two adjacent ones is the same.
   If there is a remaining space after spacing division, it is combined with the last spacing (i.e the one between the last 2 children).
   */
  A_SStackLayoutJustifyContentSpaceBetween,
  /**
   On overflow or if the stack has only 1 child, this value is identical to A_SStackLayoutJustifyContentCenter.
   Otherwise, children are distributed such that the spacing between any two adjacent ones is the same,
   and the spacing between the first/last child and the stack edges is half the size of the spacing between children.
   If there is a remaining space after spacing division, it is combined with the last spacing (i.e the one between the last child and the stack ending edge).
   */
  A_SStackLayoutJustifyContentSpaceAround
};

/** Orientation of children along cross axis */
typedef NS_ENUM(NSUInteger, A_SStackLayoutAlignItems) {
  /** Align children to start of cross axis */
  A_SStackLayoutAlignItemsStart,
  /** Align children with end of cross axis */
  A_SStackLayoutAlignItemsEnd,
  /** Center children on cross axis */
  A_SStackLayoutAlignItemsCenter,
  /** Expand children to fill cross axis */
  A_SStackLayoutAlignItemsStretch,
  /** Children align to their first baseline. Only available for horizontal stack spec */
  A_SStackLayoutAlignItemsBaselineFirst,
  /** Children align to their last baseline. Only available for horizontal stack spec */
  A_SStackLayoutAlignItemsBaselineLast,
  A_SStackLayoutAlignItemsNotSet
};

/**
 Each child may override their parent stack's cross axis alignment.
 @see A_SStackLayoutAlignItems
 */
typedef NS_ENUM(NSUInteger, A_SStackLayoutAlignSelf) {
  /** Inherit alignment value from containing stack. */
  A_SStackLayoutAlignSelfAuto,
  /** Align to start of cross axis */
  A_SStackLayoutAlignSelfStart,
  /** Align with end of cross axis */
  A_SStackLayoutAlignSelfEnd,
  /** Center on cross axis */
  A_SStackLayoutAlignSelfCenter,
  /** Expand to fill cross axis */
  A_SStackLayoutAlignSelfStretch,
};

/** Whether children are stacked into a single or multiple lines. */
typedef NS_ENUM(NSUInteger, A_SStackLayoutFlexWrap) {
  A_SStackLayoutFlexWrapNoWrap,
  A_SStackLayoutFlexWrapWrap,
};

/** Orientation of lines along cross axis if there are multiple lines. */
typedef NS_ENUM(NSUInteger, A_SStackLayoutAlignContent) {
  A_SStackLayoutAlignContentStart,
  A_SStackLayoutAlignContentCenter,
  A_SStackLayoutAlignContentEnd,
  A_SStackLayoutAlignContentSpaceBetween,
  A_SStackLayoutAlignContentSpaceAround,
  A_SStackLayoutAlignContentStretch,
};

/** Orientation of children along horizontal axis */
typedef NS_ENUM(NSUInteger, A_SHorizontalAlignment) {
  /** No alignment specified. Default value */
  A_SHorizontalAlignmentNone,
  /** Left aligned */
  A_SHorizontalAlignmentLeft,
  /** Center aligned */
  A_SHorizontalAlignmentMiddle,
  /** Right aligned */
  A_SHorizontalAlignmentRight,

  // After 2.0 has landed, we'll add A_SDISPLAYNODE_DEPRECATED here - for now, avoid triggering errors for projects with -Werror
  /** @deprecated Use A_SHorizontalAlignmentLeft instead */
  A_SAlignmentLeft A_SDISPLAYNODE_DEPRECATED = A_SHorizontalAlignmentLeft,
  /** @deprecated Use A_SHorizontalAlignmentMiddle instead */
  A_SAlignmentMiddle A_SDISPLAYNODE_DEPRECATED = A_SHorizontalAlignmentMiddle,
  /** @deprecated Use A_SHorizontalAlignmentRight instead */
  A_SAlignmentRight A_SDISPLAYNODE_DEPRECATED = A_SHorizontalAlignmentRight,
};

/** Orientation of children along vertical axis */
typedef NS_ENUM(NSUInteger, A_SVerticalAlignment) {
  /** No alignment specified. Default value */
  A_SVerticalAlignmentNone,
  /** Top aligned */
  A_SVerticalAlignmentTop,
  /** Center aligned */
  A_SVerticalAlignmentCenter,
  /** Bottom aligned */
  A_SVerticalAlignmentBottom,

  // After 2.0 has landed, we'll add A_SDISPLAYNODE_DEPRECATED here - for now, avoid triggering errors for projects with -Werror
  /** @deprecated Use A_SVerticalAlignmentTop instead */
  A_SAlignmentTop A_SDISPLAYNODE_DEPRECATED = A_SVerticalAlignmentTop,
  /** @deprecated Use A_SVerticalAlignmentCenter instead */
  A_SAlignmentCenter A_SDISPLAYNODE_DEPRECATED = A_SVerticalAlignmentCenter,
  /** @deprecated Use A_SVerticalAlignmentBottom instead */
  A_SAlignmentBottom A_SDISPLAYNODE_DEPRECATED = A_SVerticalAlignmentBottom,
};
