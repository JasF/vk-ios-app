//
//  A_STableView.h
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

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_STableViewProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class A_SCellNode;
@protocol A_STableDataSource;
@protocol A_STableDelegate;
@class A_STableNode;

/**
 * Asynchronous UITableView with Intelligent Preloading capabilities.
 *
 * @note A_STableNode is strongly recommended over A_STableView.  This class is provided for adoption convenience.
 */
@interface A_STableView : UITableView

/// The corresponding table node, or nil if one does not exist.
@property (nonatomic, weak, readonly) A_STableNode *tableNode;

/**
 * Retrieves the node for the row at the given index path.
 */
- (nullable A_SCellNode *)nodeForRowAtIndexPath:(NSIndexPath *)indexPath A_S_WARN_UNUSED_RESULT;

@end

@interface A_STableView (Deprecated)

@property (nonatomic, weak) id<A_STableDelegate>   asyncDelegate A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode's .delegate property instead.");
@property (nonatomic, weak) id<A_STableDataSource> asyncDataSource A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode .dataSource property instead.");

/**
 * Initializer.
 *
 * @param frame A rectangle specifying the initial location and size of the table view in its superview’s coordinates.
 * The frame of the table view changes as table cells are added and deleted.
 *
 * @param style A constant that specifies the style of the table view. See UITableViewStyle for descriptions of valid constants.
 */
- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style A_SDISPLAYNODE_DEPRECATED_MSG("Please use A_STableNode instead of A_STableView.");

/**
 * The number of screens left to scroll before the delegate -tableView:beginBatchFetchingWithContext: is called.
 *
 * Defaults to two screenfuls.
 */
@property (nonatomic, assign) CGFloat leadingScreensForBatching A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

/**
 * The distance that the content view is inset from the table view edges. Defaults to UIEdgeInsetsZero.
 */
@property (nonatomic, assign) UIEdgeInsets contentInset A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead");

/**
 * The offset of the content view's origin from the table node's origin. Defaults to CGPointZero.
 */
@property (nonatomic, assign) CGPoint contentOffset A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

/**
 * YES to automatically adjust the contentOffset when cells are inserted or deleted above
 * visible cells, maintaining the users' visible scroll position.
 *
 * @note This is only applied to non-animated updates. For animated updates, there is no way to
 * synchronize or "cancel out" the appearance of a scroll due to UITableView API limitations.
 *
 * default is NO.
 */
@property (nonatomic) BOOL automaticallyAdjustsContentOffset A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

/*
 * A Boolean value that determines whether the nodes that the data source renders will be flipped.
 */
@property (nonatomic, assign) BOOL inverted A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

@property (nonatomic, readonly, nullable) NSIndexPath *indexPathForSelectedRow  A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

@property (nonatomic, readonly, nullable) NSArray<NSIndexPath *> *indexPathsForSelectedRows A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

@property (nonatomic, readonly, nullable) NSArray<NSIndexPath *> *indexPathsForVisibleRows A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode property instead.");

/**
 * Tuning parameters for a range type in full mode.
 *
 * @param rangeType The range type to get the tuning parameters for.
 *
 * @return A tuning parameter value for the given range type in full mode.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Set the tuning parameters for a range type in full mode.
 *
 * @param tuningParameters The tuning parameters to store for a range type.
 * @param rangeType The range type to set the tuning parameters for.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Tuning parameters for a range type in the specified mode.
 *
 * @param rangeMode The range mode to get the running parameters for.
 * @param rangeType The range type to get the tuning parameters for.
 *
 * @return A tuning parameter value for the given range type in the given mode.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Set the tuning parameters for a range type in the specified mode.
 *
 * @param tuningParameters The tuning parameters to store for a range type.
 * @param rangeMode The range mode to set the running parameters for.
 * @param rangeType The range type to set the tuning parameters for.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (nullable __kindof UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (nullable NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (nullable NSArray<NSIndexPath *> *)indexPathsForRowsInRect:(CGRect)rect A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Similar to -visibleCells.
 *
 * @return an array containing the cell nodes being displayed on screen.
 */
- (NSArray<A_SCellNode *> *)visibleNodes A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Similar to -indexPathForCell:.
 *
 * @param cellNode a cellNode part of the table view
 *
 * @return an indexPath for this cellNode
 */
- (nullable NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @param completion block to run on completion of asynchronous loading or nil. If supplied, the block is run on
 * the main thread.
 * @warning This method is substantially more expensive than UITableView's version.
 */
-(void)reloadDataWithCompletion:(void (^ _Nullable)(void))completion A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @warning This method is substantially more expensive than UITableView's version.
 */
- (void)reloadData A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

/**
 * Triggers a relayout of all nodes.
 *
 * @discussion This method invalidates and lays out every cell node in the table view.
 */
- (void)relayoutItems A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)beginUpdates A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode's -performBatchUpdates:completion: instead.");

- (void)endUpdates A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode's -performBatchUpdates:completion: instead.");

/**
 *  Concludes a series of method calls that insert, delete, select, or reload rows and sections of the table view.
 *  You call this method to bracket a series of method calls that begins with beginUpdates and that consists of operations
 *  to insert, delete, select, and reload rows and sections of the table view. When you call endUpdates, A_STableView begins animating
 *  the operations simultaneously. This method is must be called from the main thread. It's important to remember that the A_STableView will
 *  be processing the updates asynchronously after this call and are not guaranteed to be reflected in the A_STableView until
 *  the completion block is executed.
 *
 *  @param animated   NO to disable all animations.
 *  @param completion A completion handler block to execute when all of the operations are finished. This block takes a single
 *                    Boolean parameter that contains the value YES if all of the related animations completed successfully or
 *                    NO if they were interrupted. This parameter may be nil. If supplied, the block is run on the main thread.
 */
- (void)endUpdatesAnimated:(BOOL)animated completion:(void (^ _Nullable)(BOOL completed))completion A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode's -performBatchUpdates:completion: instead.");

/**
 * See A_STableNode.h for full documentation of these methods.
 */
@property (nonatomic, readonly) BOOL isProcessingUpdates;
- (void)onDidFinishProcessingUpdates:(nullable void (^)(void))completion;
- (void)waitUntilAllUpdatesAreCommitted A_SDISPLAYNODE_DEPRECATED_MSG("Use -[A_STableNode waitUntilAllUpdatesAreProcessed] instead.");

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)insertRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated A_SDISPLAYNODE_DEPRECATED_MSG("Use A_STableNode method instead.");

@end

A_SDISPLAYNODE_DEPRECATED_MSG("Renamed to A_STableDataSource.")
@protocol A_STableViewDataSource <A_STableDataSource>
@end

A_SDISPLAYNODE_DEPRECATED_MSG("Renamed to A_STableDelegate.")
@protocol A_STableViewDelegate <A_STableDelegate>
@end

NS_ASSUME_NONNULL_END
