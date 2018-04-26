//
//  A_STextNode+Beta.h
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

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_STextNode.h>

NS_ASSUME_NONNULL_BEGIN

// When enabled, use A_STextNode2 for subclasses, random instances, or all instances of A_STextNode.
// See A_SAvailability.h declaration of A_STEXTNODE_EXPERIMENT_GLOBAL_ENABLE for a compile-time option.
typedef NS_OPTIONS(NSUInteger, A_STextNodeExperimentOptions) {
  // All subclass instances use the experimental implementation.
  A_STextNodeExperimentSubclasses = 1 << 0,
  // Random instances of A_STextNode (50% chance) (not subclasses) use experimental impl.
  // Useful for profiling with apps that have no custom text node subclasses.
  A_STextNodeExperimentRandomInstances = 1 << 1,
  // All instances of A_STextNode itself use experimental implementation. Supersedes `.randomInstances`.
  A_STextNodeExperimentAllInstances = 1 << 2,
  // Add highlighting etc. for debugging.
  A_STextNodeExperimentDebugging = 1 << 3
};

@interface A_STextNode ()

/**
 @abstract An array of descending scale factors that will be applied to this text node to try to make it fit within its constrained size
 @discussion This array should be in descending order and NOT contain the scale factor 1.0. For example, it could return @[@(.9), @(.85), @(.8)];
 @default nil (no scaling)
 */
@property (nullable, nonatomic, copy) NSArray<NSNumber *> *pointSizeScaleFactors;

/**
 @abstract Text margins for text laid out in the text node.
 @discussion defaults to UIEdgeInsetsZero.
 This property can be useful for handling text which does not fit within the view by default. An example: like UILabel,
 A_STextNode will clip the left and right of the string "judar" if it's rendered in an italicised font.
 */
@property (nonatomic, assign) UIEdgeInsets textContainerInset;

/**
 * Opt in to an experimental implementation of text node. The implementation may improve performance and correctness,
 * but may not support all features and has not been thoroughly tested in production.
 *
 * @precondition You may not call this after allocating any text nodes. You may only call this once.
 */
+ (void)setExperimentOptions:(A_STextNodeExperimentOptions)options;

/**
 * Returns YES if this node is using the experimental implementation. NO otherwise. Will not change.
 */
@property (atomic, readonly) BOOL usingExperiment;

@end

NS_ASSUME_NONNULL_END
