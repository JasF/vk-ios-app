//
//  A_SStackUnpositionedLayout.h
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

#import <vector>

#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SStackLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SStackLayoutSpec.h>

/** The threshold that determines if a violation has actually occurred. */
extern CGFloat const kViolationEpsilon;

struct A_SStackLayoutSpecChild {
  /** The original source child. */
  id<A_SLayoutElement> element;
  /** Style object of element. */
  A_SLayoutElementStyle *style;
  /** Size object of the element */
  A_SLayoutElementSize size;
};

struct A_SStackLayoutSpecItem {
  /** The original source child. */
  A_SStackLayoutSpecChild child;
  /** The proposed layout or nil if no is calculated yet. */
  A_SLayout *layout;
};

struct A_SStackUnpositionedLine {
  /** The set of proposed children in this line, each contains child layout, not yet positioned. */
  std::vector<A_SStackLayoutSpecItem> items;
  /** The total size of the children in the stack dimension, including all spacing. */
  CGFloat stackDimensionSum;
  /** The size in the cross dimension */
  CGFloat crossSize;
  /** The baseline of the stack which baseline aligned children should align to */
  CGFloat baseline;
};

/** Represents a set of stack layout children that have their final layout computed, but are not yet positioned. */
struct A_SStackUnpositionedLayout {
  /** The set of proposed lines, each contains child layouts, not yet positioned. */
  const std::vector<A_SStackUnpositionedLine> lines;
  /** 
   * In a single line stack (e.g no wrao), this is the total size of the children in the stack dimension, including all spacing.
   * In a multi-line stack, this is the largest stack dimension among lines.
   */
  const CGFloat stackDimensionSum;
  const CGFloat crossDimensionSum;
  
  /** Given a set of children, computes the unpositioned layouts for those children. */
  static A_SStackUnpositionedLayout compute(const std::vector<A_SStackLayoutSpecChild> &children,
                                           const A_SStackLayoutSpecStyle &style,
                                           const A_SSizeRange &sizeRange,
                                           const BOOL concurrent);
  
  static CGFloat baselineForItem(const A_SStackLayoutSpecStyle &style,
                                 const A_SStackLayoutSpecItem &l);
  
  static CGFloat computeStackViolation(const CGFloat stackDimensionSum,
                                       const A_SStackLayoutSpecStyle &style,
                                       const A_SSizeRange &sizeRange);

  static CGFloat computeCrossViolation(const CGFloat crossDimensionSum,
                                       const A_SStackLayoutSpecStyle &style,
                                       const A_SSizeRange &sizeRange);
};
