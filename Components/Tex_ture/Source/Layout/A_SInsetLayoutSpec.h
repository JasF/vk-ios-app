//
//  A_SInsetLayoutSpec.h
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

#import <Async_DisplayKit/A_SLayoutSpec.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A layout spec that wraps another layoutElement child, applying insets around it.

 If the child has a size specified as a fraction, the fraction is resolved against this spec's parent
 size **after** applying insets.

 @example A_SOuterLayoutSpec contains an A_SInsetLayoutSpec with an A_SInnerLayoutSpec. Suppose that:
 - A_SOuterLayoutSpec is 200pt wide.
 - A_SInnerLayoutSpec specifies its width as 100%.
 - The A_SInsetLayoutSpec has insets of 10pt on every side.
 A_SInnerLayoutSpec will have size 180pt, not 200pt, because it receives a parent size that has been adjusted for insets.

 If you're familiar with CSS: A_SInsetLayoutSpec's child behaves similarly to "box-sizing: border-box".

 An infinite inset is resolved as an inset equal to all remaining space after applying the other insets and child size.
 @example An A_SInsetLayoutSpec with an infinite left inset and 10px for all other edges will position it's child 10px from the right edge.
 */
@interface A_SInsetLayoutSpec : A_SLayoutSpec

@property (nonatomic, assign) UIEdgeInsets insets;

/**
 @param insets The amount of space to inset on each side.
 @param child The wrapped child to inset.
 */
+ (instancetype)insetLayoutSpecWithInsets:(UIEdgeInsets)insets child:(id<A_SLayoutElement>)child A_S_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
