//
//  A_SDataController.h
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

#pragma once

#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SBlockTypes.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SEventLog.h>
#ifdef __cplusplus
#import <vector>
#endif

NS_ASSUME_NONNULL_BEGIN

#if A_SEVENTLOG_ENABLE
#define A_SDataControllerLogEvent(dataController, ...) [dataController.eventLog logEventWithBacktrace:(A_S_SAVE_EVENT_BACKTRACES ? [NSThread callStackSymbols] : nil) format:__VA_ARGS__]
#else
#define A_SDataControllerLogEvent(dataController, ...)
#endif

@class A_SCellNode;
@class A_SCollectionElement;
@class A_SCollectionLayoutContext;
@class A_SCollectionLayoutState;
@class A_SDataController;
@class A_SElementMap;
@class A_SLayout;
@class _A_SHierarchyChangeSet;
@protocol A_SRangeManagingNode;
@protocol A_STraitEnvironment;
@protocol A_SSectionContext;

typedef NSUInteger A_SDataControllerAnimationOptions;

extern NSString * const A_SDataControllerRowNodeKind;
extern NSString * const A_SCollectionInvalidUpdateException;

/**
 Data source for data controller
 It will be invoked in the same thread as the api call of A_SDataController.
 */

@protocol A_SDataControllerSource <NSObject>

/**
 Fetch the A_SCellNode block for specific index path. This block should return the A_SCellNode for the specified index path.
 */
- (A_SCellNodeBlock)dataController:(A_SDataController *)dataController nodeBlockAtIndexPath:(NSIndexPath *)indexPath;

/**
 Fetch the number of rows in specific section.
 */
- (NSUInteger)dataController:(A_SDataController *)dataController rowsInSection:(NSUInteger)section;

/**
 Fetch the number of sections.
 */
- (NSUInteger)numberOfSectionsInDataController:(A_SDataController *)dataController;

/**
 Returns if the collection element size matches a given size.
 @precondition The element is present in the data controller's visible map.
 */
- (BOOL)dataController:(A_SDataController *)dataController presentedSizeForElement:(A_SCollectionElement *)element matchesSize:(CGSize)size;

- (nullable id)dataController:(A_SDataController *)dataController nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

/**
 The constrained size range for layout. Called only if collection layout delegate is not provided.
 */
- (A_SSizeRange)dataController:(A_SDataController *)dataController constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray<NSString *> *)dataController:(A_SDataController *)dataController supplementaryNodeKindsInSections:(NSIndexSet *)sections;

- (NSUInteger)dataController:(A_SDataController *)dataController supplementaryNodesOfKind:(NSString *)kind inSection:(NSUInteger)section;

- (A_SCellNodeBlock)dataController:(A_SDataController *)dataController supplementaryNodeBlockOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 The constrained size range for layout. Called only if no data controller layout delegate is provided.
 */
- (A_SSizeRange)dataController:(A_SDataController *)dataController constrainedSizeForSupplementaryNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

- (nullable id<A_SSectionContext>)dataController:(A_SDataController *)dataController contextForSection:(NSInteger)section;

@end

/**
 Delegate for notify the data updating of data controller.
 These methods will be invoked from main thread right now, but it may be moved to background thread in the future.
 */
@protocol A_SDataControllerDelegate <NSObject>

/**
 * Called for change set updates.
 *
 * @param changeSet The change set that includes all updates
 *
 * @param updates The block that performs relevant data updates.
 *
 * @discussion The updates block must always be executed or the data controller will get into a bad state.
 * It should be called at the time the backing view is ready to process the updates,
 * i.e inside the updates block of `-[UICollectionView performBatchUpdates:completion:] or after calling `-[UITableView beginUpdates]`.
 */
- (void)dataController:(A_SDataController *)dataController updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet updates:(dispatch_block_t)updates;

@end

@protocol A_SDataControllerLayoutDelegate <NSObject>

/**
 * @abstract Returns a layout context needed for a coming layout pass with the given elements.
 * The context should contain the elements and any additional information needed.
 *
 * @discussion This method will be called on main thread.
 */
- (A_SCollectionLayoutContext *)layoutContextWithElements:(A_SElementMap *)elements;

/**
 * @abstract Prepares and returns a new layout for given context.
 *
 * @param context A context that was previously returned by `-layoutContextWithElements:`.
 *
 * @return The new layout calculated for the given context.
 *
 * @discussion This method is called ahead of time, i.e before the underlying collection/table view is aware of the provided elements.
 * As a result, clients must solely rely on the given context and should not reach out to other objects for information not available in the context.
 *
 * This method will be called on background theads. It must be thread-safe and should not change any internal state of the conforming object.
 * It must block the calling thread but can dispatch to other theads to reduce total blocking time.
 */
+ (A_SCollectionLayoutState *)calculateLayoutWithContext:(A_SCollectionLayoutContext *)context;

@end

/**
 * Controller to layout data in background, and managed data updating.
 *
 * All operations are asynchronous and thread safe. You can call it from background thread (it is recommendated) and the data
 * will be updated asynchronously. The dataSource must be updated to reflect the changes before these methods has been called.
 * For each data updating, the corresponding methods in delegate will be called.
 */
@interface A_SDataController : NSObject

- (instancetype)initWithDataSource:(id<A_SDataControllerSource>)dataSource node:(nullable id<A_SRangeManagingNode>)node eventLog:(nullable A_SEventLog *)eventLog NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * The node that owns this data controller, if any.
 *
 * NOTE: Soon we will drop support for using A_STableView/A_SCollectionView without the node, so this will be non-null.
 */
@property (nonatomic, nullable, weak, readonly) id<A_SRangeManagingNode> node;

/**
 * The map that is currently displayed. The "UIKit index space."
 *
 * This property will only be changed on the main thread.
 */
@property (atomic, copy, readonly) A_SElementMap *visibleMap;

/**
 * The latest map fetched from the data source. May be more recent than @c visibleMap.
 *
 * This property will only be changed on the main thread.
 */
@property (atomic, copy, readonly) A_SElementMap *pendingMap;

/**
 Data source for fetching data info.
 */
@property (nonatomic, weak, readonly) id<A_SDataControllerSource> dataSource;

/**
 An object that will be included in the backtrace of any update validation exceptions that occur.
 */
@property (nonatomic, weak) id validationErrorSource;

/**
 Delegate to notify when data is updated.
 */
@property (nonatomic, weak) id<A_SDataControllerDelegate> delegate;

/**
 * Delegate for preparing layouts. Main thead only.
 */
@property (nonatomic, weak) id<A_SDataControllerLayoutDelegate> layoutDelegate;

#ifdef __cplusplus
/**
 * Returns the most recently gathered item counts from the data source. If the counts
 * have been invalidated, this synchronously queries the data source and saves the result.
 *
 * This must be called on the main thread.
 */
- (std::vector<NSInteger>)itemCountsFromDataSource;
#endif

/**
 * Returns YES if reloadData has been called at least once. Before this point it is
 * important to ignore/suppress some operations. For example, inserting a section
 * before the initial data load should have no effect.
 *
 * This must be called on the main thread.
 */
@property (nonatomic, readonly) BOOL initialReloadDataHasBeenCalled;

#if A_SEVENTLOG_ENABLE
/*
 * @abstract The primitive event tracing object. You shouldn't directly use it to log event. Use the A_SDataControllerLogEvent macro instead.
 */
@property (nonatomic, strong, readonly) A_SEventLog *eventLog;
#endif

/**
 * @see A_SCollectionNode+Beta.h for full documentation.
 */
@property (nonatomic, assign) BOOL usesSynchronousDataLoading;

/** @name Data Updating */

- (void)updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet;

/**
 * Re-measures all loaded nodes in the backing store.
 * 
 * @discussion Used to respond to a change in size of the containing view
 * (e.g. A_STableView or A_SCollectionView after an orientation change).
 *
 * The invalidationBlock is called after flushing the A_SMainSerialQueue, which ensures that any in-progress
 * layout calculations have been applied. The block will not be called if data hasn't been loaded.
 */
- (void)relayoutAllNodesWithInvalidationBlock:(nullable void (^)())invalidationBlock;

/**
 * Re-measures given nodes in the backing store.
 *
 * @discussion Used to respond to setNeedsLayout calls in A_SCellNode
 */
- (void)relayoutNodes:(id<NSFastEnumeration>)nodes nodesSizeChanged:(NSMutableArray * _Nonnull)nodesSizesChanged;

/**
 * See A_SCollectionNode.h for full documentation of these methods.
 */
@property (nonatomic, readonly) BOOL isProcessingUpdates;
- (void)onDidFinishProcessingUpdates:(nullable void (^)(void))completion;
- (void)waitUntilAllUpdatesAreProcessed;

/**
 * Notifies the data controller object that its environment has changed. The object will request its environment delegate for new information
 * and propagate the information to all visible elements, including ones that are being prepared in background.
 *
 * @discussion If called before the initial @c reloadData, this method will do nothing and the trait collection of the initial load will be requested from the environment delegate.
 *
 * @discussion This method can be called on any threads.
 */
- (void)environmentDidChange;

@end

NS_ASSUME_NONNULL_END
