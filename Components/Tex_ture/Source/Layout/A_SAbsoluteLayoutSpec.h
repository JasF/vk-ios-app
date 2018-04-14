//
//  A_SAbsoluteLayoutSpec.h
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

/** How much space the spec will take up. */
typedef NS_ENUM(NSInteger, A_SAbsoluteLayoutSpecSizing) {
  /** The spec will take up the maximum size possible. */
  A_SAbsoluteLayoutSpecSizingDefault,
  /** Computes a size for the spec that is the union of all childrens' frames. */
  A_SAbsoluteLayoutSpecSizingSizeToFit,
};

NS_ASSUME_NONNULL_BEGIN

/**
 A layout spec that positions children at fixed positions.
 */
@interface A_SAbsoluteLayoutSpec : A_SLayoutSpec

/**
 How much space will the spec taken up
 */
@property (nonatomic, assign) A_SAbsoluteLayoutSpecSizing sizing;

/**
 @param sizing How much space the spec will take up
 @param children Children to be positioned at fixed positions
 */
+ (instancetype)absoluteLayoutSpecWithSizing:(A_SAbsoluteLayoutSpecSizing)sizing children:(NSArray<id<A_SLayoutElement>> *)children A_S_WARN_UNUSED_RESULT;

/**
 @param children Children to be positioned at fixed positions
 */
+ (instancetype)absoluteLayoutSpecWithChildren:(NSArray<id<A_SLayoutElement>> *)children A_S_WARN_UNUSED_RESULT;

@end

NS_ASSUME_NONNULL_END
