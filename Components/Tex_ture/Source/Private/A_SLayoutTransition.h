//
//  A_SLayoutTransition.h
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

#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/_A_STransitionContext.h>
#import <Async_DisplayKit/A_SDisplayNodeLayout.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>

#import <memory>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - A_SLayoutElementTransition

/**
 * Objects conform to this project returns if it's possible to layout asynchronous
 */
@protocol A_SLayoutElementTransition <NSObject>

/**
 * @abstract Returns if the layoutElement can be used to layout in an asynchronous way on a background thread.
 */
@property (nonatomic, assign, readonly) BOOL canLayoutAsynchronous;

@end

@interface A_SDisplayNode () <A_SLayoutElementTransition>
@end
@interface A_SLayoutSpec () <A_SLayoutElementTransition>
@end


#pragma mark - A_SLayoutTransition

A_S_SUBCLASSING_RESTRICTED
@interface A_SLayoutTransition : NSObject <_A_STransitionContextLayoutDelegate>

/**
 * Node to apply layout transition on
 */
@property (nonatomic, readonly, weak) A_SDisplayNode *node;

/**
 * Previous layout to transition from
 */
@property (nonatomic, readonly, assign) std::shared_ptr<A_SDisplayNodeLayout> previousLayout;

/**
 * Pending layout to transition to
 */
@property (nonatomic, readonly, assign) std::shared_ptr<A_SDisplayNodeLayout> pendingLayout;

/**
 * Returns if the layout transition needs to happen synchronously
 */
@property (nonatomic, readonly, assign) BOOL isSynchronous;

/**
 * Returns a newly initialized layout transition
 */
- (instancetype)initWithNode:(A_SDisplayNode *)node
               pendingLayout:(std::shared_ptr<A_SDisplayNodeLayout>)pendingLayout
              previousLayout:(std::shared_ptr<A_SDisplayNodeLayout>)previousLayout NS_DESIGNATED_INITIALIZER;

/**
 * Insert and remove subnodes that were added or removed between the previousLayout and the pendingLayout
 */
- (void)commitTransition;

/**
 * Insert all new subnodes that were added between the previous layout and the pending layout
 */
- (void)applySubnodeInsertions;

/**
 * Remove all subnodes that are removed between the previous layout and the pending layout
 */
- (void)applySubnodeRemovals;

@end

@interface A_SLayoutTransition (Unavailable)

- (instancetype)init __unavailable;

@end

NS_ASSUME_NONNULL_END
