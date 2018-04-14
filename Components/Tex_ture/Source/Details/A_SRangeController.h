//
//  A_SRangeController.h
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
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_SAbstractLayoutController.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_SRangeControllerUpdateRangeProtocol+Beta.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#define A_SRangeControllerLoggingEnabled 0

NS_ASSUME_NONNULL_BEGIN

@class _A_SHierarchyChangeSet;
@protocol A_SRangeControllerDataSource;
@protocol A_SRangeControllerDelegate;
@protocol A_SLayoutController;

/**
 * Working range controller.
 *
 * Used internally by A_STableView and A_SCollectionView.  It is paired with A_SDataController.
 * It is designed to support custom scrolling containers as well.  Observes the visible range, maintains
 * "working ranges" to trigger network calls and rendering, and is responsible for driving asynchronous layout of cells.
 * This includes cancelling those asynchronous operations as cells fall outside of the working ranges.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SRangeController : NSObject <A_SDataControllerDelegate>
{
  id<A_SLayoutController>                  _layoutController;
  __weak id<A_SRangeControllerDataSource>  _dataSource;
  __weak id<A_SRangeControllerDelegate>    _delegate;
}

/**
 * Notify the range controller that the visible range has been updated.
 * This is the primary input call that drives updating the working ranges, and triggering their actions.
 * The ranges will be updated in the next turn of the main loop, or when -updateIfNeeded is called.
 *
 * @see [A_SRangeControllerDelegate rangeControllerVisibleNodeIndexPaths:]
 */
- (void)setNeedsUpdate;

/**
 * Update the ranges immediately, if -setNeedsUpdate has been called since the last update.
 * This is useful because the ranges must be updated immediately after a cell is added
 * into a table/collection to satisfy interface state API guarantees.
 */
- (void)updateIfNeeded;

/**
 * Add the sized node for `indexPath` as a subview of `contentView`.
 *
 * @param contentView UIView to add a (sized) node's view to.
 *
 * @param node The cell node to be added.
 */
- (void)configureContentView:(UIView *)contentView forCellNode:(A_SCellNode *)node;

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType;

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType;

// These methods call the corresponding method on each node, visiting each one that
// the range controller has set a non-default interface state on.
- (void)clearContents;
- (void)clearPreloadedData;

/**
 * An object that describes the layout behavior of the ranged component (table view, collection view, etc.)
 *
 * Used primarily for providing the current range of index paths and identifying when the
 * range controller should invalidate its range.
 */
@property (nonatomic, strong) id<A_SLayoutController> layoutController;

/**
 * The underlying data source for the range controller
 */
@property (nonatomic, weak) id<A_SRangeControllerDataSource> dataSource;

/**
 * Delegate for handling range controller events. Must not be nil.
 */
@property (nonatomic, weak) id<A_SRangeControllerDelegate> delegate;

@end


/**
 * Data source for A_SRangeController.
 *
 * Allows the range controller to perform external queries on the range. 
 * Ex. range nodes, visible index paths, and viewport size.
 */
@protocol A_SRangeControllerDataSource <NSObject>

/**
 * @param rangeController Sender.
 *
 * @return an table of elements corresponding to the data currently visible onscreen (i.e., the visible range).
 */
- (nullable NSHashTable<A_SCollectionElement *> *)visibleElementsForRangeController:(A_SRangeController *)rangeController;

/**
 * @param rangeController Sender.
 *
 * @return the current scroll direction of the view using this range controller.
 */
- (A_SScrollDirection)scrollDirectionForRangeController:(A_SRangeController *)rangeController;

/**
 * @param rangeController Sender.
 *
 * @return the A_SInterfaceState of the node that this controller is powering.  This allows nested range controllers
 * to collaborate with one another, as an outer controller may set bits in .interfaceState such as Visible.
 * If this controller is an orthogonally scrolling element, it waits until it is visible to preload outside the viewport.
 */
- (A_SInterfaceState)interfaceStateForRangeController:(A_SRangeController *)rangeController;

- (A_SElementMap *)elementMapForRangeController:(A_SRangeController *)rangeController;

- (NSString *)nameForRangeControllerDataSource;

@end

/**
 * Delegate for A_SRangeController.
 */
@protocol A_SRangeControllerDelegate <NSObject>

/**
 * Called to update with given change set.
 *
 * @param changeSet The change set that includes all updates
 *
 * @param updates The block that performs relevant data updates.
 *
 * @discussion The updates block must always be executed or the data controller will get into a bad state.
 * It should be called at the time the backing view is ready to process the updates,
 * i.e inside the updates block of `-[UICollectionView performBatchUpdates:completion:] or after calling `-[UITableView beginUpdates]`.
 */
- (void)rangeController:(A_SRangeController *)rangeController updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet updates:(dispatch_block_t)updates;

@end

@interface A_SRangeController (A_SRangeControllerUpdateRangeProtocol) <A_SRangeControllerUpdateRangeProtocol>

/**
 * Update the range mode for a range controller to a explicitly set mode until the node that contains the range
 * controller becomes visible again
 *
 * Logic for the automatic range mode:
 * 1. If there are no visible node paths available nothing is to be done and no range update will happen
 * 2. The initial range update if the range controller is visible always will be
 *    A_SLayoutRangeModeMinimum as it's the initial fetch
 * 3. The range mode set explicitly via updateCurrentRangeWithMode: will last at least one range update. After that it
 the range controller will use the explicit set range mode until it becomes visible and a new range update was
 triggered or a new range mode via updateCurrentRangeWithMode: is set
 * 4. If range mode is not explicitly set the range mode is variying based if the range controller is visible or not
 */
- (void)updateCurrentRangeWithMode:(A_SLayoutRangeMode)rangeMode;

@end

@interface A_SRangeController (DebugInternal)

+ (void)layoutDebugOverlayIfNeeded;

- (void)addRangeControllerToRangeDebugOverlay;

- (void)updateRangeController:(A_SRangeController *)controller
     withScrollableDirections:(A_SScrollDirection)scrollableDirections
              scrollDirection:(A_SScrollDirection)direction
                    rangeMode:(A_SLayoutRangeMode)mode
      displayTuningParameters:(A_SRangeTuningParameters)displayTuningParameters
      preloadTuningParameters:(A_SRangeTuningParameters)preloadTuningParameters
               interfaceState:(A_SInterfaceState)interfaceState;

@end

NS_ASSUME_NONNULL_END