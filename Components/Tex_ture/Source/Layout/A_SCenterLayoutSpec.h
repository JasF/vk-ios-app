//
//  A_SCenterLayoutSpec.h
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

#import <Async_DisplayKit/A_SRelativeLayoutSpec.h>

/** 
  * How the child is centered within the spec.
  *
  * The default option will position the child at {0,0} relatively to the layout bound.
  * Swift: use [] for the default behavior.
  */
typedef NS_OPTIONS(NSUInteger, A_SCenterLayoutSpecCenteringOptions) {
  /** The child is positioned in {0,0} relatively to the layout bounds */
  A_SCenterLayoutSpecCenteringNone = 0,
  /** The child is centered along the X axis */
  A_SCenterLayoutSpecCenteringX = 1 << 0,
  /** The child is centered along the Y axis */
  A_SCenterLayoutSpecCenteringY = 1 << 1,
  /** Convenience option to center both along the X and Y axis */
  A_SCenterLayoutSpecCenteringXY = A_SCenterLayoutSpecCenteringX | A_SCenterLayoutSpecCenteringY
};

/** 
  * How much space the spec will take up.
  *
  * The default option will allow the spec to take up the maximum size possible.
  * Swift: use [] for the default behavior.
  */
typedef NS_OPTIONS(NSUInteger, A_SCenterLayoutSpecSizingOptions) {
  /** The spec will take up the maximum size possible */
  A_SCenterLayoutSpecSizingOptionDefault = A_SRelativeLayoutSpecSizingOptionDefault,
  /** The spec will take up the minimum size possible along the X axis */
  A_SCenterLayoutSpecSizingOptionMinimumX = A_SRelativeLayoutSpecSizingOptionMinimumWidth,
  /** The spec will take up the minimum size possible along the Y axis */
  A_SCenterLayoutSpecSizingOptionMinimumY = A_SRelativeLayoutSpecSizingOptionMinimumHeight,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  A_SCenterLayoutSpecSizingOptionMinimumXY = A_SRelativeLayoutSpecSizingOptionMinimumSize
};

NS_ASSUME_NONNULL_BEGIN

/** Lays out a single layoutElement child and position it so that it is centered into the layout bounds.
  * NOTE: A_SRelativeLayoutSpec offers all of the capabilities of Center, and more.
  * Check it out if you would like to be able to position the child at any corner or the middle of an edge.
 */
@interface A_SCenterLayoutSpec : A_SRelativeLayoutSpec

@property (nonatomic, assign) A_SCenterLayoutSpecCenteringOptions centeringOptions;
@property (nonatomic, assign) A_SCenterLayoutSpecSizingOptions sizingOptions;

/**
 * Initializer.
 *
 * @param centeringOptions How the child is centered.
 * @param sizingOptions How much space will be taken up.
 * @param child The child to center.
 */
+ (instancetype)centerLayoutSpecWithCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
                                       sizingOptions:(A_SCenterLayoutSpecSizingOptions)sizingOptions
                                               child:(id<A_SLayoutElement>)child A_S_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
