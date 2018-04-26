//
//  A_SCollectionLayoutCache.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

@class A_SCollectionLayoutContext, A_SCollectionLayoutState;

/// A thread-safe cache for A_SCollectionLayoutContext-A_SCollectionLayoutState pairs
A_S_SUBCLASSING_RESTRICTED
@interface A_SCollectionLayoutCache : NSObject

- (nullable A_SCollectionLayoutState *)layoutForContext:(A_SCollectionLayoutContext *)context;

- (void)setLayout:(A_SCollectionLayoutState *)layout forContext:(A_SCollectionLayoutContext *)context;

- (void)removeLayoutForContext:(A_SCollectionLayoutContext *)context;

- (void)removeAllLayouts;

@end

NS_ASSUME_NONNULL_END
