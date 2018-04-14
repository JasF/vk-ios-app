//
//  A_SElementMap.h
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

NS_ASSUME_NONNULL_BEGIN

@class A_SCollectionElement, A_SSection, UICollectionViewLayoutAttributes;
@protocol A_SSectionContext;

/**
 * An immutable representation of the state of a collection view's data.
 * All items and supplementary elements are represented by A_SCollectionElement.
 * Fast enumeration is in terms of A_SCollectionElement.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SElementMap : NSObject <NSCopying, NSFastEnumeration>

/**
 * The number of sections (of items) in this map.
 */
@property (readonly) NSInteger numberOfSections;

/**
 * The kinds of supplementary elements present in this map. O(1)
 */
@property (copy, readonly) NSArray<NSString *> *supplementaryElementKinds;

/**
 * Returns number of items in the given section. O(1)
 */
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

/**
 * Returns the context object for the given section, if any. O(1)
 */
- (nullable id<A_SSectionContext>)contextForSection:(NSInteger)section;

/**
 * All the index paths for all the items in this map. O(N)
 *
 * This property may be removed in the future, since it doesn't account for supplementary nodes.
 */
@property (copy, readonly) NSArray<NSIndexPath *> *itemIndexPaths;

/**
 * All the item elements in this map, in ascending order. O(N)
 */
@property (copy, readonly) NSArray<A_SCollectionElement *> *itemElements;

/**
 * Returns the index path that corresponds to the same element in @c map at the given @c indexPath.
 * O(1) for items, fast O(N) for sections.
 *
 * Note you can pass "section index paths" of length 1 and get a corresponding section index path.
 */
- (nullable NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromMap:(A_SElementMap *)map;

/**
 * Returns the section index into the receiver that corresponds to the same element in @c map at @c sectionIndex. Fast O(N).
 *
 * Returns @c NSNotFound if the section does not exist in the receiver.
 */
- (NSInteger)convertSection:(NSInteger)sectionIndex fromMap:(A_SElementMap *)map;

/**
 * Returns the index path for the given element. O(1)
 */
- (nullable NSIndexPath *)indexPathForElement:(A_SCollectionElement *)element;

/**
 * Returns the index path for the given element, if it represents a cell. O(1)
 */
- (nullable NSIndexPath *)indexPathForElementIfCell:(A_SCollectionElement *)element;

/**
 * Returns the item-element at the given index path. O(1)
 */
- (nullable A_SCollectionElement *)elementForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Returns the element for the supplementary element of the given kind at the given index path. O(1)
 */
- (nullable A_SCollectionElement *)supplementaryElementOfKind:(NSString *)supplementaryElementKind atIndexPath:(NSIndexPath *)indexPath;

/**
 * Returns the element that corresponds to the given layout attributes, if any.
 *
 * NOTE: This method only regards the category, kind, and index path of the attributes object. Elements do not
 * have any concept of size/position.
 */
- (nullable A_SCollectionElement *)elementForLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes;

/**
 * A very terse description e.g. { itemCounts = [ <S0: 1> <S1: 16> ] }
 */
@property (atomic, readonly) NSString *smallDescription;

#pragma mark - Initialization -- Only Useful to A_SDataController


// SectionIndex -> ItemIndex -> Element
typedef NSArray<NSArray<A_SCollectionElement *> *> A_SCollectionElementTwoDimensionalArray;

// ElementKind -> IndexPath -> Element
typedef NSDictionary<NSString *, NSDictionary<NSIndexPath *, A_SCollectionElement *> *> A_SSupplementaryElementDictionary;

/**
 * Create a new element map for this dataset. You probably don't need to use this – A_SDataController is the only one who creates these.
 *
 * @param sections The array of A_SSection objects.
 * @param items A 2D array of A_SCollectionElements, for each item.
 * @param supplementaryElements A dictionary of gathered supplementary elements.
 */
- (instancetype)initWithSections:(NSArray<A_SSection *> *)sections
                           items:(A_SCollectionElementTwoDimensionalArray *)items
           supplementaryElements:(A_SSupplementaryElementDictionary *)supplementaryElements;

@end

NS_ASSUME_NONNULL_END
