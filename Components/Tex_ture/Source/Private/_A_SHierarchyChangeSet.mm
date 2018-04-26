//
//  _A_SHierarchyChangeSet.mm
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

#import <Async_DisplayKit/_A_SHierarchyChangeSet.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/NSIndexSet+A_SHelpers.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <unordered_map>
#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

// If assertions are enabled, throw. Otherwise log.
#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED
  #define A_SFailUpdateValidation(...)\
    NSLog(__VA_ARGS__);\
    [NSException raise:A_SCollectionInvalidUpdateException format:__VA_ARGS__];
#else
  #define A_SFailUpdateValidation(...) NSLog(__VA_ARGS__);
#endif

BOOL A_SHierarchyChangeTypeIsFinal(_A_SHierarchyChangeType changeType) {
    switch (changeType) {
        case _A_SHierarchyChangeTypeInsert:
        case _A_SHierarchyChangeTypeDelete:
            return YES;
        default:
            return NO;
    }
}

NSString *NSStringFromA_SHierarchyChangeType(_A_SHierarchyChangeType changeType)
{
  switch (changeType) {
    case _A_SHierarchyChangeTypeInsert:
      return @"Insert";
    case _A_SHierarchyChangeTypeOriginalInsert:
      return @"OriginalInsert";
    case _A_SHierarchyChangeTypeDelete:
      return @"Delete";
    case _A_SHierarchyChangeTypeOriginalDelete:
      return @"OriginalDelete";
    case _A_SHierarchyChangeTypeReload:
      return @"Reload";
    default:
      return @"(invalid)";
  }
}

@interface _A_SHierarchySectionChange ()
- (instancetype)initWithChangeType:(_A_SHierarchyChangeType)changeType indexSet:(NSIndexSet *)indexSet animationOptions:(A_SDataControllerAnimationOptions)animationOptions;

/**
 On return `changes` is sorted according to the change type with changes coalesced by animationOptions
 Assumes: `changes` all have the same changeType
 */
+ (void)sortAndCoalesceSectionChanges:(NSMutableArray<_A_SHierarchySectionChange *> *)changes;

/// Returns all the indexes from all the `indexSet`s of the given `_A_SHierarchySectionChange` objects.
+ (NSMutableIndexSet *)allIndexesInSectionChanges:(NSArray *)changes;

+ (NSString *)smallDescriptionForSectionChanges:(NSArray<_A_SHierarchySectionChange *> *)changes;
@end

@interface _A_SHierarchyItemChange ()
- (instancetype)initWithChangeType:(_A_SHierarchyChangeType)changeType indexPaths:(NSArray *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)animationOptions presorted:(BOOL)presorted;

/**
 On return `changes` is sorted according to the change type with changes coalesced by animationOptions
 Assumes: `changes` all have the same changeType
 */
+ (void)sortAndCoalesceItemChanges:(NSMutableArray<_A_SHierarchyItemChange *> *)changes ignoringChangesInSections:(NSIndexSet *)sections;

+ (NSString *)smallDescriptionForItemChanges:(NSArray<_A_SHierarchyItemChange *> *)changes;

+ (void)ensureItemChanges:(NSArray<_A_SHierarchyItemChange *> *)changes ofSameType:(_A_SHierarchyChangeType)changeType;
@end

@interface _A_SHierarchyChangeSet ()

// array index is old section index, map goes oldItem -> newItem
@property (nonatomic, strong, readonly) NSMutableArray<A_SIntegerMap *> *itemMappings;

// array index is new section index, map goes newItem -> oldItem
@property (nonatomic, strong, readonly) NSMutableArray<A_SIntegerMap *> *reverseItemMappings;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchyItemChange *> *insertItemChanges;
@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchyItemChange *> *originalInsertItemChanges;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchyItemChange *> *deleteItemChanges;
@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchyItemChange *> *originalDeleteItemChanges;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchyItemChange *> *reloadItemChanges;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchySectionChange *> *insertSectionChanges;
@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchySectionChange *> *originalInsertSectionChanges;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchySectionChange *> *deleteSectionChanges;
@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchySectionChange *> *originalDeleteSectionChanges;

@property (nonatomic, strong, readonly) NSMutableArray<_A_SHierarchySectionChange *> *reloadSectionChanges;

@end

@implementation _A_SHierarchyChangeSet {
  std::vector<NSInteger> _oldItemCounts;
  std::vector<NSInteger> _newItemCounts;
  void (^_completionHandler)(BOOL finished);
}
@synthesize sectionMapping = _sectionMapping;
@synthesize reverseSectionMapping = _reverseSectionMapping;
@synthesize itemMappings = _itemMappings;
@synthesize reverseItemMappings = _reverseItemMappings;

- (instancetype)init
{
  A_SFailUpdateValidation(@"_A_SHierarchyChangeSet: -init is not supported. Call -initWithOldData:");
  return [self initWithOldData:std::vector<NSInteger>()];
}

- (instancetype)initWithOldData:(std::vector<NSInteger>)oldItemCounts
{
  self = [super init];
  if (self) {
    _oldItemCounts = oldItemCounts;
    
    _originalInsertItemChanges = [[NSMutableArray alloc] init];
    _insertItemChanges = [[NSMutableArray alloc] init];
    _originalDeleteItemChanges = [[NSMutableArray alloc] init];
    _deleteItemChanges = [[NSMutableArray alloc] init];
    _reloadItemChanges = [[NSMutableArray alloc] init];
    
    _originalInsertSectionChanges = [[NSMutableArray alloc] init];
    _insertSectionChanges = [[NSMutableArray alloc] init];
    _originalDeleteSectionChanges = [[NSMutableArray alloc] init];
    _deleteSectionChanges = [[NSMutableArray alloc] init];
    _reloadSectionChanges = [[NSMutableArray alloc] init];
  }
  return self;
}

#pragma mark External API

- (BOOL)isEmpty
{
  return (! _includesReloadData) && (! [self _includesPerItemOrSectionChanges]);
}

- (void)addCompletionHandler:(void (^)(BOOL))completion
{
  [self _ensureNotCompleted];
  if (completion == nil) {
    return;
  }

  void (^oldCompletionHandler)(BOOL finished) = _completionHandler;
  _completionHandler = ^(BOOL finished) {
    if (oldCompletionHandler != nil) {
    	oldCompletionHandler(finished);
    }
    completion(finished);
  };
}

- (void)executeCompletionHandlerWithFinished:(BOOL)finished
{
  if (_completionHandler != nil) {
    _completionHandler(finished);
    _completionHandler = nil;
  }
}

- (void)markCompletedWithNewItemCounts:(std::vector<NSInteger>)newItemCounts
{
  NSAssert(!_completed, @"Attempt to mark already-completed changeset as completed.");
  _completed = YES;
  _newItemCounts = newItemCounts;
  [self _sortAndCoalesceChangeArrays];
  [self _validateUpdate];
}

- (NSArray *)sectionChangesOfType:(_A_SHierarchyChangeType)changeType
{
  [self _ensureCompleted];
  switch (changeType) {
    case _A_SHierarchyChangeTypeInsert:
      return _insertSectionChanges;
    case _A_SHierarchyChangeTypeReload:
      return _reloadSectionChanges;
    case _A_SHierarchyChangeTypeDelete:
      return _deleteSectionChanges;
    case _A_SHierarchyChangeTypeOriginalDelete:
      return _originalDeleteSectionChanges;
    case _A_SHierarchyChangeTypeOriginalInsert:
      return _originalInsertSectionChanges;
    default:
      NSAssert(NO, @"Request for section changes with invalid type: %lu", (long)changeType);
      return nil;
  }
}

- (NSArray *)itemChangesOfType:(_A_SHierarchyChangeType)changeType
{
  [self _ensureCompleted];
  switch (changeType) {
    case _A_SHierarchyChangeTypeInsert:
      return _insertItemChanges;
    case _A_SHierarchyChangeTypeReload:
      return _reloadItemChanges;
    case _A_SHierarchyChangeTypeDelete:
      return _deleteItemChanges;
    case _A_SHierarchyChangeTypeOriginalInsert:
      return _originalInsertItemChanges;
    case _A_SHierarchyChangeTypeOriginalDelete:
      return _originalDeleteItemChanges;
    default:
      NSAssert(NO, @"Request for item changes with invalid type: %lu", (long)changeType);
      return nil;
  }
}

- (NSIndexSet *)indexesForItemChangesOfType:(_A_SHierarchyChangeType)changeType inSection:(NSUInteger)section
{
  [self _ensureCompleted];
  NSMutableIndexSet *result = [NSMutableIndexSet indexSet];
  for (_A_SHierarchyItemChange *change in [self itemChangesOfType:changeType]) {
    [result addIndexes:[NSIndexSet as_indexSetFromIndexPaths:change.indexPaths inSection:section]];
  }
  return result;
}

- (NSUInteger)newSectionForOldSection:(NSUInteger)oldSection
{
  return [self.sectionMapping integerForKey:oldSection];
}

- (NSUInteger)oldSectionForNewSection:(NSUInteger)newSection
{
  return [self.reverseSectionMapping integerForKey:newSection];
}

- (A_SIntegerMap *)sectionMapping
{
  A_SDisplayNodeAssertNotNil(_deletedSections, @"Cannot call %s before `markCompleted` returns.", sel_getName(_cmd));
  A_SDisplayNodeAssertNotNil(_insertedSections, @"Cannot call %s before `markCompleted` returns.", sel_getName(_cmd));
  [self _ensureCompleted];
  if (_sectionMapping == nil) {
    _sectionMapping = [A_SIntegerMap mapForUpdateWithOldCount:_oldItemCounts.size() deleted:_deletedSections inserted:_insertedSections];
  }
  return _sectionMapping;
}

- (A_SIntegerMap *)reverseSectionMapping
{
  if (_reverseSectionMapping == nil) {
    _reverseSectionMapping = [self.sectionMapping inverseMap];
  }
  return _reverseSectionMapping;
}

- (NSMutableArray *)itemMappings
{
  [self _ensureCompleted];

  if (_itemMappings == nil) {
    _itemMappings = [NSMutableArray array];
    auto insertMap = [_A_SHierarchyItemChange sectionToIndexSetMapFromChanges:_originalInsertItemChanges];
    auto deleteMap = [_A_SHierarchyItemChange sectionToIndexSetMapFromChanges:_originalDeleteItemChanges];
    NSInteger oldSection = 0;
    for (auto oldCount : _oldItemCounts) {
      NSInteger newSection = [self newSectionForOldSection:oldSection];
      A_SIntegerMap *table;
      if (newSection == NSNotFound) {
        table = A_SIntegerMap.emptyMap;
      } else {
        table = [A_SIntegerMap mapForUpdateWithOldCount:oldCount deleted:deleteMap[@(oldSection)] inserted:insertMap[@(newSection)]];
      }
      _itemMappings[oldSection] = table;
      oldSection++;
    }
  }
  return _itemMappings;
}

- (NSMutableArray *)reverseItemMappings
{
  [self _ensureCompleted];

  if (_reverseItemMappings == nil) {
    _reverseItemMappings = [NSMutableArray array];
    for (NSInteger newSection = 0; newSection < _newItemCounts.size(); newSection++) {
      NSInteger oldSection = [self oldSectionForNewSection:newSection];
      A_SIntegerMap *table;
      if (oldSection == NSNotFound) {
        table = A_SIntegerMap.emptyMap;
      } else {
        table = [[self itemMappingInSection:oldSection] inverseMap];
      }
      _reverseItemMappings[newSection] = table;
    }
  }
  return _reverseItemMappings;
}

- (A_SIntegerMap *)itemMappingInSection:(NSInteger)oldSection
{
  if (self.includesReloadData || oldSection >= _oldItemCounts.size()) {
    return A_SIntegerMap.emptyMap;
  }
  return self.itemMappings[oldSection];
}

- (A_SIntegerMap *)reverseItemMappingInSection:(NSInteger)newSection
{
  if (self.includesReloadData || newSection >= _newItemCounts.size()) {
    return A_SIntegerMap.emptyMap;
  }
  return self.reverseItemMappings[newSection];
}

- (NSIndexPath *)oldIndexPathForNewIndexPath:(NSIndexPath *)indexPath
{
  [self _ensureCompleted];
  NSInteger newSection = indexPath.section;
  NSInteger oldSection = [self oldSectionForNewSection:newSection];
  if (oldSection == NSNotFound) {
    return nil;
  }
  NSInteger oldItem = [[self reverseItemMappingInSection:newSection] integerForKey:indexPath.item];
  if (oldItem == NSNotFound) {
    return nil;
  }
  return [NSIndexPath indexPathForItem:oldItem inSection:oldSection];
}

- (NSIndexPath *)newIndexPathForOldIndexPath:(NSIndexPath *)indexPath
{
  [self _ensureCompleted];
  NSInteger oldSection = indexPath.section;
  NSInteger newSection = [self newSectionForOldSection:oldSection];
  if (newSection == NSNotFound) {
    return nil;
  }
  NSInteger newItem = [[self itemMappingInSection:oldSection] integerForKey:indexPath.item];
  if (newItem == NSNotFound) {
    return nil;
  }
  return [NSIndexPath indexPathForItem:newItem inSection:newSection];
}

- (void)reloadData
{
  [self _ensureNotCompleted];
  NSAssert(_includesReloadData == NO, @"Attempt to reload data multiple times %@", self);
  _includesReloadData = YES;
}

- (void)deleteItems:(NSArray *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchyItemChange *change = [[_A_SHierarchyItemChange alloc] initWithChangeType:_A_SHierarchyChangeTypeOriginalDelete indexPaths:indexPaths animationOptions:options presorted:NO];
  [_originalDeleteItemChanges addObject:change];
}

- (void)deleteSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchySectionChange *change = [[_A_SHierarchySectionChange alloc] initWithChangeType:_A_SHierarchyChangeTypeOriginalDelete indexSet:sections animationOptions:options];
  [_originalDeleteSectionChanges addObject:change];
}

- (void)insertItems:(NSArray *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchyItemChange *change = [[_A_SHierarchyItemChange alloc] initWithChangeType:_A_SHierarchyChangeTypeOriginalInsert indexPaths:indexPaths animationOptions:options presorted:NO];
  [_originalInsertItemChanges addObject:change];
}

- (void)insertSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchySectionChange *change = [[_A_SHierarchySectionChange alloc] initWithChangeType:_A_SHierarchyChangeTypeOriginalInsert indexSet:sections animationOptions:options];
  [_originalInsertSectionChanges addObject:change];
}

- (void)reloadItems:(NSArray *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchyItemChange *change = [[_A_SHierarchyItemChange alloc] initWithChangeType:_A_SHierarchyChangeTypeReload indexPaths:indexPaths animationOptions:options presorted:NO];
  [_reloadItemChanges addObject:change];
}

- (void)reloadSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options
{
  [self _ensureNotCompleted];
  _A_SHierarchySectionChange *change = [[_A_SHierarchySectionChange alloc] initWithChangeType:_A_SHierarchyChangeTypeReload indexSet:sections animationOptions:options];
  [_reloadSectionChanges addObject:change];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath animationOptions:(A_SDataControllerAnimationOptions)options
{
  /**
   * TODO: Proper move implementation.
   */
  [self deleteItems:@[ indexPath ] animationOptions:options];
  [self insertItems:@[ newIndexPath ] animationOptions:options];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection animationOptions:(A_SDataControllerAnimationOptions)options
{
  /**
   * TODO: Proper move implementation.
   */
  [self deleteSections:[NSIndexSet indexSetWithIndex:section] animationOptions:options];
  [self insertSections:[NSIndexSet indexSetWithIndex:newSection] animationOptions:options];
}

#pragma mark Private

- (BOOL)_ensureNotCompleted
{
  NSAssert(!_completed, @"Attempt to modify completed changeset %@", self);
  return !_completed;
}

- (BOOL)_ensureCompleted
{
  NSAssert(_completed, @"Attempt to process incomplete changeset %@", self);
  return _completed;
}

- (void)_sortAndCoalesceChangeArrays
{
  if (_includesReloadData) {
    return;
  }
  
  @autoreleasepool {

    // Split reloaded sections into [delete(oldIndex), insert(newIndex)]
    
    // Give these their "pre-reloads" values. Once we add in the reloads we'll re-process them.
    _deletedSections = [_A_SHierarchySectionChange allIndexesInSectionChanges:_originalDeleteSectionChanges];
    _insertedSections = [_A_SHierarchySectionChange allIndexesInSectionChanges:_originalInsertSectionChanges];
    for (_A_SHierarchySectionChange *originalDeleteSectionChange in _originalDeleteSectionChanges) {
      [_deleteSectionChanges addObject:[originalDeleteSectionChange changeByFinalizingType]];
    }
    for (_A_SHierarchySectionChange *originalInsertSectionChange in _originalInsertSectionChanges) {
      [_insertSectionChanges addObject:[originalInsertSectionChange changeByFinalizingType]];
    }
    
    for (_A_SHierarchySectionChange *change in _reloadSectionChanges) {
      NSIndexSet *newSections = [change.indexSet as_indexesByMapping:^(NSUInteger idx) {
        NSUInteger newSec = [self newSectionForOldSection:idx];
        A_SDisplayNodeAssert(newSec != NSNotFound, @"Request to reload and delete same section %tu", idx);
        return newSec;
      }];
      
      _A_SHierarchySectionChange *deleteChange = [[_A_SHierarchySectionChange alloc] initWithChangeType:_A_SHierarchyChangeTypeDelete indexSet:change.indexSet animationOptions:change.animationOptions];
      [_deleteSectionChanges addObject:deleteChange];
      
      _A_SHierarchySectionChange *insertChange = [[_A_SHierarchySectionChange alloc] initWithChangeType:_A_SHierarchyChangeTypeInsert indexSet:newSections animationOptions:change.animationOptions];
      [_insertSectionChanges addObject:insertChange];
    }
    
    [_A_SHierarchySectionChange sortAndCoalesceSectionChanges:_deleteSectionChanges];
    [_A_SHierarchySectionChange sortAndCoalesceSectionChanges:_insertSectionChanges];
    _deletedSections = [_A_SHierarchySectionChange allIndexesInSectionChanges:_deleteSectionChanges];
    _insertedSections = [_A_SHierarchySectionChange allIndexesInSectionChanges:_insertSectionChanges];

    // Split reloaded items into [delete(oldIndexPath), insert(newIndexPath)]
    for (_A_SHierarchyItemChange *originalDeleteItemChange in _originalDeleteItemChanges) {
      [_deleteItemChanges addObject:[originalDeleteItemChange changeByFinalizingType]];
    }
    for (_A_SHierarchyItemChange *originalInsertItemChange in _originalInsertItemChanges) {
      [_insertItemChanges addObject:[originalInsertItemChange changeByFinalizingType]];
    }
    
    [_A_SHierarchyItemChange ensureItemChanges:_insertItemChanges ofSameType:_A_SHierarchyChangeTypeInsert];
    [_A_SHierarchyItemChange ensureItemChanges:_deleteItemChanges ofSameType:_A_SHierarchyChangeTypeDelete];
    
    for (_A_SHierarchyItemChange *change in _reloadItemChanges) {
      NSAssert(change.changeType == _A_SHierarchyChangeTypeReload, @"It must be a reload change to be in here");

      auto newIndexPaths = A_SArrayByFlatMapping(change.indexPaths, NSIndexPath *indexPath, [self newIndexPathForOldIndexPath:indexPath]);
      
      // All reload changes are translated into deletes and inserts
      // We delete the items that needs reload together with other deleted items, at their original index
      _A_SHierarchyItemChange *deleteItemChangeFromReloadChange = [[_A_SHierarchyItemChange alloc] initWithChangeType:_A_SHierarchyChangeTypeDelete indexPaths:change.indexPaths animationOptions:change.animationOptions presorted:NO];
      [_deleteItemChanges addObject:deleteItemChangeFromReloadChange];
      // We insert the items that needs reload together with other inserted items, at their future index
      _A_SHierarchyItemChange *insertItemChangeFromReloadChange = [[_A_SHierarchyItemChange alloc] initWithChangeType:_A_SHierarchyChangeTypeInsert indexPaths:newIndexPaths animationOptions:change.animationOptions presorted:NO];
      [_insertItemChanges addObject:insertItemChangeFromReloadChange];
    }
    
    // Ignore item deletes in reloaded/deleted sections.
    [_A_SHierarchyItemChange sortAndCoalesceItemChanges:_deleteItemChanges ignoringChangesInSections:_deletedSections];

    // Ignore item inserts in reloaded(new)/inserted sections.
    [_A_SHierarchyItemChange sortAndCoalesceItemChanges:_insertItemChanges ignoringChangesInSections:_insertedSections];
  }
}

- (void)_validateUpdate
{
  // If reloadData exists, ignore other changes
  if (_includesReloadData) {
    if ([self _includesPerItemOrSectionChanges]) {
      NSLog(@"Warning: A reload data shouldn't be used in conjuntion with other updates.");
    }
    return;
  }
  
  NSIndexSet *allReloadedSections = [_A_SHierarchySectionChange allIndexesInSectionChanges:_reloadSectionChanges];
  
  NSInteger newSectionCount = _newItemCounts.size();
  NSInteger oldSectionCount = _oldItemCounts.size();
  
  NSInteger insertedSectionCount = _insertedSections.count;
  NSInteger deletedSectionCount = _deletedSections.count;
  // Assert that the new section count is correct.
  if (newSectionCount != oldSectionCount + insertedSectionCount - deletedSectionCount) {
    A_SFailUpdateValidation(@"Invalid number of sections. The number of sections after the update (%zd) must be equal to the number of sections before the update (%zd) plus or minus the number of sections inserted or deleted (%tu inserted, %tu deleted)", newSectionCount, oldSectionCount, insertedSectionCount, deletedSectionCount);
    return;
  }
  
  // Assert that no invalid deletes/reloads happened.
  NSInteger invalidSectionDelete = NSNotFound;
  if (oldSectionCount == 0) {
    invalidSectionDelete = _deletedSections.firstIndex;
  } else {
    invalidSectionDelete = [_deletedSections indexGreaterThanIndex:oldSectionCount - 1];
  }
  if (invalidSectionDelete != NSNotFound) {
    A_SFailUpdateValidation(@"Attempt to delete section %zd but there are only %zd sections before the update.", invalidSectionDelete, oldSectionCount);
    return;
  }
  
  for (_A_SHierarchyItemChange *change in _deleteItemChanges) {
    for (NSIndexPath *indexPath in change.indexPaths) {
      // Assert that item delete happened in a valid section.
      NSInteger section = indexPath.section;
      NSInteger item = indexPath.item;
      if (section >= oldSectionCount) {
        A_SFailUpdateValidation(@"Attempt to delete item %zd from section %zd, but there are only %zd sections before the update.", item, section, oldSectionCount);
        return;
      }
      
      // Assert that item delete happened to a valid item.
      NSInteger oldItemCount = _oldItemCounts[section];
      if (item >= oldItemCount) {
        A_SFailUpdateValidation(@"Attempt to delete item %zd from section %zd, which only contains %zd items before the update.", item, section, oldItemCount);
        return;
      }
    }
  }
  
  for (_A_SHierarchyItemChange *change in _insertItemChanges) {
    for (NSIndexPath *indexPath in change.indexPaths) {
      NSInteger section = indexPath.section;
      NSInteger item = indexPath.item;
      // Assert that item insert happened in a valid section.
      if (section >= newSectionCount) {
        A_SFailUpdateValidation(@"Attempt to insert item %zd into section %zd, but there are only %zd sections after the update.", item, section, newSectionCount);
        return;
      }
      
      // Assert that item delete happened to a valid item.
      NSInteger newItemCount = _newItemCounts[section];
      if (item >= newItemCount) {
        A_SFailUpdateValidation(@"Attempt to insert item %zd into section %zd, which only contains %zd items after the update.", item, section, newItemCount);
        return;
      }
    }
  }
  
  // Assert that no sections were inserted out of bounds.
  NSInteger invalidSectionInsert = NSNotFound;
  if (newSectionCount == 0) {
    invalidSectionInsert = _insertedSections.firstIndex;
  } else {
    invalidSectionInsert = [_insertedSections indexGreaterThanIndex:newSectionCount - 1];
  }
  if (invalidSectionInsert != NSNotFound) {
    A_SFailUpdateValidation(@"Attempt to insert section %zd but there are only %zd sections after the update.", invalidSectionInsert, newSectionCount);
    return;
  }
  
  for (NSUInteger oldSection = 0; oldSection < oldSectionCount; oldSection++) {
    NSInteger oldItemCount = _oldItemCounts[oldSection];
    // If section was reloaded, ignore.
    if ([allReloadedSections containsIndex:oldSection]) {
      continue;
    }
    
    // If section was deleted, ignore.
    NSUInteger newSection = [self newSectionForOldSection:oldSection];
    if (newSection == NSNotFound) {
      continue;
    }
    
    NSIndexSet *originalInsertedItems = [self indexesForItemChangesOfType:_A_SHierarchyChangeTypeOriginalInsert inSection:newSection];
    NSIndexSet *originalDeletedItems = [self indexesForItemChangesOfType:_A_SHierarchyChangeTypeOriginalDelete inSection:oldSection];
    NSIndexSet *reloadedItems = [self indexesForItemChangesOfType:_A_SHierarchyChangeTypeReload inSection:oldSection];
    
    // Assert that no reloaded items were deleted.
    NSInteger deletedReloadedItem = [originalDeletedItems as_intersectionWithIndexes:reloadedItems].firstIndex;
    if (deletedReloadedItem != NSNotFound) {
      A_SFailUpdateValidation(@"Attempt to delete and reload the same item at index path %@", [NSIndexPath indexPathForItem:deletedReloadedItem inSection:oldSection]);
      return;
    }
    
    // Assert that the new item count is correct.
    NSInteger newItemCount = _newItemCounts[newSection];
    NSInteger insertedItemCount = originalInsertedItems.count;
    NSInteger deletedItemCount = originalDeletedItems.count;
    if (newItemCount != oldItemCount + insertedItemCount - deletedItemCount) {
      A_SFailUpdateValidation(@"Invalid number of items in section %zd. The number of items after the update (%zd) must be equal to the number of items before the update (%zd) plus or minus the number of items inserted or deleted (%zd inserted, %zd deleted).", oldSection, newItemCount, oldItemCount, insertedItemCount, deletedItemCount);
      return;
    }
  }
}

- (BOOL)_includesPerItemOrSectionChanges
{
  return 0 < (_originalDeleteSectionChanges.count + _originalDeleteItemChanges.count
              +_originalInsertSectionChanges.count + _originalInsertItemChanges.count
              + _reloadSectionChanges.count + _reloadItemChanges.count);
}

#pragma mark - Debugging (Private)

- (NSString *)description
{
  return A_SObjectDescriptionMakeWithoutObject([self propertiesForDescription]);
}

- (NSString *)debugDescription
{
  return A_SObjectDescriptionMake(self, [self propertiesForDebugDescription]);
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  if (_includesReloadData) {
    [result addObject:@{ @"reloadData" : @"YES" }];
  }
  if (_reloadSectionChanges.count > 0) {
    [result addObject:@{ @"reloadSections" : [_A_SHierarchySectionChange smallDescriptionForSectionChanges:_reloadSectionChanges] }];
  }
  if (_reloadItemChanges.count > 0) {
    [result addObject:@{ @"reloadItems" : [_A_SHierarchyItemChange smallDescriptionForItemChanges:_reloadItemChanges] }];
  }
  if (_originalDeleteSectionChanges.count > 0) {
    [result addObject:@{ @"deleteSections" : [_A_SHierarchySectionChange smallDescriptionForSectionChanges:_originalDeleteSectionChanges] }];
  }
  if (_originalDeleteItemChanges.count > 0) {
    [result addObject:@{ @"deleteItems" : [_A_SHierarchyItemChange smallDescriptionForItemChanges:_originalDeleteItemChanges] }];
  }
  if (_originalInsertSectionChanges.count > 0) {
    [result addObject:@{ @"insertSections" : [_A_SHierarchySectionChange smallDescriptionForSectionChanges:_originalInsertSectionChanges] }];
  }
  if (_originalInsertItemChanges.count > 0) {
    [result addObject:@{ @"insertItems" : [_A_SHierarchyItemChange smallDescriptionForItemChanges:_originalInsertItemChanges] }];
  }
  return result;
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  return [self propertiesForDescription];
}

@end

@implementation _A_SHierarchySectionChange

- (instancetype)initWithChangeType:(_A_SHierarchyChangeType)changeType indexSet:(NSIndexSet *)indexSet animationOptions:(A_SDataControllerAnimationOptions)animationOptions
{
  self = [super init];
  if (self) {
    A_SDisplayNodeAssert(indexSet.count > 0, @"Request to create _A_SHierarchySectionChange with no sections!");
    _changeType = changeType;
    _indexSet = indexSet;
    _animationOptions = animationOptions;
  }
  return self;
}

- (_A_SHierarchySectionChange *)changeByFinalizingType
{
  _A_SHierarchyChangeType newType;
  switch (_changeType) {
    case _A_SHierarchyChangeTypeOriginalInsert:
      newType = _A_SHierarchyChangeTypeInsert;
      break;
    case _A_SHierarchyChangeTypeOriginalDelete:
      newType = _A_SHierarchyChangeTypeDelete;
      break;
    default:
      A_SFailUpdateValidation(@"Attempt to finalize section change of invalid type %@.", NSStringFromA_SHierarchyChangeType(_changeType));
      return self;
  }
  return [[_A_SHierarchySectionChange alloc] initWithChangeType:newType indexSet:_indexSet animationOptions:_animationOptions];
}

+ (void)sortAndCoalesceSectionChanges:(NSMutableArray<_A_SHierarchySectionChange *> *)changes
{
  _A_SHierarchySectionChange *firstChange = changes.firstObject;
  if (firstChange == nil) {
    return;
  }
  _A_SHierarchyChangeType type = [firstChange changeType];
  
  A_SDisplayNodeAssert(A_SHierarchyChangeTypeIsFinal(type), @"Attempt to sort and coalesce section changes of intermediary type %@. Why?", NSStringFromA_SHierarchyChangeType(type));
    
  // Lookup table [Int: AnimationOptions]
  __block std::unordered_map<NSUInteger, A_SDataControllerAnimationOptions> animationOptions;
  
  // All changed indexes
  NSMutableIndexSet *allIndexes = [NSMutableIndexSet new];
  
  for (_A_SHierarchySectionChange *change in changes) {
    A_SDataControllerAnimationOptions options = change.animationOptions;
    NSIndexSet *indexes = change.indexSet;
    [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
      for (NSUInteger i = range.location; i < NSMaxRange(range); i++) {
        animationOptions[i] = options;
      }
    }];
    [allIndexes addIndexes:indexes];
  }
  
  // Create new changes by grouping sorted changes by animation option
  NSMutableArray *result = [[NSMutableArray alloc] init];
  
  __block A_SDataControllerAnimationOptions currentOptions = 0;
  NSMutableIndexSet *currentIndexes = [NSMutableIndexSet indexSet];

  BOOL reverse = type == _A_SHierarchyChangeTypeDelete || type == _A_SHierarchyChangeTypeOriginalDelete;
  NSEnumerationOptions options = reverse ? NSEnumerationReverse : kNilOptions;

  [allIndexes enumerateRangesWithOptions:options usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    NSInteger increment = reverse ? -1 : 1;
    NSUInteger start = reverse ? NSMaxRange(range) - 1 : range.location;
    NSInteger limit = reverse ? range.location - 1 : NSMaxRange(range);
    for (NSInteger i = start; i != limit; i += increment) {
      A_SDataControllerAnimationOptions options = animationOptions[i];
      
      // End the previous group if needed.
      if (options != currentOptions && currentIndexes.count > 0) {
        _A_SHierarchySectionChange *change = [[_A_SHierarchySectionChange alloc] initWithChangeType:type indexSet:[currentIndexes copy] animationOptions:currentOptions];
        [result addObject:change];
        [currentIndexes removeAllIndexes];
      }
      
      // Start a new group if needed.
      if (currentIndexes.count == 0) {
        currentOptions = options;
      }
      
      [currentIndexes addIndex:i];
    }
  }];

  // Finish up the last group.
  if (currentIndexes.count > 0) {
    _A_SHierarchySectionChange *change = [[_A_SHierarchySectionChange alloc] initWithChangeType:type indexSet:[currentIndexes copy] animationOptions:currentOptions];
    [result addObject:change];
  }

  [changes setArray:result];
}

+ (NSMutableIndexSet *)allIndexesInSectionChanges:(NSArray<_A_SHierarchySectionChange *> *)changes
{
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
  for (_A_SHierarchySectionChange *change in changes) {
    [indexes addIndexes:change.indexSet];
  }
  return indexes;
}

#pragma mark - Debugging (Private)

+ (NSString *)smallDescriptionForSectionChanges:(NSArray<_A_SHierarchySectionChange *> *)changes
{
  NSMutableIndexSet *unionIndexSet = [NSMutableIndexSet indexSet];
  for (_A_SHierarchySectionChange *change in changes) {
    [unionIndexSet addIndexes:change.indexSet];
  }
  return [unionIndexSet as_smallDescription];
}

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSString *)debugDescription
{
  return A_SObjectDescriptionMake(self, [self propertiesForDebugDescription]);
}

- (NSString *)smallDescription
{
  return [self.indexSet as_smallDescription];
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  [result addObject:@{ @"indexes" : [self.indexSet as_smallDescription] }];
  return result;
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  [result addObject:@{ @"anim" : @(_animationOptions) }];
  [result addObject:@{ @"type" : NSStringFromA_SHierarchyChangeType(_changeType) }];
  [result addObject:@{ @"indexes" : self.indexSet }];
  return result;
}

@end

@implementation _A_SHierarchyItemChange

- (instancetype)initWithChangeType:(_A_SHierarchyChangeType)changeType indexPaths:(NSArray *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)animationOptions presorted:(BOOL)presorted
{
  self = [super init];
  if (self) {
    A_SDisplayNodeAssert(indexPaths.count > 0, @"Request to create _A_SHierarchyItemChange with no items!");
    _changeType = changeType;
    if (presorted) {
      _indexPaths = indexPaths;
    } else {
      SEL sorting = changeType == _A_SHierarchyChangeTypeDelete ? @selector(asdk_inverseCompare:) : @selector(compare:);
      _indexPaths = [indexPaths sortedArrayUsingSelector:sorting];
    }
    _animationOptions = animationOptions;
  }
  return self;
}

// Create a mapping out of changes indexPaths to a {@section : [indexSet]} fashion
// e.g. changes: (0 - 0), (0 - 1), (2 - 5)
//  will become: {@0 : [0, 1], @2 : [5]}
+ (NSDictionary *)sectionToIndexSetMapFromChanges:(NSArray<_A_SHierarchyItemChange *> *)changes
{
  NSMutableDictionary *sectionToIndexSetMap = [NSMutableDictionary dictionary];
  for (_A_SHierarchyItemChange *change in changes) {
    for (NSIndexPath *indexPath in change.indexPaths) {
      NSNumber *sectionKey = @(indexPath.section);
      NSMutableIndexSet *indexSet = sectionToIndexSetMap[sectionKey];
      if (indexSet) {
        [indexSet addIndex:indexPath.item];
      } else {
        indexSet = [NSMutableIndexSet indexSetWithIndex:indexPath.item];
        sectionToIndexSetMap[sectionKey] = indexSet;
      }
    }
  }
  return sectionToIndexSetMap;
}

+ (void)ensureItemChanges:(NSArray<_A_SHierarchyItemChange *> *)changes ofSameType:(_A_SHierarchyChangeType)changeType
{
#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED
  for (_A_SHierarchyItemChange *change in changes) {
    NSAssert(change.changeType == changeType, @"The map we created must all be of the same changeType as of now");
  }
#endif
}

- (_A_SHierarchyItemChange *)changeByFinalizingType
{
  _A_SHierarchyChangeType newType;
  switch (_changeType) {
    case _A_SHierarchyChangeTypeOriginalInsert:
      newType = _A_SHierarchyChangeTypeInsert;
      break;
    case _A_SHierarchyChangeTypeOriginalDelete:
      newType = _A_SHierarchyChangeTypeDelete;
      break;
    default:
      A_SFailUpdateValidation(@"Attempt to finalize item change of invalid type %@.", NSStringFromA_SHierarchyChangeType(_changeType));
      return self;
  }
  return [[_A_SHierarchyItemChange alloc] initWithChangeType:newType indexPaths:_indexPaths animationOptions:_animationOptions presorted:YES];
}

+ (void)sortAndCoalesceItemChanges:(NSMutableArray<_A_SHierarchyItemChange *> *)changes ignoringChangesInSections:(NSIndexSet *)ignoredSections
{
  if (changes.count < 1) {
    return;
  }
  
  _A_SHierarchyChangeType type = [changes.firstObject changeType];
  A_SDisplayNodeAssert(A_SHierarchyChangeTypeIsFinal(type), @"Attempt to sort and coalesce item changes of intermediary type %@. Why?", NSStringFromA_SHierarchyChangeType(type));
    
  // Lookup table [NSIndexPath: AnimationOptions]
  NSMutableDictionary *animationOptions = [NSMutableDictionary new];
  
  // All changed index paths, sorted
  NSMutableArray *allIndexPaths = [[NSMutableArray alloc] init];
  
  for (_A_SHierarchyItemChange *change in changes) {
    for (NSIndexPath *indexPath in change.indexPaths) {
      if (![ignoredSections containsIndex:indexPath.section]) {
        animationOptions[indexPath] = @(change.animationOptions);
        [allIndexPaths addObject:indexPath];
      }
    }
  }
  
  SEL sorting = type == _A_SHierarchyChangeTypeDelete ? @selector(asdk_inverseCompare:) : @selector(compare:);
  [allIndexPaths sortUsingSelector:sorting];

  // Create new changes by grouping sorted changes by animation option
  NSMutableArray *result = [[NSMutableArray alloc] init];

  A_SDataControllerAnimationOptions currentOptions = 0;
  NSMutableArray *currentIndexPaths = [NSMutableArray array];

  for (NSIndexPath *indexPath in allIndexPaths) {
    A_SDataControllerAnimationOptions options = [animationOptions[indexPath] integerValue];

    // End the previous group if needed.
    if (options != currentOptions && currentIndexPaths.count > 0) {
      _A_SHierarchyItemChange *change = [[_A_SHierarchyItemChange alloc] initWithChangeType:type indexPaths:[currentIndexPaths copy] animationOptions:currentOptions presorted:YES];
      [result addObject:change];
      [currentIndexPaths removeAllObjects];
    }

    // Start a new group if needed.
    if (currentIndexPaths.count == 0) {
      currentOptions = options;
    }

    [currentIndexPaths addObject:indexPath];
  }

  // Finish up the last group.
  if (currentIndexPaths.count > 0) {
    _A_SHierarchyItemChange *change = [[_A_SHierarchyItemChange alloc] initWithChangeType:type indexPaths:[currentIndexPaths copy] animationOptions:currentOptions presorted:YES];
    [result addObject:change];
  }

  [changes setArray:result];
}

#pragma mark - Debugging (Private)

+ (NSString *)smallDescriptionForItemChanges:(NSArray<_A_SHierarchyItemChange *> *)changes
{
  NSDictionary *map = [self sectionToIndexSetMapFromChanges:changes];
  NSMutableString *str = [NSMutableString stringWithString:@"{ "];
  [map enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull section, NSIndexSet * _Nonnull indexSet, BOOL * _Nonnull stop) {
    [str appendFormat:@"@%lu : %@ ", (long)section.integerValue, [indexSet as_smallDescription]];
  }];
  [str appendString:@"}"];
  return str;
}

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSString *)debugDescription
{
  return A_SObjectDescriptionMake(self, [self propertiesForDebugDescription]);
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  [result addObject:@{ @"indexPaths" : self.indexPaths }];
  return result;
}

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
  [result addObject:@{ @"anim" : @(_animationOptions) }];
  [result addObject:@{ @"type" : NSStringFromA_SHierarchyChangeType(_changeType) }];
  [result addObject:@{ @"indexPaths" : self.indexPaths }];
  return result;
}

@end
