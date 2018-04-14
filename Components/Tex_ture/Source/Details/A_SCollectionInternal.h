//
//  A_SCollectionInternal.h
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

#import <Async_DisplayKit/A_SCollectionView.h>

NS_ASSUME_NONNULL_BEGIN

@protocol A_SCollectionViewLayoutFacilitatorProtocol;
@class A_SCollectionNode;
@class A_SDataController;
@class A_SRangeController;

@interface A_SCollectionView ()
- (instancetype)_initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(nullable id<A_SCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator owningNode:(nullable A_SCollectionNode *)owningNode eventLog:(nullable A_SEventLog *)eventLog;

@property (nonatomic, weak, readwrite) A_SCollectionNode *collectionNode;
@property (nonatomic, strong, readonly) A_SDataController *dataController;
@property (nonatomic, strong, readonly) A_SRangeController *rangeController;

/**
 * The change set that we're currently building, if any.
 */
@property (nonatomic, strong, nullable, readonly) _A_SHierarchyChangeSet *changeSet;

/**
 * @see A_SCollectionNode+Beta.h for full documentation.
 */
@property (nonatomic, assign) BOOL usesSynchronousDataLoading;

/**
 * Attempt to get the view-layer index path for the item with the given index path.
 *
 * @param indexPath The index path of the item.
 * @param wait If the item hasn't reached the view yet, this attempts to wait for updates to commit.
 */
- (nullable NSIndexPath *)convertIndexPathFromCollectionNode:(NSIndexPath *)indexPath waitingIfNeeded:(BOOL)wait;

/**
 * Attempt to get the node index path given the view-layer index path.
 *
 * @param indexPath The index path of the row.
 */
- (nullable NSIndexPath *)convertIndexPathToCollectionNode:(NSIndexPath *)indexPath;

/**
 * Attempt to get the node index paths given the view-layer index paths.
 *
 * @param indexPaths An array of index paths in the view space
 */
- (nullable NSArray<NSIndexPath *> *)convertIndexPathsToCollectionNode:(nullable NSArray<NSIndexPath *> *)indexPaths;

- (void)beginUpdates;

- (void)endUpdatesAnimated:(BOOL)animated completion:(nullable void (^)(BOOL))completion;

@end

NS_ASSUME_NONNULL_END
