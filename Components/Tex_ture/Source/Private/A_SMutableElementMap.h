//
//  A_SMutableElementMap.h
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
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SIntegerMap.h>

NS_ASSUME_NONNULL_BEGIN

@class A_SSection, A_SCollectionElement, _A_SHierarchyChangeSet;

/**
 * This mutable version will be removed in the future. It's only here now to keep the diff small
 * as we port data controller to use A_SElementMap.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SMutableElementMap : NSObject <NSCopying>

- (instancetype)init __unavailable;

- (instancetype)initWithSections:(NSArray<A_SSection *> *)sections items:(A_SCollectionElementTwoDimensionalArray *)items supplementaryElements:(A_SSupplementaryElementDictionary *)supplementaryElements;

- (void)insertSection:(A_SSection *)section atIndex:(NSInteger)index;

- (void)removeAllSections;

/// Only modifies the array of A_SSection * objects
- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes;

- (void)removeAllElements;

- (void)removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

- (void)removeSectionsOfItems:(NSIndexSet *)itemSections;

- (void)insertEmptySectionsOfItemsAtIndexes:(NSIndexSet *)sections;

- (void)insertElement:(A_SCollectionElement *)element atIndexPath:(NSIndexPath *)indexPath;

/**
 * Update the index paths for all supplementary elements to account for section-level
 * deletes, moves, inserts. This must be called before adding new supplementary elements.
 *
 * This also deletes any supplementary elements in deleted sections.
 */
- (void)migrateSupplementaryElementsWithSectionMapping:(A_SIntegerMap *)mapping;

@end

@interface A_SElementMap (MutableCopying) <NSMutableCopying>
@end

NS_ASSUME_NONNULL_END
