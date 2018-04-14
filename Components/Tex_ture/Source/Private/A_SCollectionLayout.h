//
//  A_SCollectionLayout.h
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
#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

@protocol A_SCollectionLayoutDelegate;
@class A_SElementMap, A_SCollectionLayout, A_SCollectionNode;

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED
@interface A_SCollectionLayout : UICollectionViewLayout

/**
 * The collection node object currently using this layout object.
 *
 * @discussion The collection node object sets the value of this property when a new layout object is assigned to it.
 *
 * @discussion To get the truth on the current state of the collection, call methods on the collection node or the data source rather than the collection view because:
 *  1. The view might not yet be allocated.
 *  2. The collection node and data source are thread-safe.
 */
@property (nonatomic, weak) A_SCollectionNode *collectionNode;

@property (nonatomic, strong, readonly) id<A_SCollectionLayoutDelegate> layoutDelegate;

/**
 * Initializes with a layout delegate.
 *
 * @discussion For developers' convenience, the delegate is retained by this layout object, similar to UICollectionView retains its UICollectionViewLayout object.
 *
 * @discussion For simplicity, the delegate is read-only. If a new layout delegate is needed, construct a new layout object with that delegate and notify A_SCollectionView about it.
 * This ensures the underlying UICollectionView purges its cache and properly loads the new layout.
 */
- (instancetype)initWithLayoutDelegate:(id<A_SCollectionLayoutDelegate>)layoutDelegate NS_DESIGNATED_INITIALIZER;

- (instancetype)init __unavailable;

- (instancetype)initWithCoder:(NSCoder *)aDecoder __unavailable;

@end

NS_ASSUME_NONNULL_END