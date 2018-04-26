//
//  A_SViewController.h
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
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SVisibilityProtocols.h>

@class A_STraitCollection;

NS_ASSUME_NONNULL_BEGIN

typedef A_STraitCollection * _Nonnull (^A_SDisplayTraitsForTraitCollectionBlock)(UITraitCollection *traitCollection);
typedef A_STraitCollection * _Nonnull (^A_SDisplayTraitsForTraitWindowSizeBlock)(CGSize windowSize);

/**
 * A_SViewController allows you to have a completely node backed hierarchy. It automatically
 * handles @c A_SVisibilityDepth, automatic range mode and propogating @c A_SDisplayTraits to contained nodes.
 *
 * You can opt-out of node backed hierarchy and use it like a normal UIViewController.
 * More importantly, you can use it as a base class for all of your view controllers among which some use a node hierarchy and some don't.
 * See examples/A_SDKgram project for actual implementation.
 */
@interface A_SViewController<__covariant DisplayNodeType : A_SDisplayNode *> : UIViewController <A_SVisibilityDepth>

/**
 * A_SViewController initializer.
 *
 * @param node An A_SDisplayNode which will provide the root view (self.view)
 * @return An A_SViewController instance whose root view will be backed by the provided A_SDisplayNode.
 *
 * @see A_SVisibilityDepth
 */
- (instancetype)initWithNode:(DisplayNodeType)node;

NS_ASSUME_NONNULL_END

/**
 * @return node Returns the A_SDisplayNode which provides the backing view to the view controller.
 */
@property (nonatomic, strong, readonly, null_unspecified) DisplayNodeType node;

NS_ASSUME_NONNULL_BEGIN

/**
 * Set this block to customize the A_SDisplayTraits returned when the VC transitions to the given traitCollection.
 */
@property (nonatomic, copy) A_SDisplayTraitsForTraitCollectionBlock overrideDisplayTraitsWithTraitCollection;

/**
 * Set this block to customize the A_SDisplayTraits returned when the VC transitions to the given window size.
 */
@property (nonatomic, copy) A_SDisplayTraitsForTraitWindowSizeBlock overrideDisplayTraitsWithWindowSize;

/**
 * @abstract Passthrough property to the the .interfaceState of the node.
 * @return The current A_SInterfaceState of the node, indicating whether it is visible and other situational properties.
 * @see A_SInterfaceState
 */
@property (nonatomic, readonly) A_SInterfaceState interfaceState;


// Async_DisplayKit 2.0 BETA: This property is still being tested, but it allows
// blocking as a view controller becomes visible to ensure no placeholders flash onscreen.
// Refer to examples/SynchronousConcurrency, AsyncViewController.m
@property (nonatomic, assign) BOOL neverShowPlaceholders;

@end

@interface A_SViewController (A_SRangeControllerUpdateRangeProtocol)

/**
 * Automatically adjust range mode based on view events. If you set this to YES, the view controller or its node
 * must conform to the A_SRangeControllerUpdateRangeProtocol. 
 *
 * Default value is YES *if* node or view controller conform to A_SRangeControllerUpdateRangeProtocol otherwise it is NO.
 */
@property (nonatomic, assign) BOOL automaticallyAdjustRangeModeBasedOnViewEvents;

@end

NS_ASSUME_NONNULL_END
