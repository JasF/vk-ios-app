//
//  A_SElementMap.m
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

#import "A_SElementMap.h"
#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_STwoDimensionalArrayUtils.h>
#import <Async_DisplayKit/A_SMutableElementMap.h>
#import <Async_DisplayKit/A_SSection.h>
#import <Async_DisplayKit/NSIndexSet+A_SHelpers.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

@interface A_SElementMap () <A_SDescriptionProvider>

@property (nonatomic, strong, readonly) NSArray<A_SSection *> *sections;

// Element -> IndexPath
@property (nonatomic, strong, readonly) NSMapTable<A_SCollectionElement *, NSIndexPath *> *elementToIndexPathMap;

// The items, in a 2D array
@property (nonatomic, strong, readonly) A_SCollectionElementTwoDimensionalArray *sectionsOfItems;

@property (nonatomic, strong, readonly) A_SSupplementaryElementDictionary *supplementaryElements;

@end

@implementation A_SElementMap

- (instancetype)init
{
  return [self initWithSections:@[] items:@[] supplementaryElements:@{}];
}

- (instancetype)initWithSections:(NSArray<A_SSection *> *)sections items:(A_SCollectionElementTwoDimensionalArray *)items supplementaryElements:(A_SSupplementaryElementDictionary *)supplementaryElements
{
  NSCParameterAssert(items.count == sections.count);

  if (self = [super init]) {
    _sections = [sections copy];
    _sectionsOfItems = [[NSArray alloc] initWithArray:items copyItems:YES];
    _supplementaryElements = [[NSDictionary alloc] initWithDictionary:supplementaryElements copyItems:YES];

    // Setup our index path map
    _elementToIndexPathMap = [NSMapTable mapTableWithKeyOptions:(NSMapTableStrongMemory | NSMapTableObjectPointerPersonality) valueOptions:NSMapTableCopyIn];
    NSInteger s = 0;
    for (NSArray *section in _sectionsOfItems) {
      NSInteger i = 0;
      for (A_SCollectionElement *element in section) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:s];
        [_elementToIndexPathMap setObject:indexPath forKey:element];
        i++;
      }
      s++;
    }
    for (NSDictionary *supplementariesForKind in [_supplementaryElements objectEnumerator]) {
      [supplementariesForKind enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *_Nonnull indexPath, A_SCollectionElement * _Nonnull element, BOOL * _Nonnull stop) {
        [_elementToIndexPathMap setObject:indexPath forKey:element];
      }];
    }
  }
  return self;
}

- (NSArray<NSIndexPath *> *)itemIndexPaths
{
  return A_SIndexPathsForTwoDimensionalArray(_sectionsOfItems);
}

- (NSArray<A_SCollectionElement *> *)itemElements
{
  return A_SElementsInTwoDimensionalArray(_sectionsOfItems);
}

- (NSInteger)numberOfSections
{
  return _sectionsOfItems.count;
}

- (NSArray<NSString *> *)supplementaryElementKinds
{
  return _supplementaryElements.allKeys;
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
  if (![self sectionIndexIsValid:section assert:YES]) {
    return 0;
  }

  return _sectionsOfItems[section].count;
}

- (id<A_SSectionContext>)contextForSection:(NSInteger)section
{
  if (![self sectionIndexIsValid:section assert:NO]) {
    return nil;
  }

  return _sections[section].context;
}

- (nullable NSIndexPath *)indexPathForElement:(A_SCollectionElement *)element
{
  return element ? [_elementToIndexPathMap objectForKey:element] : nil;
}

- (nullable NSIndexPath *)indexPathForElementIfCell:(A_SCollectionElement *)element
{
  if (element.supplementaryElementKind == nil) {
    return [self indexPathForElement:element];
  } else {
    return nil;
  }
}

- (nullable A_SCollectionElement *)elementForItemAtIndexPath:(NSIndexPath *)indexPath
{
  NSInteger section, item;
  if (![self itemIndexPathIsValid:indexPath assert:NO item:&item section:&section]) {
    return nil;
  }

  return _sectionsOfItems[section][item];
}

- (nullable A_SCollectionElement *)supplementaryElementOfKind:(NSString *)supplementaryElementKind atIndexPath:(NSIndexPath *)indexPath
{
  return _supplementaryElements[supplementaryElementKind][indexPath];
}

- (A_SCollectionElement *)elementForLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  switch (layoutAttributes.representedElementCategory) {
    case UICollectionElementCategoryCell:
      // Cell
      return [self elementForItemAtIndexPath:layoutAttributes.indexPath];
    case UICollectionElementCategorySupplementaryView:
      // Supplementary element.
      return [self supplementaryElementOfKind:layoutAttributes.representedElementKind atIndexPath:layoutAttributes.indexPath];
    case UICollectionElementCategoryDecorationView:
      // No support for decoration views.
      return nil;
  }
}

- (NSIndexPath *)convertIndexPath:(NSIndexPath *)indexPath fromMap:(A_SElementMap *)map
{
  if (indexPath.item == NSNotFound) {
    // Section index path
    NSInteger result = [self convertSection:indexPath.section fromMap:map];
    return (result != NSNotFound ? [NSIndexPath indexPathWithIndex:result] : nil);
  } else {
    // Item index path
    A_SCollectionElement *element = [map elementForItemAtIndexPath:indexPath];
    return [self indexPathForElement:element];
  }
}

- (NSInteger)convertSection:(NSInteger)sectionIndex fromMap:(A_SElementMap *)map
{
  if (![map sectionIndexIsValid:sectionIndex assert:YES]) {
    return NSNotFound;
  }

  A_SSection *section = map.sections[sectionIndex];
  return [_sections indexOfObjectIdenticalTo:section];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  return self;
}

// NSMutableCopying conformance is declared in A_SMutableElementMap.h, so that most consumers of A_SElementMap don't bother with it.
#pragma mark - NSMutableCopying

- (id)mutableCopyWithZone:(NSZone *)zone
{
  return [[A_SMutableElementMap alloc] initWithSections:_sections items:_sectionsOfItems supplementaryElements:_supplementaryElements];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len
{
  return [_elementToIndexPathMap countByEnumeratingWithState:state objects:buffer count:len];
}

- (NSString *)smallDescription
{
  NSMutableArray *sectionDescriptions = [NSMutableArray array];

  NSUInteger i = 0;
  for (NSArray *section in _sectionsOfItems) {
    [sectionDescriptions addObject:[NSString stringWithFormat:@"<S%tu: %tu>", i, section.count]];
    i++;
  }
  return A_SObjectDescriptionMakeWithoutObject(@[ @{ @"itemCounts": sectionDescriptions }]);
}

#pragma mark - A_SDescriptionProvider

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray *result = [NSMutableArray array];
  [result addObject:@{ @"items" : _sectionsOfItems }];
  [result addObject:@{ @"supplementaryElements" : _supplementaryElements }];
  return result;
}

#pragma mark - Internal

/**
 * Fails assert + return NO if section is out of bounds.
 */
- (BOOL)sectionIndexIsValid:(NSInteger)section assert:(BOOL)assert
{
  NSInteger sectionCount = _sectionsOfItems.count;
  if (section >= sectionCount || section < 0) {
    if (assert) {
      A_SDisplayNodeFailAssert(@"Invalid section index %zd when there are only %zd sections!", section, sectionCount);
    }
    return NO;
  } else {
    return YES;
  }
}

/**
 * If indexPath is nil, just returns NO.
 * If indexPath is invalid, fails assertion and returns NO.
 * Otherwise returns YES and sets the item & section.
 */
- (BOOL)itemIndexPathIsValid:(NSIndexPath *)indexPath assert:(BOOL)assert item:(out NSInteger *)outItem section:(out NSInteger *)outSection
{
  if (indexPath == nil) {
    return NO;
  }

  NSInteger section = indexPath.section;
  if (![self sectionIndexIsValid:section assert:assert]) {
    return NO;
  }

  NSInteger itemCount = _sectionsOfItems[section].count;
  NSInteger item = indexPath.item;
  if (item >= itemCount || item < 0) {
    if (assert) {
      A_SDisplayNodeFailAssert(@"Invalid item index %zd in section %zd which only has %zd items!", item, section, itemCount);
    }
    return NO;
  }
  *outItem = item;
  *outSection = section;
  return YES;
}

@end
