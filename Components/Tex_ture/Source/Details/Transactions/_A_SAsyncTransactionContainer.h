//
//  _A_SAsyncTransactionContainer.h
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

#pragma once 

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class _A_SAsyncTransaction;

typedef NS_ENUM(NSUInteger, A_SAsyncTransactionContainerState) {
  /**
   The async container has no outstanding transactions.
   Whatever it is displaying is up-to-date.
   */
  A_SAsyncTransactionContainerStateNoTransactions = 0,
  /**
   The async container has one or more outstanding async transactions.
   Its contents may be out of date or showing a placeholder, depending on the configuration of the contained A_SDisplayLayers.
   */
  A_SAsyncTransactionContainerStatePendingTransactions,
};

@protocol A_SAsyncTransactionContainer

/**
 @summary If YES, the receiver is marked as a container for async transactions, grouping all of the transactions
 in the container hierarchy below the receiver together in a single A_SAsyncTransaction.

 @default NO
 */
@property (nonatomic, assign, getter=asyncdisplaykit_isAsyncTransactionContainer, setter=asyncdisplaykit_setAsyncTransactionContainer:) BOOL asyncdisplaykit_asyncTransactionContainer;

/**
 @summary The current state of the receiver; indicates if it is currently performing asynchronous operations or if all operations have finished/canceled.
 */
@property (nonatomic, readonly, assign) A_SAsyncTransactionContainerState asyncdisplaykit_asyncTransactionContainerState;

/**
 @summary Cancels all async transactions on the receiver.
 */
- (void)asyncdisplaykit_cancelAsyncTransactions;

@property (nonatomic, strong, nullable, setter=asyncdisplaykit_setCurrentAsyncTransaction:) _A_SAsyncTransaction *asyncdisplaykit_currentAsyncTransaction;

@end

@interface CALayer (A_SAsyncTransactionContainer) <A_SAsyncTransactionContainer>
/**
 @summary Returns the current async transaction for this layer. A new transaction is created if one
 did not already exist. This method will always return an open, uncommitted transaction.
 @desc asyncdisplaykit_isAsyncTransactionContainer does not need to be YES for this to return a transaction.
 */
@property (nonatomic, readonly, strong, nullable) _A_SAsyncTransaction *asyncdisplaykit_asyncTransaction;

/**
 @summary Goes up the superlayer chain until it finds the first layer with asyncdisplaykit_isAsyncTransactionContainer=YES (including the receiver) and returns it.
 Returns nil if no parent container is found.
 */
@property (nonatomic, readonly, strong, nullable) CALayer *asyncdisplaykit_parentTransactionContainer;
@end

@interface UIView (A_SAsyncTransactionContainer) <A_SAsyncTransactionContainer>
@end

NS_ASSUME_NONNULL_END
