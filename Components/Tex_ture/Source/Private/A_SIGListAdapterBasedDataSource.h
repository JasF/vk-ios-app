//
//  A_SIGListAdapterBasedDataSource.h
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

#import <Async_DisplayKit/A_SAvailability.h>

#if A_S_IG_LIST_KIT

#import <IGListKit/IGListKit.h>
#import <Async_DisplayKit/A_SCollectionView.h>
#import <Async_DisplayKit/A_SCollectionNode.h>

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED
@interface A_SIGListAdapterBasedDataSource : NSObject <A_SCollectionDataSourceInterop, A_SCollectionDelegateInterop, A_SCollectionDelegateFlowLayout>

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter;

@end

#endif

NS_ASSUME_NONNULL_END
