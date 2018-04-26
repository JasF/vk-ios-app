//
//  A_SCollectionNode.h
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

#import <UIKit/UICollectionView.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SRangeControllerUpdateRangeProtocol+Beta.h>
#import <Async_DisplayKit/A_SCollectionView.h>
#import <Async_DisplayKit/A_SBlockTypes.h>
#import <Async_DisplayKit/A_SRangeManagingNode.h>

@protocol A_SCollectionViewLayoutFacilitatorProtocol;
@protocol A_SCollectionDelegate;
@protocol A_SCollectionDataSource;
@class A_SCollectionView;

NS_ASSUME_NONNULL_BEGIN

/**
 * A_SCollectionNode is a node based class that wraps an A_SCollectionView. It can be used
 * as a subnode of another node, and provide room for many (great) features and improvements later on.
 */
@interface A_SCollectionNode : A_SDisplayNode <A_SRangeControllerUpdateRangeProtocol, A_SRangeManagingNode>

- (instancetype)init NS_UNAVAILABLE;

/**
 * Initializes an A_SCollectionNode
 *
 * @discussion Initializes and returns a newly allocated collection node object with the specified layout.
 *
 * @param layout The layout object to use for organizing items. The collection view stores a strong reference to the specified object. Must not be nil.
 */
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout;

/**
 * Initializes an A_SCollectionNode
 *
 * @discussion Initializes and returns a newly allocated collection node object with the specified frame and layout.
 *
 * @param frame The frame rectangle for the collection view, measured in points. The origin of the frame is relative to the superview in which you plan to add it. This frame is passed to the superclass during initialization.
 * @param layout The layout object to use for organizing items. The collection view stores a strong reference to the specified object. Must not be nil.
 */
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout;

/**
 * Returns the corresponding A_SCollectionView
 *
 * @return view The corresponding A_SCollectionView.
 */
@property (strong, nonatomic, readonly) A_SCollectionView *view;

/**
 * The object that acts as the asynchronous delegate of the collection view
 *
 * @discussion The delegate must adopt the A_SCollectionDelegate protocol. The collection view maintains a weak reference to the delegate object.
 *
 * The delegate object is responsible for providing size constraints for nodes and indicating whether batch fetching should begin.
 * @note This is a convenience method which sets the asyncDelegate on the collection node's collection view.
 */
@property (weak, nonatomic) id <A_SCollectionDelegate>   delegate;

/**
 * The object that acts as the asynchronous data source of the collection view
 *
 * @discussion The datasource must adopt the A_SCollectionDataSource protocol. The collection view maintains a weak reference to the datasource object.
 *
 * The datasource object is responsible for providing nodes or node creation blocks to the collection view.
 * @note This is a convenience method which sets the asyncDatasource on the collection node's collection view.
 */
@property (weak, nonatomic) id <A_SCollectionDataSource> dataSource;

/**
 * The number of screens left to scroll before the delegate -collectionNode:beginBatchFetchingWithContext: is called.
 *
 * Defaults to two screenfuls.
 */
@property (nonatomic, assign) CGFloat leadingScreensForBatching;

/*
 * A Boolean value that determines whether the collection node will be flipped.
 * If the value of this property is YES, the first cell node will be at the bottom of the collection node (as opposed to the top by default). This is useful for chat/messaging apps. The default value is NO.
 */
@property (nonatomic, assign) BOOL inverted;

/**
 * A Boolean value that indicates whether users can select items in the collection node.
 * If the value of this property is YES (the default), users can select items. If you want more fine-grained control over the selection of items, you must provide a delegate object and implement the appropriate methods of the UICollectionNodeDelegate protocol.
 */
@property (nonatomic, assign) BOOL allowsSelection;

/**
 * A Boolean value that determines whether users can select more than one item in the collection node.
 * This property controls whether multiple items can be selected simultaneously. The default value of this property is NO.
 * When the value of this property is YES, tapping a cell adds it to the current selection (assuming the delegate permits the cell to be selected). Tapping the cell again removes it from the selection.
 */
@property (nonatomic, assign) BOOL allowsMultipleSelection;

/**
 * The layout used to organize the node's items.
 *
 * @discussion Assigning a new layout object to this property causes the new layout to be applied (without animations) to the node’s items.
 */
@property (nonatomic, strong) UICollectionViewLayout *collectionViewLayout;

/**
 * Optional introspection object for the collection node's layout.
 *
 * @discussion Since supplementary and decoration nodes are controlled by the layout, this object
 * is used as a bridge to provide information to the internal data controller about the existence of these views and
 * their associated index paths. For collections using `UICollectionViewFlowLayout`, a default inspector
 * implementation `A_SCollectionViewFlowLayoutInspector` is created and set on this property by default. Custom
 * collection layout subclasses will need to provide their own implementation of an inspector object for their
 * supplementary elements to be compatible with `A_SCollectionNode`'s supplementary node support.
 */
@property (nonatomic, weak) id<A_SCollectionViewLayoutInspecting> layoutInspector;

/**
 * The distance that the content view is inset from the collection node edges. Defaults to UIEdgeInsetsZero.
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 * The offset of the content view's origin from the collection node's origin. Defaults to CGPointZero.
 */
@property (nonatomic, assign) CGPoint contentOffset;

/**
 * Sets the offset from the content node’s origin to the collection node’s origin.
 *
 * @param contentOffset The offset
 *
 * @param animated YES to animate to this new offset at a constant velocity, NO to not aniamte and immediately make the transition.
 */
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated;

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
- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT;

/**
 * Set the tuning parameters for a range type in full mode.
 *
 * @param tuningParameters The tuning parameters to store for a range type.
 * @param rangeType The range type to set the tuning parameters for.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType;

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
- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT;

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
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType;

/**
 * Scrolls the collection to the given item.
 *
 * @param indexPath The index path of the item.
 * @param scrollPosition Where the item should end up after the scroll.
 * @param animated Whether the scroll should be animated or not.
 *
 * This method must be called on the main thread.
 */
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

/**
 * Determines collection node's current scroll direction. Supports 2-axis collection nodes.
 *
 * @return a bitmask of A_SScrollDirection values.
 */
@property (nonatomic, readonly) A_SScrollDirection scrollDirection;

/**
 * Determines collection node's scrollable directions.
 *
 * @return a bitmask of A_SScrollDirection values.
 */
@property (nonatomic, readonly) A_SScrollDirection scrollableDirections;

#pragma mark - Editing

/**
 * Registers the given kind of supplementary node for use in creating node-backed supplementary elements.
 *
 * @param elementKind The kind of supplementary node that will be requested through the data source.
 *
 * @discussion Use this method to register support for the use of supplementary nodes in place of the default
 * `registerClass:forSupplementaryViewOfKind:withReuseIdentifier:` and `registerNib:forSupplementaryViewOfKind:withReuseIdentifier:`
 * methods. This method will register an internal backing view that will host the contents of the supplementary nodes
 * returned from the data source.
 */
- (void)registerSupplementaryNodeOfKind:(NSString *)elementKind;

/**
 *  Perform a batch of updates asynchronously, optionally disabling all animations in the batch. This method must be called from the main thread.
 *  The data source must be updated to reflect the changes before the update block completes.
 *
 *  @param animated   NO to disable animations for this batch
 *  @param updates    The block that performs the relevant insert, delete, reload, or move operations.
 *  @param completion A completion handler block to execute when all of the operations are finished. This block takes a single
 *                    Boolean parameter that contains the value YES if all of the related animations completed successfully or
 *                    NO if they were interrupted. This parameter may be nil. If supplied, the block is run on the main thread.
 */
- (void)performBatchAnimated:(BOOL)animated updates:(nullable A_S_NOESCAPE void (^)(void))updates completion:(nullable void (^)(BOOL finished))completion;

/**
 *  Perform a batch of updates asynchronously, optionally disabling all animations in the batch. This method must be called from the main thread.
 *  The data source must be updated to reflect the changes before the update block completes.
 *
 *  @param updates    The block that performs the relevant insert, delete, reload, or move operations.
 *  @param completion A completion handler block to execute when all of the operations are finished. This block takes a single
 *                    Boolean parameter that contains the value YES if all of the related animations completed successfully or
 *                    NO if they were interrupted. This parameter may be nil. If supplied, the block is run on the main thread.
 */
- (void)performBatchUpdates:(nullable A_S_NOESCAPE void (^)(void))updates completion:(nullable void (^)(BOOL finished))completion;

/**
 *  Returns YES if the A_SCollectionNode is still processing changes from performBatchUpdates:.
 *  This is typically the concurrent allocation (calling nodeBlocks) and layout of newly inserted
 *  A_SCellNodes. If YES is returned, then calling -waitUntilAllUpdatesAreProcessed may take tens of
 *  milliseconds to return as it blocks on these concurrent operations.
 *
 *  Returns NO if A_SCollectionNode is fully synchronized with the underlying UICollectionView. This
 *  means that until the next performBatchUpdates: is called, it is safe to compare UIKit values
 *  (such as from UICollectionViewLayout) with your app's data source.
 *
 *  This method will always return NO if called immediately after -waitUntilAllUpdatesAreProcessed.
 */
@property (nonatomic, readonly) BOOL isProcessingUpdates;

/**
 *  Schedules a block to be performed (on the main thread) after processing of performBatchUpdates:
 *  is finished (completely synchronized to UIKit). The blocks will be run at the moment that
 *  -isProcessingUpdates changes from YES to NO;
 *
 *  When isProcessingUpdates == NO, the block is run block immediately (before the method returns).
 *
 *  Blocks scheduled by this mechanism are NOT guaranteed to run in the order they are scheduled.
 *  They may also be delayed if performBatchUpdates continues to be called; the blocks will wait until
 *  all running updates are finished.
 *
 *  Calling -waitUntilAllUpdatesAreProcessed is one way to flush any pending update completion blocks.
 */
- (void)onDidFinishProcessingUpdates:(nullable void (^)(void))didFinishProcessingUpdates;

/**
 *  Blocks execution of the main thread until all section and item updates are committed to the view. This method must be called from the main thread.
 */
- (void)waitUntilAllUpdatesAreProcessed;

/**
 * Inserts one or more sections.
 *
 * @param sections An index set that specifies the sections to insert.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)insertSections:(NSIndexSet *)sections;

/**
 * Deletes one or more sections.
 *
 * @param sections An index set that specifies the sections to delete.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)deleteSections:(NSIndexSet *)sections;

/**
 * Reloads the specified sections.
 *
 * @param sections An index set that specifies the sections to reload.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)reloadSections:(NSIndexSet *)sections;

/**
 * Moves a section to a new location.
 *
 * @param section The index of the section to move.
 *
 * @param newSection The index that is the destination of the move for the section.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;

/**
 * Inserts items at the locations identified by an array of index paths.
 *
 * @param indexPaths An array of NSIndexPath objects, each representing an item index and section index that together identify an item.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

/**
 * Deletes the items specified by an array of index paths.
 *
 * @param indexPaths An array of NSIndexPath objects identifying the items to delete.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

/**
 * Reloads the specified items.
 *
 * @param indexPaths An array of NSIndexPath objects identifying the items to reload.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths;

/**
 * Moves the item at a specified location to a destination location.
 *
 * @param indexPath The index path identifying the item to move.
 *
 * @param newIndexPath The index path that is the destination of the move for the item.
 *
 * @discussion This method must be called from the main thread. The data source must be updated to reflect the changes
 * before this method is called.
 */
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @param completion block to run on completion of asynchronous loading or nil. If supplied, the block is run on
 * the main thread.
 * @warning This method is substantially more expensive than UICollectionView's version.
 */
- (void)reloadDataWithCompletion:(nullable void (^)(void))completion;


/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @warning This method is substantially more expensive than UICollectionView's version.
 */
- (void)reloadData;

/**
 * Triggers a relayout of all nodes.
 *
 * @discussion This method invalidates and lays out every cell node in the collection view.
 */
- (void)relayoutItems;

#pragma mark - Selection

/**
 * The index paths of the selected items, or @c nil if no items are selected.
 */
@property (nonatomic, readonly, nullable) NSArray<NSIndexPath *> *indexPathsForSelectedItems;

/**
 * Selects the item at the specified index path and optionally scrolls it into view.
 * If the `allowsSelection` property is NO, calling this method has no effect. If there is an existing selection with a different index path and the `allowsMultipleSelection` property is NO, calling this method replaces the previous selection.
 * This method does not cause any selection-related delegate methods to be called.
 *
 * @param indexPath The index path of the item to select. Specifying nil for this parameter clears the current selection.
 *
 * @param animated Specify YES to animate the change in the selection or NO to make the change without animating it.
 *
 * @param scrollPosition An option that specifies where the item should be positioned when scrolling finishes. For a list of possible values, see `UICollectionViewScrollPosition`.
 *
 * @discussion This method must be called from the main thread.
 */
- (void)selectItemAtIndexPath:(nullable NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition;

/**
 * Deselects the item at the specified index.
 * If the allowsSelection property is NO, calling this method has no effect.
 * This method does not cause any selection-related delegate methods to be called.
 *
 * @param indexPath The index path of the item to select. Specifying nil for this parameter clears the current selection.
 *
 * @param animated Specify YES to animate the change in the selection or NO to make the change without animating it.
 *
 * @discussion This method must be called from the main thread.
 */
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

#pragma mark - Querying Data

/**
 * Retrieves the number of items in the given section.
 *
 * @param section The section.
 *
 * @return The number of items.
 */
- (NSInteger)numberOfItemsInSection:(NSInteger)section A_S_WARN_UNUSED_RESULT;

/**
 * The number of sections.
 */
@property (nonatomic, readonly) NSInteger numberOfSections;

/**
 * Similar to -visibleCells.
 *
 * @return an array containing the nodes being displayed on screen. This must be called on the main thread.
 */
@property (nonatomic, readonly) NSArray<__kindof A_SCellNode *> *visibleNodes;

/**
 * Retrieves the node for the item at the given index path.
 *
 * @param indexPath The index path of the requested item.
 *
 * @return The node for the given item, or @c nil if no item exists at the specified path.
 */
- (nullable __kindof A_SCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath A_S_WARN_UNUSED_RESULT;

/**
 * Retrieves the node-model for the item at the given index path, if any.
 *
 * @param indexPath The index path of the requested item.
 *
 * @return The node-model for the given item, or @c nil if no item exists at the specified path or no node-model was provided.
 *
 * @warning This API is beta and subject to change. We'll try to provide an easy migration path.
 */
- (nullable id)nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath A_S_WARN_UNUSED_RESULT;

/**
 * Retrieve the index path for the item with the given node.
 *
 * @param cellNode A node for an item in the collection node.
 *
 * @return The indexPath for this item.
 */
- (nullable NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode A_S_WARN_UNUSED_RESULT;

/**
 * Retrieve the index paths of all visible items.
 *
 * @return an array containing the index paths of all visible items. This must be called on the main thread.
 */
@property (nonatomic, readonly) NSArray<NSIndexPath *> *indexPathsForVisibleItems;

/**
 * Retrieve the index path of the item at the given point.
 *
 * @param point The point of the requested item.
 *
 * @return The indexPath for the item at the given point. This must be called on the main thread.
 */
- (nullable NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point A_S_WARN_UNUSED_RESULT;

/**
 * Retrieve the cell at the given index path.
 *
 * @param indexPath The index path of the requested item.
 *
 * @return The cell for the given index path. This must be called on the main thread.
 */
- (nullable UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Retrieves the context object for the given section, as provided by the data source in
 * the @c collectionNode:contextForSection: method.
 *
 * @param section The section to get the context for.
 *
 * @return The context object, or @c nil if no context was provided.
 *
 * TODO: This method currently accepts @c section in the _view_ index space, but it should
 *   be in the node index space. To get the context in the view index space (e.g. for subclasses
 *   of @c UICollectionViewLayout, the user will call the same method on @c A_SCollectionView.
 */
- (nullable id<A_SSectionContext>)contextForSection:(NSInteger)section A_S_WARN_UNUSED_RESULT;

@end

@interface A_SCollectionNode (Deprecated)

- (void)waitUntilAllUpdatesAreCommitted A_SDISPLAYNODE_DEPRECATED_MSG("This method has been renamed to -waitUntilAllUpdatesAreProcessed.");

@end

/**
 * This is a node-based UICollectionViewDataSource.
 */
@protocol A_SCollectionDataSource <A_SCommonCollectionDataSource>

@optional

/**
 * Asks the data source for the number of items in the given section of the collection node.
 *
 * @see @c collectionView:numberOfItemsInSection:
 */
- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section;

/**
 * Asks the data source for the number of sections in the collection node.
 *
 * @see @c numberOfSectionsInCollectionView:
 */
- (NSInteger)numberOfSectionsInCollectionNode:(A_SCollectionNode *)collectionNode;

/**
 * --BETA--
 * Asks the data source for a view-model for the item at the given index path.
 *
 * @param collectionNode The sender.
 * @param indexPath The index path of the item.
 *
 * @return An object that contains all the data for this item.
 */
- (nullable id)collectionNode:(A_SCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Similar to -collectionNode:nodeForItemAtIndexPath:
 * This method takes precedence over collectionNode:nodeForItemAtIndexPath: if implemented.
 *
 * @param collectionNode The sender.
 * @param indexPath The index path of the item.
 *
 * @return a block that creates the node for display for this item.
 *   Must be thread-safe (can be called on the main thread or a background
 *   queue) and should not implement reuse (it will be called once per row).
 */
- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Similar to -collectionView:cellForItemAtIndexPath:.
 *
 * @param collectionNode The sender.
 * @param indexPath The index path of the item.
 *
 * @return A node to display for the given item. This will be called on the main thread and should
 *   not implement reuse (it will be called once per item).  Unlike UICollectionView's version,
 *   this method is not called when the item is about to display.
 */
- (A_SCellNode *)collectionNode:(A_SCollectionNode *)collectionNode nodeForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 * Asks the data source to provide a node-block to display for the given supplementary element in the collection view.
 *
 * @param collectionNode The sender.
 * @param kind           The kind of supplementary element.
 * @param indexPath      The index path of the supplementary element.
 */
- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 * Asks the data source to provide a node to display for the given supplementary element in the collection view.
 *
 * @param collectionNode The sender.
 * @param kind           The kind of supplementary element.
 * @param indexPath      The index path of the supplementary element.
 */
- (A_SCellNode *)collectionNode:(A_SCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 * Asks the data source to provide a context object for the given section. This object
 * can later be retrieved by calling @c contextForSection: and is useful when implementing
 * custom @c UICollectionViewLayout subclasses. The context object is ret
 *
 * @param collectionNode The sender.
 * @param section The index of the section to provide context for.
 *
 * @return A context object to assign to the given section, or @c nil.
 */
- (nullable id<A_SSectionContext>)collectionNode:(A_SCollectionNode *)collectionNode contextForSection:(NSInteger)section;

/**
 * Asks the data source to provide an array of supplementary element kinds that exist in a given section.
 *
 * @param collectionNode The sender.
 * @param section The index of the section to provide supplementary kinds for.
 *
 * @return The supplementary element kinds that exist in the given section, if any.
 */
- (NSArray<NSString *> *)collectionNode:(A_SCollectionNode *)collectionNode supplementaryElementKindsInSection:(NSInteger)section;

/**
 * Similar to -collectionView:cellForItemAtIndexPath:.
 *
 * @param collectionView The sender.
 *
 * @param indexPath The index path of the requested node.
 *
 * @return a node for display at this indexpath. This will be called on the main thread and should
 *   not implement reuse (it will be called once per row).  Unlike UICollectionView's version,
 *   this method is not called when the row is about to display.
 */
- (A_SCellNode *)collectionView:(A_SCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Similar to -collectionView:nodeForItemAtIndexPath:
 * This method takes precedence over collectionView:nodeForItemAtIndexPath: if implemented.
 *
 * @param collectionView The sender.
 *
 * @param indexPath The index path of the requested node.
 *
 * @return a block that creates the node for display at this indexpath.
 *   Must be thread-safe (can be called on the main thread or a background
 *   queue) and should not implement reuse (it will be called once per row).
 */
- (A_SCellNodeBlock)collectionView:(A_SCollectionView *)collectionView nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Asks the collection view to provide a supplementary node to display in the collection view.
 *
 * @param collectionView An object representing the collection view requesting this information.
 * @param kind           The kind of supplementary node to provide.
 * @param indexPath      The index path that specifies the location of the new supplementary node.
 */
- (A_SCellNode *)collectionView:(A_SCollectionView *)collectionView nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Indicator to lock the data source for data fetching in async mode.
 * We should not update the data source until the data source has been unlocked. Otherwise, it will incur data inconsistency or exception
 * due to the data access in async mode.
 *
 * @param collectionView The sender.
 * @deprecated The data source is always accessed on the main thread, and this method will not be called.
 */
- (void)collectionViewLockDataSource:(A_SCollectionView *)collectionView A_SDISPLAYNODE_DEPRECATED_MSG("Data source accesses are on the main thread. Method will not be called.");

/**
 * Indicator to unlock the data source for data fetching in async mode.
 * We should not update the data source until the data source has been unlocked. Otherwise, it will incur data inconsistency or exception
 * due to the data access in async mode.
 *
 * @param collectionView The sender.
 * @deprecated The data source is always accessed on the main thread, and this method will not be called.
 */
- (void)collectionViewUnlockDataSource:(A_SCollectionView *)collectionView A_SDISPLAYNODE_DEPRECATED_MSG("Data source accesses are on the main thread. Method will not be called.");

@end

/**
 * This is a node-based UICollectionViewDelegate.
 */
@protocol A_SCollectionDelegate <A_SCommonCollectionDelegate, NSObject>

@optional

/**
 * Provides the constrained size range for measuring the given item.
 *
 * @param collectionNode The sender.
 *
 * @param indexPath The index path of the item.
 *
 * @return A constrained size range for layout for the item at this index path.
 */
- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionNode:(A_SCollectionNode *)collectionNode willDisplayItemWithNode:(A_SCellNode *)node;

- (void)collectionNode:(A_SCollectionNode *)collectionNode didEndDisplayingItemWithNode:(A_SCellNode *)node;

- (void)collectionNode:(A_SCollectionNode *)collectionNode willDisplaySupplementaryElementWithNode:(A_SCellNode *)node NS_AVAILABLE_IOS(8_0);
- (void)collectionNode:(A_SCollectionNode *)collectionNode didEndDisplayingSupplementaryElementWithNode:(A_SCellNode *)node;

- (BOOL)collectionNode:(A_SCollectionNode *)collectionNode shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionNode:(A_SCollectionNode *)collectionNode didHighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionNode:(A_SCollectionNode *)collectionNode didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionNode:(A_SCollectionNode *)collectionNode shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionNode:(A_SCollectionNode *)collectionNode shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionNode:(A_SCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
- (void)collectionNode:(A_SCollectionNode *)collectionNode didDeselectItemAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)collectionNode:(A_SCollectionNode *)collectionNode shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionNode:(A_SCollectionNode *)collectionNode canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath sender:(nullable id)sender;
- (void)collectionNode:(A_SCollectionNode *)collectionNode performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath sender:(nullable id)sender;

/**
 * Receive a message that the collection node is near the end of its data set and more data should be fetched if
 * necessary.
 *
 * @param collectionNode The sender.
 * @param context A context object that must be notified when the batch fetch is completed.
 *
 * @discussion You must eventually call -completeBatchFetching: with an argument of YES in order to receive future
 * notifications to do batch fetches. This method is called on a background queue.
 *
 * A_SCollectionNode currently only supports batch events for tail loads. If you require a head load, consider
 * implementing a UIRefreshControl.
 */
- (void)collectionNode:(A_SCollectionNode *)collectionNode willBeginBatchFetchWithContext:(A_SBatchContext *)context;

/**
 * Tell the collection node if batch fetching should begin.
 *
 * @param collectionNode The sender.
 *
 * @discussion Use this method to conditionally fetch batches. Example use cases are: limiting the total number of
 * objects that can be fetched or no network connection.
 *
 * If not implemented, the collection node assumes that it should notify its asyncDelegate when batch fetching
 * should occur.
 */
- (BOOL)shouldBatchFetchForCollectionNode:(A_SCollectionNode *)collectionNode;

/**
 * Provides the constrained size range for measuring the node at the index path.
 *
 * @param collectionView The sender.
 *
 * @param indexPath The index path of the node.
 *
 * @return A constrained size range for layout the node at this index path.
 */
- (A_SSizeRange)collectionView:(A_SCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's constrainedSizeForItemAtIndexPath: instead. PLEA_SE NOTE the very subtle method name change.");

/**
 * Informs the delegate that the collection view will add the given node
 * at the given index path to the view hierarchy.
 *
 * @param collectionView The sender.
 * @param node The node that will be displayed.
 * @param indexPath The index path of the item that will be displayed.
 *
 * @warning Async_DisplayKit processes collection view edits asynchronously. The index path
 *   passed into this method may not correspond to the same item in your data source
 *   if your data source has been updated since the last edit was processed.
 */
- (void)collectionView:(A_SCollectionView *)collectionView willDisplayNode:(A_SCellNode *)node forItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Informs the delegate that the collection view did remove the provided node from the view hierarchy.
 * This may be caused by the node scrolling out of view, or by deleting the item
 * or its containing section with @c deleteItemsAtIndexPaths: or @c deleteSections: .
 *
 * @param collectionView The sender.
 * @param node The node which was removed from the view hierarchy.
 * @param indexPath The index path at which the node was located before it was removed.
 *
 * @warning Async_DisplayKit processes collection view edits asynchronously. The index path
 *   passed into this method may not correspond to the same item in your data source
 *   if your data source has been updated since the last edit was processed.
 */
- (void)collectionView:(A_SCollectionView *)collectionView didEndDisplayingNode:(A_SCellNode *)node forItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

- (void)collectionView:(A_SCollectionView *)collectionView willBeginBatchFetchWithContext:(A_SBatchContext *)context A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Tell the collectionView if batch fetching should begin.
 *
 * @param collectionView The sender.
 *
 * @discussion Use this method to conditionally fetch batches. Example use cases are: limiting the total number of
 * objects that can be fetched or no network connection.
 *
 * If not implemented, the collectionView assumes that it should notify its asyncDelegate when batch fetching
 * should occur.
 */
- (BOOL)shouldBatchFetchForCollectionView:(A_SCollectionView *)collectionView A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

/**
 * Informs the delegate that the collection view will add the node
 * at the given index path to the view hierarchy.
 *
 * @param collectionView The sender.
 * @param indexPath The index path of the item that will be displayed.
 *
 * @warning Async_DisplayKit processes collection view edits asynchronously. The index path
 *   passed into this method may not correspond to the same item in your data source
 *   if your data source has been updated since the last edit was processed.
 *
 * This method is deprecated. Use @c collectionView:willDisplayNode:forItemAtIndexPath: instead.
 */
- (void)collectionView:(A_SCollectionView *)collectionView willDisplayNodeForItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode's method instead.");

@end

@protocol A_SCollectionDataSourceInterop <A_SCollectionDataSource>

/**
 * This method offers compatibility with synchronous, standard UICollectionViewCell objects.
 * These cells will **not** have the performance benefits of A_SCellNodes (like preloading, async layout, and
 * async drawing) - even when mixed within the same A_SCollectionNode.
 *
 * In order to use this method, you must:
 * 1. Implement it on your A_SCollectionDataSource object.
 * 2. Call registerCellClass: on the collectionNode.view (in viewDidLoad, or register an onDidLoad: block).
 * 3. Return nil from the nodeBlockForItem...: or nodeForItem...: method. NOTE: it is an error to return
 *    nil from within a nodeBlock, if you have returned a nodeBlock object.
 * 4. Lastly, you must implement a method to provide the size for the cell. There are two ways this is done:
 * 4a. UICollectionViewFlowLayout (incl. A_SPagerNode). Implement
 collectionNode:constrainedSizeForItemAtIndexPath:.
 * 4b. Custom collection layouts. Set .layoutInspector and have it implement
 collectionView:constrainedSizeForNodeAtIndexPath:.
 *
 * For an example of using this method with all steps above (including a custom layout, 4b.),
 * see the app in examples/CustomCollectionView and enable kShowUICollectionViewCells = YES.
 */
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

/**
 * Implement this property and return YES if you want your interop data source to be
 * used when dequeuing cells for node-backed items.
 *
 * If NO (the default), the interop data source will only be consulted in cases
 * where no A_SCellNode was provided to Async_DisplayKit.
 *
 * If YES, the interop data source will always be consulted to dequeue cells, and
 * will be expected to return _A_SCollectionViewCells in cases where a node was provided.
 *
 * The default value is NO.
 */
@property (class, nonatomic, readonly) BOOL dequeuesCellsForNodeBackedItems;

@end

@protocol A_SCollectionDelegateInterop <A_SCollectionDelegate>

@optional

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath;

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
