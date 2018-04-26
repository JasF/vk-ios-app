//
//  _A_SHierarchyChangeSet.h
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
#import <vector>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <Async_DisplayKit/A_SIntegerMap.h>
#import <Async_DisplayKit/A_SLog.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSUInteger A_SDataControllerAnimationOptions;

typedef NS_ENUM(NSInteger, _A_SHierarchyChangeType) {
  /**
   * A reload change, as submitted by the user. When a change set is
   * completed, these changes are decomposed into delete-insert pairs
   * and combined with the original deletes and inserts of the change.
   */
  _A_SHierarchyChangeTypeReload,
  
  /**
   * A change that was either an original delete, or the first 
   * part of a decomposed reload.
   */
  _A_SHierarchyChangeTypeDelete,
  
  /**
   * A change that was submitted by the user as a delete.
   */
  _A_SHierarchyChangeTypeOriginalDelete,
  
  /**
   * A change that was either an original insert, or the second
   * part of a decomposed reload.
   */
  _A_SHierarchyChangeTypeInsert,
  
  /**
   * A change that was submitted by the user as an insert.
   */
  _A_SHierarchyChangeTypeOriginalInsert
};

/**
 * Returns YES if the given change type is either .Insert or .Delete, NO otherwise.
 * Other change types – .Reload, .OriginalInsert, .OriginalDelete – are
 * intermediary types used while building the change set. All changes will
 * be reduced to either .Insert or .Delete when the change is marked completed.
 */
BOOL A_SHierarchyChangeTypeIsFinal(_A_SHierarchyChangeType changeType);

NSString *NSStringFromA_SHierarchyChangeType(_A_SHierarchyChangeType changeType);

@interface _A_SHierarchySectionChange : NSObject <A_SDescriptionProvider, A_SDebugDescriptionProvider>

// FIXME: Generalize this to `changeMetadata` dict?
@property (nonatomic, readonly) A_SDataControllerAnimationOptions animationOptions;

@property (nonatomic, strong, readonly) NSIndexSet *indexSet;

@property (nonatomic, readonly) _A_SHierarchyChangeType changeType;

/**
 * If this is a .OriginalInsert or .OriginalDelete change, this returns a copied change
 * with type .Insert or .Delete. Calling this on changes of other types is an error.
 */
- (_A_SHierarchySectionChange *)changeByFinalizingType;

@end

@interface _A_SHierarchyItemChange : NSObject <A_SDescriptionProvider, A_SDebugDescriptionProvider>

@property (nonatomic, readonly) A_SDataControllerAnimationOptions animationOptions;

/// Index paths are sorted descending for changeType .Delete, ascending otherwise
@property (nonatomic, strong, readonly) NSArray<NSIndexPath *> *indexPaths;

@property (nonatomic, readonly) _A_SHierarchyChangeType changeType;

+ (NSDictionary<NSNumber *, NSIndexSet *> *)sectionToIndexSetMapFromChanges:(NSArray<_A_SHierarchyItemChange *> *)changes;

/**
 * If this is a .OriginalInsert or .OriginalDelete change, this returns a copied change
 * with type .Insert or .Delete. Calling this on changes of other types is an error.
 */
- (_A_SHierarchyItemChange *)changeByFinalizingType;

@end

@interface _A_SHierarchyChangeSet : NSObject <A_SDescriptionProvider, A_SDebugDescriptionProvider>

/// @precondition The change set must be completed.
@property (nonatomic, strong, readonly) NSIndexSet *deletedSections;

/// @precondition The change set must be completed.
@property (nonatomic, strong, readonly) NSIndexSet *insertedSections;

@property (nonatomic, readonly) BOOL completed;

/// Whether or not changes should be animated.
// TODO: if any update in this chagne set is non-animated, the whole update should be non-animated.
@property (nonatomic, readwrite) BOOL animated;

@property (nonatomic, readonly) BOOL includesReloadData;

/// Indicates whether the change set is empty, that is it includes neither reload data nor per item or section changes.
@property (nonatomic, readonly) BOOL isEmpty;

/// The top-level activity for this update.
@property (nonatomic, OS_ACTIVITY_NULLABLE) os_activity_t rootActivity;

/// The activity for submitting this update i.e. between -beginUpdates and -endUpdates.
@property (nonatomic, OS_ACTIVITY_NULLABLE) os_activity_t submitActivity;

- (instancetype)initWithOldData:(std::vector<NSInteger>)oldItemCounts NS_DESIGNATED_INITIALIZER;

/**
 * Append the given completion handler to the combined @c completionHandler.
 *
 * @discussion Since batch updates can be nested, we have to support multiple
 * completion handlers per update.
 *
 * @precondition The change set must not be completed.
 */
- (void)addCompletionHandler:(nullable void(^)(BOOL finished))completion;

/**
 * Execute the combined completion handler.
 *
 * @warning The completion block is discarded after reading because it may have captured
 *   significant resources that we would like to reclaim as soon as possible.
 */
- (void)executeCompletionHandlerWithFinished:(BOOL)finished;

/**
 * Get the section index after the update for the given section before the update.
 *
 * @precondition The change set must be completed.
 * @return The new section index, or NSNotFound if the given section was deleted.
 */
- (NSUInteger)newSectionForOldSection:(NSUInteger)oldSection;

/**
 * A table that maps old section indexes to new section indexes.
 */
@property (nonatomic, readonly, strong) A_SIntegerMap *sectionMapping;

/**
 * A table that maps new section indexes to old section indexes.
 */
@property (nonatomic, readonly, strong) A_SIntegerMap *reverseSectionMapping;

/**
 * A table that provides the item mapping for the old section. If the section was deleted
 * or is out of bounds, returns the empty table.
 */
- (A_SIntegerMap *)itemMappingInSection:(NSInteger)oldSection;

/**
 * A table that provides the reverse item mapping for the new section. If the section was inserted
 * or is out of bounds, returns the empty table.
 */
- (A_SIntegerMap *)reverseItemMappingInSection:(NSInteger)newSection;

/**
 * Get the old item index path for the given new index path.
 *
 * @precondition The change set must be completed.
 * @return The old index path, or nil if the given item was inserted.
 */
- (nullable NSIndexPath *)oldIndexPathForNewIndexPath:(NSIndexPath *)indexPath;

/**
 * Get the new item index path for the given old index path.
 *
 * @precondition The change set must be completed.
 * @return The new index path, or nil if the given item was deleted.
 */
- (nullable NSIndexPath *)newIndexPathForOldIndexPath:(NSIndexPath *)indexPath;

/// Call this once the change set has been constructed to prevent future modifications to the changeset. Calling this more than once is a programmer error.
/// NOTE: Calling this method will cause the changeset to convert all reloads into delete/insert pairs.
- (void)markCompletedWithNewItemCounts:(std::vector<NSInteger>)newItemCounts;

- (nullable NSArray <_A_SHierarchySectionChange *> *)sectionChangesOfType:(_A_SHierarchyChangeType)changeType;

- (nullable NSArray <_A_SHierarchyItemChange *> *)itemChangesOfType:(_A_SHierarchyChangeType)changeType;

/// Returns all item indexes affected by changes of the given type in the given section.
- (NSIndexSet *)indexesForItemChangesOfType:(_A_SHierarchyChangeType)changeType inSection:(NSUInteger)section;

- (void)reloadData;
- (void)deleteSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)insertSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)reloadSections:(NSIndexSet *)sections animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)insertItems:(NSArray<NSIndexPath *> *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)deleteItems:(NSArray<NSIndexPath *> *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)reloadItems:(NSArray<NSIndexPath *> *)indexPaths animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection animationOptions:(A_SDataControllerAnimationOptions)options;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath animationOptions:(A_SDataControllerAnimationOptions)options;

@end

NS_ASSUME_NONNULL_END
