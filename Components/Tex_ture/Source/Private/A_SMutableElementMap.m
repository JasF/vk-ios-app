//
//  A_SMutableElementMap.m
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

#import "A_SMutableElementMap.h"

#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_STwoDimensionalArrayUtils.h>
#import <Async_DisplayKit/NSIndexSet+A_SHelpers.h>

typedef NSMutableArray<NSMutableArray<A_SCollectionElement *> *> A_SMutableCollectionElementTwoDimensionalArray;

typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSIndexPath *, A_SCollectionElement *> *> A_SMutableSupplementaryElementDictionary;

@implementation A_SMutableElementMap {
  A_SMutableSupplementaryElementDictionary *_supplementaryElements;
  NSMutableArray<A_SSection *> *_sections;
  A_SMutableCollectionElementTwoDimensionalArray *_sectionsOfItems;
}

- (instancetype)initWithSections:(NSArray<A_SSection *> *)sections items:(A_SCollectionElementTwoDimensionalArray *)items supplementaryElements:(A_SSupplementaryElementDictionary *)supplementaryElements
{
  if (self = [super init]) {
    _sections = [sections mutableCopy];
    _sectionsOfItems = (id)A_STwoDimensionalArrayDeepMutableCopy(items);
    _supplementaryElements = [A_SMutableElementMap deepMutableCopyOfElementsDictionary:supplementaryElements];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  return [[A_SElementMap alloc] initWithSections:_sections items:_sectionsOfItems supplementaryElements:_supplementaryElements];
}

- (void)removeAllSections
{
  [_sections removeAllObjects];
}

- (void)insertSection:(A_SSection *)section atIndex:(NSInteger)index
{
  [_sections insertObject:section atIndex:index];
}

- (void)removeItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
  A_SDeleteElementsInTwoDimensionalArrayAtIndexPaths(_sectionsOfItems, indexPaths);
}

- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes
{
  [_sections removeObjectsAtIndexes:indexes];
}

- (void)removeAllElements
{
  [_sectionsOfItems removeAllObjects];
  [_supplementaryElements removeAllObjects];
}

- (void)removeSectionsOfItems:(NSIndexSet *)itemSections
{
  [_sectionsOfItems removeObjectsAtIndexes:itemSections];
}

- (void)insertEmptySectionsOfItemsAtIndexes:(NSIndexSet *)sections
{
  [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
    [_sectionsOfItems insertObject:[NSMutableArray array] atIndex:idx];
  }];
}

- (void)insertElement:(A_SCollectionElement *)element atIndexPath:(NSIndexPath *)indexPath
{
  NSString *kind = element.supplementaryElementKind;
  if (kind == nil) {
    [_sectionsOfItems[indexPath.section] insertObject:element atIndex:indexPath.item];
  } else {
    NSMutableDictionary *supplementariesForKind = _supplementaryElements[kind];
    if (supplementariesForKind == nil) {
      supplementariesForKind = [NSMutableDictionary dictionary];
      _supplementaryElements[kind] = supplementariesForKind;
    }
    supplementariesForKind[indexPath] = element;
  }
}

- (void)migrateSupplementaryElementsWithSectionMapping:(A_SIntegerMap *)mapping
{
  // Fast-path, no section changes.
  if (mapping == A_SIntegerMap.identityMap) {
    return;
  }

  // For each element kind,
  [_supplementaryElements enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableDictionary<NSIndexPath *,A_SCollectionElement *> * _Nonnull supps, BOOL * _Nonnull stop) {
    
    // For each index path of that kind, move entries into a new dictionary.
    // Note: it's tempting to update the dictionary in-place but because of the likely collision between old and new index paths,
    // subtle bugs are possible. Note that this process is rare (only on section-level updates),
    // that this work is done off-main, and that the typical supplementary element use case is just 1-per-section (header).
    NSMutableDictionary *newSupps = [NSMutableDictionary dictionary];
    [supps enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull oldIndexPath, A_SCollectionElement * _Nonnull obj, BOOL * _Nonnull stop) {
      NSInteger oldSection = oldIndexPath.section;
      NSInteger newSection = [mapping integerForKey:oldSection];
      
      if (oldSection == newSection) {
        // Index path stayed the same, just copy it over.
        newSupps[oldIndexPath] = obj;
      } else if (newSection != NSNotFound) {
        // Section index changed, move it.
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForItem:oldIndexPath.item inSection:newSection];
        newSupps[newIndexPath] = obj;
      }
    }];
    [supps setDictionary:newSupps];
  }];
}

#pragma mark - Helpers

+ (A_SMutableSupplementaryElementDictionary *)deepMutableCopyOfElementsDictionary:(A_SSupplementaryElementDictionary *)originalDict
{
  NSMutableDictionary *deepCopy = [NSMutableDictionary dictionaryWithCapacity:originalDict.count];
  [originalDict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSDictionary<NSIndexPath *,A_SCollectionElement *> * _Nonnull obj, BOOL * _Nonnull stop) {
    deepCopy[key] = [obj mutableCopy];
  }];
  
  return deepCopy;
}

@end
