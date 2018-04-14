//
//  _A_SAsyncTransactionContainer.m
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

#import <Async_DisplayKit/_A_SAsyncTransactionContainer.h>
#import <Async_DisplayKit/_A_SAsyncTransactionContainer+Private.h>

#import <Async_DisplayKit/_A_SAsyncTransaction.h>
#import <Async_DisplayKit/_A_SAsyncTransactionGroup.h>
#import <objc/runtime.h>

static const char *A_SDisplayNodeAssociatedTransactionsKey = "A_SAssociatedTransactions";
static const char *A_SDisplayNodeAssociatedCurrentTransactionKey = "A_SAssociatedCurrentTransaction";

@implementation CALayer (A_SAsyncTransactionContainerTransactions)

- (NSHashTable *)asyncdisplaykit_asyncLayerTransactions
{
  return objc_getAssociatedObject(self, A_SDisplayNodeAssociatedTransactionsKey);
}

- (void)asyncdisplaykit_setAsyncLayerTransactions:(NSHashTable *)transactions
{
  objc_setAssociatedObject(self, A_SDisplayNodeAssociatedTransactionsKey, transactions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// No-ops in the base class. Mostly exposed for testing.
- (void)asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:(_A_SAsyncTransaction *)transaction {}
- (void)asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:(_A_SAsyncTransaction *)transaction {}
@end

static const char *A_SAsyncTransactionIsContainerKey = "A_STransactionIsContainer";

@implementation CALayer (A_SAsyncTransactionContainer)

- (_A_SAsyncTransaction *)asyncdisplaykit_currentAsyncTransaction
{
  return objc_getAssociatedObject(self, A_SDisplayNodeAssociatedCurrentTransactionKey);
}

- (void)asyncdisplaykit_setCurrentAsyncTransaction:(_A_SAsyncTransaction *)transaction
{
  objc_setAssociatedObject(self, A_SDisplayNodeAssociatedCurrentTransactionKey, transaction, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
  CFBooleanRef isContainerBool = (__bridge CFBooleanRef)objc_getAssociatedObject(self, A_SAsyncTransactionIsContainerKey);
  BOOL isContainer = (isContainerBool == kCFBooleanTrue);
  return isContainer;
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)isContainer
{
  objc_setAssociatedObject(self, A_SAsyncTransactionIsContainerKey, (id)(isContainer ? kCFBooleanTrue : kCFBooleanFalse), OBJC_ASSOCIATION_ASSIGN);
}

- (A_SAsyncTransactionContainerState)asyncdisplaykit_asyncTransactionContainerState
{
  return ([self.asyncdisplaykit_asyncLayerTransactions count] == 0) ? A_SAsyncTransactionContainerStateNoTransactions : A_SAsyncTransactionContainerStatePendingTransactions;
}

- (void)asyncdisplaykit_cancelAsyncTransactions
{
  // If there was an open transaction, commit and clear the current transaction. Otherwise:
  // (1) The run loop observer will try to commit a canceled transaction which is not allowed
  // (2) We leave the canceled transaction attached to the layer, dooming future operations
  _A_SAsyncTransaction *currentTransaction = self.asyncdisplaykit_currentAsyncTransaction;
  [currentTransaction commit];
  self.asyncdisplaykit_currentAsyncTransaction = nil;

  for (_A_SAsyncTransaction *transaction in [self.asyncdisplaykit_asyncLayerTransactions copy]) {
    [transaction cancel];
  }
}

- (_A_SAsyncTransaction *)asyncdisplaykit_asyncTransaction
{
  _A_SAsyncTransaction *transaction = self.asyncdisplaykit_currentAsyncTransaction;
  if (transaction == nil) {
    NSHashTable *transactions = self.asyncdisplaykit_asyncLayerTransactions;
    if (transactions == nil) {
      transactions = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
      self.asyncdisplaykit_asyncLayerTransactions = transactions;
    }
    __weak CALayer *weakSelf = self;
    transaction = [[_A_SAsyncTransaction alloc] initWithCompletionBlock:^(_A_SAsyncTransaction *completedTransaction, BOOL cancelled) {
      __strong CALayer *self = weakSelf;
      if (self == nil) {
        return;
      }
      [transactions removeObject:completedTransaction];
      [self asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:completedTransaction];
    }];
    [transactions addObject:transaction];
    self.asyncdisplaykit_currentAsyncTransaction = transaction;
    [self asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:transaction];
  }
  [[_A_SAsyncTransactionGroup mainTransactionGroup] addTransactionContainer:self];
  return transaction;
}

- (CALayer *)asyncdisplaykit_parentTransactionContainer
{
  CALayer *containerLayer = self;
  while (containerLayer && !containerLayer.asyncdisplaykit_isAsyncTransactionContainer) {
    containerLayer = containerLayer.superlayer;
  }
  return containerLayer;
}

@end

@implementation UIView (A_SAsyncTransactionContainer)

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
  return self.layer.asyncdisplaykit_isAsyncTransactionContainer;
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  self.layer.asyncdisplaykit_asyncTransactionContainer = asyncTransactionContainer;
}

- (A_SAsyncTransactionContainerState)asyncdisplaykit_asyncTransactionContainerState
{
  return self.layer.asyncdisplaykit_asyncTransactionContainerState;
}

- (void)asyncdisplaykit_cancelAsyncTransactions
{
  [self.layer asyncdisplaykit_cancelAsyncTransactions];
}

- (void)asyncdisplaykit_asyncTransactionContainerStateDidChange
{
  // No-op in the base class.
}

- (void)asyncdisplaykit_setCurrentAsyncTransaction:(_A_SAsyncTransaction *)transaction
{
  self.layer.asyncdisplaykit_currentAsyncTransaction = transaction;
}

- (_A_SAsyncTransaction *)asyncdisplaykit_currentAsyncTransaction
{
  return self.layer.asyncdisplaykit_currentAsyncTransaction;
}

@end
