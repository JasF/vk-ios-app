//
//  A_SCollectionView.h
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

#import <Async_DisplayKit/A_SCollectionViewProtocols.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SBatchContext.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_SScrollDirection.h>

@class A_SCellNode;
@class A_SCollectionNode;
@protocol A_SCollectionDataSource;
@protocol A_SCollectionDelegate;
@protocol A_SCollectionViewLayoutInspecting;
@protocol A_SSectionContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * Asynchronous UICollectionView with Intelligent Preloading capabilities.
 *
 * @note A_SCollectionNode is strongly recommended over A_SCollectionView.  This class exists for adoption convenience.
 */
@interface A_SCollectionView : UICollectionView

/**
 * Returns the corresponding A_SCollectionNode
 *
 * @return collectionNode The corresponding A_SCollectionNode, if one exists.
 */
@property (nonatomic, weak, readonly) A_SCollectionNode *collectionNode;

/**
 * Retrieves the node for the item at the given index path.
 *
 * @param indexPath The index path of the requested node.
 * @return The node at the given index path, or @c nil if no item exists at the specified path.
 */
- (nullable A_SCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath A_S_WARN_UNUSED_RESULT;

/**
 * Similar to -indexPathForCell:.
 *
 * @param cellNode a cellNode in the collection view
 *
 * @return The index path for this cell node.
 *
 * @discussion This index path returned by this method is in the _view's_ index space
 *    and should only be used with @c A_SCollectionView directly. To get an index path suitable
 *    for use with your data source and @c A_SCollectionNode, call @c indexPathForNode: on the
 *    collection node instead.
 */
- (nullable NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode A_S_WARN_UNUSED_RESULT;

/**
 * Similar to -supplementaryViewForElementKind:atIndexPath:
 *
 * @param elementKind The kind of supplementary node to locate.
 * @param indexPath The index path of the requested supplementary node.
 *
 * @return The specified supplementary node or @c nil.
 */
- (nullable A_SCellNode *)supplementaryNodeForElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath A_S_WARN_UNUSED_RESULT;

/**
 * Retrieves the context object for the given section, as provided by the data source in
 * the @c collectionNode:contextForSection: method. This method must be called on the main thread.
 *
 * @param section The section to get the context for.
 *
 * @return The context object, or @c nil if no context was provided.
 */
- (nullable id<A_SSectionContext>)contextForSection:(NSInteger)section A_S_WARN_UNUSED_RESULT;

@end

@interface A_SCollectionView (Deprecated)

/*
 * A Boolean value that determines whether the nodes that the data source renders will be flipped.
 */
@property (nonatomic, assign) BOOL inverted A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * The number of screens left to scroll before the delegate -collectionView:beginBatchFetchingWithContext: is called.
 *
 * Defaults to two screenfuls.
 */
@property (nonatomic, assign) CGFloat leadingScreensForBatching A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * Optional introspection object for the collection view's layout.
 *
 * @discussion Since supplementary and decoration views are controlled by the collection view's layout, this object
 * is used as a bridge to provide information to the internal data controller about the existence of these views and
 * their associated index paths. For collection views using `UICollectionViewFlowLayout`, a default inspector
 * implementation `A_SCollectionViewFlowLayoutInspector` is created and set on this property by default. Custom
 * collection view layout subclasses will need to provide their own implementation of an inspector object for their
 * supplementary views to be compatible with `A_SCollectionView`'s supplementary node support.
 */
@property (nonatomic, weak) id<A_SCollectionViewLayoutInspecting> layoutInspector A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * Determines collection view's current scroll direction. Supports 2-axis collection views.
 *
 * @return a bitmask of A_SScrollDirection values.
 */
@property (nonatomic, readonly) A_SScrollDirection scrollDirection A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * Determines collection view's scrollable directions.
 *
 * @return a bitmask of A_SScrollDirection values.
 */
@property (nonatomic, readonly) A_SScrollDirection scrollableDirections A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * Forces the .contentInset to be UIEdgeInsetsZero.
 *
 * @discussion By default, UIKit sets the top inset to the navigation bar height, even for horizontally
 * scrolling views.  This can only be disabled by setting a property on the containing UIViewController,
 * automaticallyAdjustsScrollViewInsets, which may not be accessible.  A_SPagerNode uses this to ensure
 * its flow layout behaves predictably and does not log undefined layout warnings.
 */
@property (nonatomic) BOOL zeroContentInsets A_SDISPLAYNODE_DEPRECATED_MSG("Set automaticallyAdjustsScrollViewInsets=NO on your view controller instead.");

/**
 * The distance that the content view is inset from the collection view edges. Defaults to UIEdgeInsetsZero.
 */
@property (nonatomic, assign) UIEdgeInsets contentInset A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead");

/**
 * The point at which the origin of the content view is offset from the origin of the collection view.
 */
@property (nonatomic, assign) CGPoint contentOffset A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 * The object that acts as the asynchronous delegate of the collection view
 *
 * @discussion The delegate must adopt the A_SCollectionDelegate protocol. The collection view maintains a weak reference to the delegate object.
 *
 * The delegate object is responsible for providing size constraints for nodes and indicating whether batch fetching should begin.
 */
@property (nonatomic, weak) id<A_SCollectionDelegate> asyncDelegate A_SDISPLAYNODE_DEPRECATED_MSG("Please use A_SCollectionNode's .delegate property instead.");

/**
 * The object that acts as the asynchronous data source of the collection view
 *
 * @discussion The datasource must adopt the A_SCollectionDataSource protocol. The collection view maintains a weak reference to the datasource object.
 *
 * The datasource object is responsible for providing nodes or node creation blocks to the collection view.
 */
@property (nonatomic, weak) id<A_SCollectionDataSource> asyncDataSource A_SDISPLAYNODE_DEPRECATED_MSG("Please use A_SCollectionNode's .dataSource property instead.");

/**
 * Initializes an A_SCollectionView
 *
 * @discussion Initializes and returns a newly allocated collection view object with the specified layout.
 *
 * @param layout The layout object to use for organizing items. The collection view stores a strong reference to the specified object. Must not be nil.
 */
- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout A_SDISPLAYNODE_DEPRECATED_MSG("Please use A_SCollectionNode instead of A_SCollectionView.");

/**
 * Initializes an A_SCollectionView
 *
 * @discussion Initializes and returns a newly allocated collection view object with the specified frame and layout.
 *
 * @param frame The frame rectangle for the collection view, measured in points. The origin of the frame is relative to the superview in which you plan to add it. This frame is passed to the superclass during initialization.
 * @param layout The layout object to use for organizing items. The collection view stores a strong reference to the specified object. Must not be nil.
 */
- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout A_SDISPLAYNODE_DEPRECATED_MSG("Please use A_SCollectionNode instead of A_SCollectionView.");

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
- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Set the tuning parameters for a range type in full mode.
 *
 * @param tuningParameters The tuning parameters to store for a range type.
 * @param rangeType The range type to set the tuning parameters for.
 *
 * @see A_SLayoutRangeMode
 * @see A_SLayoutRangeType
 */
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

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
- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

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
- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

- (nullable __kindof UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

@property (nonatomic, readonly) NSArray<NSIndexPath *> *indexPathsForVisibleItems A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

@property (nonatomic, readonly, nullable) NSArray<NSIndexPath *> *indexPathsForSelectedItems A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode property instead.");

/**
 *  Perform a batch of updates asynchronously, optionally disabling all animations in the batch. This method must be called from the main thread.
 *  The asyncDataSource must be updated to reflect the changes before the update block completes.
 *
 *  @param animated   NO to disable animations for this batch
 *  @param updates    The block that performs the relevant insert, delete, reload, or move operations.
 *  @param completion A completion handler block to execute when all of the operations are finished. This block takes a single
 *                    Boolean parameter that contains the value YES if all of the related animations completed successfully or
 *                    NO if they were interrupted. This parameter may be nil. If supplied, the block is run on the main thread.
 */
- (void)performBatchAnimated:(BOOL)animated updates:(nullable A_S_NOESCAPE void (^)(void))updates completion:(nullable void (^)(BOOL finished))completion A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 *  Perform a batch of updates asynchronously.  This method must be called from the main thread.
 *  The asyncDataSource must be updated to reflect the changes before update block completes.
 *
 *  @param updates    The block that performs the relevant insert, delete, reload, or move operations.
 *  @param completion A completion handler block to execute when all of the operations are finished. This block takes a single
 *                    Boolean parameter that contains the value YES if all of the related animations completed successfully or
 *                    NO if they were interrupted. This parameter may be nil. If supplied, the block is run on the main thread.
 */
- (void)performBatchUpdates:(nullable A_S_NOESCAPE void (^)(void))updates completion:(nullable void (^)(BOOL finished))completion A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @param completion block to run on completion of asynchronous loading or nil. If supplied, the block is run on
 * the main thread.
 * @warning This method is substantially more expensive than UICollectionView's version.
 */
- (void)reloadDataWithCompletion:(nullable void (^)(void))completion A_S_UNAVAILABLE("Use A_SCollectionNode method instead.");

/**
 * Reload everything from scratch, destroying the working range and all cached nodes.
 *
 * @warning This method is substantially more expensive than UICollectionView's version.
 */
- (void)reloadData A_S_UNAVAILABLE("Use A_SCollectionNode method instead.");

/**
 * Triggers a relayout of all nodes.
 *
 * @discussion This method invalidates and lays out every cell node in the collection.
 */
- (void)relayoutItems A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * See A_SCollectionNode.h for full documentation of these methods.
 */
@property (nonatomic, readonly) BOOL isProcessingUpdates;
- (void)onDidFinishProcessingUpdates:(nullable void (^)(void))completion;
- (void)waitUntilAllUpdatesAreCommitted A_SDISPLAYNODE_DEPRECATED_MSG("Use -[A_SCollectionNode waitUntilAllUpdatesAreProcessed] instead.");

/**
 * Registers the given kind of supplementary node for use in creating node-backed supplementary views.
 *
 * @param elementKind The kind of supplementary node that will be requested through the data source.
 *
 * @discussion Use this method to register support for the use of supplementary nodes in place of the default
 * `registerClass:forSupplementaryViewOfKind:withReuseIdentifier:` and `registerNib:forSupplementaryViewOfKind:withReuseIdentifier:`
 * methods. This method will register an internal backing view that will host the contents of the supplementary nodes
 * returned from the data source.
 */
- (void)registerSupplementaryNodeOfKind:(NSString *)elementKind A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Inserts one or more sections.
 *
 * @param sections An index set that specifies the sections to insert.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)insertSections:(NSIndexSet *)sections A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Deletes one or more sections.
 *
 * @param sections An index set that specifies the sections to delete.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)deleteSections:(NSIndexSet *)sections A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Reloads the specified sections.
 *
 * @param sections An index set that specifies the sections to reload.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)reloadSections:(NSIndexSet *)sections A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Moves a section to a new location.
 *
 * @param section The index of the section to move.
 *
 * @param newSection The index that is the destination of the move for the section.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Inserts items at the locations identified by an array of index paths.
 *
 * @param indexPaths An array of NSIndexPath objects, each representing an item index and section index that together identify an item.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)insertItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Deletes the items specified by an array of index paths.
 *
 * @param indexPaths An array of NSIndexPath objects identifying the items to delete.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)deleteItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Reloads the specified items.
 *
 * @param indexPaths An array of NSIndexPath objects identifying the items to reload.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)reloadItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Moves the item at a specified location to a destination location.
 *
 * @param indexPath The index path identifying the item to move.
 *
 * @param newIndexPath The index path that is the destination of the move for the item.
 *
 * @discussion This method must be called from the main thread. The asyncDataSource must be updated to reflect the changes
 * before this method is called.
 */
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

/**
 * Query the sized node at @c indexPath for its calculatedSize.
 *
 * @param indexPath The index path for the node of interest.
 *
 * This method is deprecated. Call @c calculatedSize on the node of interest instead. First deprecated in version 2.0.
 */
- (CGSize)calculatedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath A_SDISPLAYNODE_DEPRECATED_MSG("Call -calculatedSize on the node of interest instead.");

/**
 * Similar to -visibleCells.
 *
 * @return an array containing the nodes being displayed on screen.
 */
- (NSArray<__kindof A_SCellNode *> *)visibleNodes A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated A_SDISPLAYNODE_DEPRECATED_MSG("Use A_SCollectionNode method instead.");

@end

A_SDISPLAYNODE_DEPRECATED_MSG("Renamed to A_SCollectionDataSource.")
@protocol A_SCollectionViewDataSource <A_SCollectionDataSource>
@end

A_SDISPLAYNODE_DEPRECATED_MSG("Renamed to A_SCollectionDelegate.")
@protocol A_SCollectionViewDelegate <A_SCollectionDelegate>
@end

/**
 * Defines methods that let you coordinate a `UICollectionViewFlowLayout` in combination with an `A_SCollectionNode`.
 */
@protocol A_SCollectionDelegateFlowLayout <A_SCollectionDelegate>

@optional

/**
 * Asks the delegate for the inset that should be applied to the given section.
 *
 * @see the same method in UICollectionViewDelegate. 
 */
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;

/**
 * Asks the delegate for the size range that should be used to measure the header in the given flow layout section.
 *
 * @param collectionNode The sender.
 * @param section The section.
 *
 * @return The size range for the header, or @c A_SSizeRangeZero if there is no header in this section.
 *
 * If you want the header to completely determine its own size, return @c A_SSizeRangeUnconstrained.
 *
 * @note Only the scrollable dimension of the returned size range will be used. In a vertical flow,
 * only the height will be used. In a horizontal flow, only the width will be used. The other dimension
 * will be constrained to fill the collection node.
 *
 * @discussion If you do not implement this method, A_SDK will fall back to calling @c collectionView:layout:referenceSizeForHeaderInSection:
 * and using that as the exact constrained size. If you don't implement that method, A_SDK will read the @c headerReferenceSize from the layout.
 */
- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section;

/**
 * Asks the delegate for the size range that should be used to measure the footer in the given flow layout section.
 *
 * @param collectionNode The sender.
 * @param section The section.
 *
 * @return The size range for the footer, or @c A_SSizeRangeZero if there is no footer in this section.
 *
 * If you want the footer to completely determine its own size, return @c A_SSizeRangeUnconstrained.
 *
 * @note Only the scrollable dimension of the returned size range will be used. In a vertical flow,
 * only the height will be used. In a horizontal flow, only the width will be used. The other dimension
 * will be constrained to fill the collection node.
 *
 * @discussion If you do not implement this method, A_SDK will fall back to calling @c collectionView:layout:referenceSizeForFooterInSection:
 * and using that as the exact constrained size. If you don't implement that method, A_SDK will read the @c footerReferenceSize from the layout.
 */
- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section;

/**
 * Asks the delegate for the size of the header in the specified section.
 */
- (CGSize)collectionView:(A_SCollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section A_SDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:sizeRangeForHeaderInSection: instead.");

/**
 * Asks the delegate for the size of the footer in the specified section.
 */
- (CGSize)collectionView:(A_SCollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section A_SDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:sizeRangeForFooterInSection: instead.");

@end

A_SDISPLAYNODE_DEPRECATED_MSG("Renamed to A_SCollectionDelegateFlowLayout.")
@protocol A_SCollectionViewDelegateFlowLayout <A_SCollectionDelegateFlowLayout>
@end

NS_ASSUME_NONNULL_END
