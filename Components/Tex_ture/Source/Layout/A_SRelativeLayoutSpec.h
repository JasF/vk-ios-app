//
//  A_SRelativeLayoutSpec.h
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

/** 
  * How the child is positioned within the spec.
  *
  * The default option will position the child at point 0.
  * Swift: use [] for the default behavior.
  */
typedef NS_ENUM(NSUInteger, A_SRelativeLayoutSpecPosition) {
  /** The child is positioned at point 0 */ 
  A_SRelativeLayoutSpecPositionNone = 0,
  /** The child is positioned at point 0 relatively to the layout axis (ie left / top most) */
  A_SRelativeLayoutSpecPositionStart = 1,
  /** The child is centered along the specified axis */
  A_SRelativeLayoutSpecPositionCenter = 2,
  /** The child is positioned at the maximum point of the layout axis (ie right / bottom most) */
  A_SRelativeLayoutSpecPositionEnd = 3,
};

/** 
  * How much space the spec will take up.
  *
  * The default option will allow the spec to take up the maximum size possible.
  * Swift: use [] for the default behavior.
  */
typedef NS_OPTIONS(NSUInteger, A_SRelativeLayoutSpecSizingOption) {
  /** The spec will take up the maximum size possible */
  A_SRelativeLayoutSpecSizingOptionDefault,
  /** The spec will take up the minimum size possible along the X axis */
  A_SRelativeLayoutSpecSizingOptionMinimumWidth = 1 << 0,
  /** The spec will take up the minimum size possible along the Y axis */
  A_SRelativeLayoutSpecSizingOptionMinimumHeight = 1 << 1,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  A_SRelativeLayoutSpecSizingOptionMinimumSize = A_SRelativeLayoutSpecSizingOptionMinimumWidth | A_SRelativeLayoutSpecSizingOptionMinimumHeight,
};

NS_ASSUME_NONNULL_BEGIN

/** Lays out a single layoutElement child and positions it within the layout bounds according to vertical and horizontal positional specifiers.
 *  Can position the child at any of the 4 corners, or the middle of any of the 4 edges, as well as the center - similar to "9-part" image areas.
 */
@interface A_SRelativeLayoutSpec : A_SLayoutSpec

// You may create a spec with alloc / init, then set any non-default properties; or use a convenience initialize that accepts all properties.
@property (nonatomic, assign) A_SRelativeLayoutSpecPosition horizontalPosition;
@property (nonatomic, assign) A_SRelativeLayoutSpecPosition verticalPosition;
@property (nonatomic, assign) A_SRelativeLayoutSpecSizingOption sizingOption;

/*!
 * @discussion convenience constructor for a A_SRelativeLayoutSpec
 * @param horizontalPosition how to position the item on the horizontal (x) axis
 * @param verticalPosition how to position the item on the vertical (y) axis
 * @param sizingOption how much size to take up
 * @param child the child to layout
 * @return a configured A_SRelativeLayoutSpec
 */
+ (instancetype)relativePositionLayoutSpecWithHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition
                                                verticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition
                                                    sizingOption:(A_SRelativeLayoutSpecSizingOption)sizingOption
                                                           child:(id<A_SLayoutElement>)child A_S_WARN_UNUSED_RESULT;

/*!
 * @discussion convenience initializer for a A_SRelativeLayoutSpec
 * @param horizontalPosition how to position the item on the horizontal (x) axis
 * @param verticalPosition how to position the item on the vertical (y) axis
 * @param sizingOption how much size to take up
 * @param child the child to layout
 * @return a configured A_SRelativeLayoutSpec
 */
- (instancetype)initWithHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition
                          verticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition
                              sizingOption:(A_SRelativeLayoutSpecSizingOption)sizingOption
                                     child:(id<A_SLayoutElement>)child;

@end

NS_ASSUME_NONNULL_END

