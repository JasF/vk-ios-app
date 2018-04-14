//
//  _A_SAsyncTransactionContainer+Private.h
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

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

@class _A_SAsyncTransaction;

@interface CALayer (A_SAsyncTransactionContainerTransactions)
@property (nonatomic, strong, nullable, setter=asyncdisplaykit_setAsyncLayerTransactions:) NSHashTable<_A_SAsyncTransaction *> *asyncdisplaykit_asyncLayerTransactions;

- (void)asyncdisplaykit_asyncTransactionContainerWillBeginTransaction:(_A_SAsyncTransaction *)transaction;
- (void)asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:(_A_SAsyncTransaction *)transaction;
@end

NS_ASSUME_NONNULL_END
