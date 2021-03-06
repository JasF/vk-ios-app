//
//  A_SCollectionView.mm
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

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SBatchFetching.h>
#import <Async_DisplayKit/A_SDelegateProxy.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionInternal.h>
#import <Async_DisplayKit/A_SCollectionLayout.h>
#import <Async_DisplayKit/A_SCollectionNode+Beta.h>
#import <Async_DisplayKit/A_SCollectionViewLayoutController.h>
#import <Async_DisplayKit/A_SCollectionViewLayoutFacilitatorProtocol.h>
#import <Async_DisplayKit/A_SCollectionViewFlowLayoutInspector.h>
#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/UICollectionViewLayout+A_SConvenience.h>
#import <Async_DisplayKit/A_SRangeController.h>
#import <Async_DisplayKit/_A_SCollectionViewCell.h>
#import <Async_DisplayKit/_A_SDisplayLayer.h>
#import <Async_DisplayKit/_A_SCollectionReusableView.h>
#import <Async_DisplayKit/A_SPagerNode.h>
#import <Async_DisplayKit/A_SSectionContext.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/_A_SHierarchyChangeSet.h>
#import <Async_DisplayKit/CoreGraphics+A_SConvenience.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SThread.h>

/**
 * A macro to get self.collectionNode and assign it to a local variable, or return
 * the given value if nil.
 *
 * Previously we would set A_SCollectionNode's dataSource & delegate to nil
 * during dealloc. However, our asyncDelegate & asyncDataSource must be set on the
 * main thread, so if the node is deallocated off-main, we won't learn about the change
 * until later on. Since our @c collectionNode parameter to delegate methods (e.g.
 * collectionNode:didEndDisplayingItemWithNode:) is nonnull, it's important that we never
 * unintentionally pass nil (this will crash in Swift, in production). So we can use
 * this macro to ensure that our node is still alive before calling out to the user
 * on its behalf.
 */
#define GET_COLLECTIONNODE_OR_RETURN(__var, __val) \
  A_SCollectionNode *__var = self.collectionNode; \
  if (__var == nil) { \
    return __val; \
  }

#define A_SFlowLayoutDefault(layout, property, default)                                        \
({                                                                                            \
  UICollectionViewFlowLayout *flowLayout = A_SDynamicCast(layout, UICollectionViewFlowLayout); \
  flowLayout ? flowLayout.property : default;                                                 \
})

/// What, if any, invalidation should we perform during the next -layoutSubviews.
typedef NS_ENUM(NSUInteger, A_SCollectionViewInvalidationStyle) {
  /// Perform no invalidation.
  A_SCollectionViewInvalidationStyleNone,
  /// Perform invalidation with animation (use an empty batch update).
  A_SCollectionViewInvalidationStyleWithoutAnimation,
  /// Perform invalidation without animation (use -invalidateLayout).
  A_SCollectionViewInvalidationStyleWithAnimation,
};

static const NSUInteger kA_SCollectionViewAnimationNone = UITableViewRowAnimationNone;

/// Used for all cells and supplementaries. UICV keys by supp-kind+reuseID so this is plenty.
static NSString * const kReuseIdentifier = @"_A_SCollectionReuseIdentifier";

#pragma mark -
#pragma mark A_SCollectionView.

@interface A_SCollectionView () <A_SRangeControllerDataSource, A_SRangeControllerDelegate, A_SDataControllerSource, A_SCellNodeInteractionDelegate, A_SDelegateProxyInterceptor, A_SBatchFetchingScrollView, A_SCALayerExtendedDelegate, UICollectionViewDelegateFlowLayout> {
  A_SCollectionViewProxy *_proxyDataSource;
  A_SCollectionViewProxy *_proxyDelegate;
  
  A_SDataController *_dataController;
  A_SRangeController *_rangeController;
  A_SCollectionViewLayoutController *_layoutController;
  id<A_SCollectionViewLayoutInspecting> _defaultLayoutInspector;
  __weak id<A_SCollectionViewLayoutInspecting> _layoutInspector;
  NSHashTable<_A_SCollectionViewCell *> *_cellsForVisibilityUpdates;
  NSHashTable<A_SCellNode *> *_cellsForLayoutUpdates;
  id<A_SCollectionViewLayoutFacilitatorProtocol> _layoutFacilitator;
  CGFloat _leadingScreensForBatching;
  BOOL _inverted;
  
  NSUInteger _superBatchUpdateCount;
  BOOL _isDeallocating;
  
  A_SBatchContext *_batchContext;
  
  CGSize _lastBoundsSizeUsedForMeasuringNodes;
  
  NSMutableSet *_registeredSupplementaryKinds;
  
  // CountedSet because UIKit may display the same element in multiple cells e.g. during animations.
  NSCountedSet<A_SCollectionElement *> *_visibleElements;
  
  CGPoint _deceleratingVelocity;

  BOOL _zeroContentInsets;
  
  A_SCollectionViewInvalidationStyle _nextLayoutInvalidationStyle;
  
  /**
   * Our layer, retained. Under iOS < 9, when collection views are removed from the hierarchy,
   * their layers may be deallocated and become dangling pointers. This puts the collection view
   * into a very dangerous state where pretty much any call will crash it. So we manually retain our layer.
   *
   * You should never access this, and it will be nil under iOS >= 9.
   */
  CALayer *_retainedLayer;
  
  /**
   * If YES, the `UICollectionView` will reload its data on next layout pass so we should not forward any updates to it.
   
   * Rationale:
   * In `reloadData`, a collection view invalidates its data and marks itself as needing reload, and waits until `layoutSubviews` to requery its data source.
   * This can lead to data inconsistency problems.
   * Say you have an empty collection view. You call `reloadData`, then immediately insert an item into your data source and call `insertItemsAtIndexPaths:[0,0]`.
   * You will get an assertion failure saying `Invalid number of items in section 0.
   * The number of items after the update (1) must be equal to the number of items before the update (1) plus or minus the items added and removed (1 added, 0 removed).`
   * The collection view never queried your data source before the update to see that it actually had 0 items.
   */
  BOOL _superIsPendingDataLoad;

  /**
   * It's important that we always check for batch fetching at least once, but also
   * that we do not check for batch fetching for empty updates (as that may cause an infinite
   * loop of batch fetching, where the batch completes and performBatchUpdates: is called without
   * actually making any changes.) So to handle the case where a collection is completely empty
   * (0 sections) we always check at least once after each update (initial reload is the first update.)
   */
  BOOL _hasEverCheckedForBatchFetchingDueToUpdate;
  
  /**
   * Counter used to keep track of nested batch updates.
   */
  NSInteger _batchUpdateCount;
  
  struct {
    unsigned int scrollViewDidScroll:1;
    unsigned int scrollViewWillBeginDragging:1;
    unsigned int scrollViewDidEndDragging:1;
    unsigned int scrollViewWillEndDragging:1;
    unsigned int scrollViewDidEndDecelerating:1;
    unsigned int collectionViewWillDisplayNodeForItem:1;
    unsigned int collectionViewWillDisplayNodeForItemDeprecated:1;
    unsigned int collectionViewDidEndDisplayingNodeForItem:1;
    unsigned int collectionViewShouldSelectItem:1;
    unsigned int collectionViewDidSelectItem:1;
    unsigned int collectionViewShouldDeselectItem:1;
    unsigned int collectionViewDidDeselectItem:1;
    unsigned int collectionViewShouldHighlightItem:1;
    unsigned int collectionViewDidHighlightItem:1;
    unsigned int collectionViewDidUnhighlightItem:1;
    unsigned int collectionViewShouldShowMenuForItem:1;
    unsigned int collectionViewCanPerformActionForItem:1;
    unsigned int collectionViewPerformActionForItem:1;
    unsigned int collectionViewWillBeginBatchFetch:1;
    unsigned int shouldBatchFetchForCollectionView:1;
    unsigned int collectionNodeWillDisplayItem:1;
    unsigned int collectionNodeDidEndDisplayingItem:1;
    unsigned int collectionNodeShouldSelectItem:1;
    unsigned int collectionNodeDidSelectItem:1;
    unsigned int collectionNodeShouldDeselectItem:1;
    unsigned int collectionNodeDidDeselectItem:1;
    unsigned int collectionNodeShouldHighlightItem:1;
    unsigned int collectionNodeDidHighlightItem:1;
    unsigned int collectionNodeDidUnhighlightItem:1;
    unsigned int collectionNodeShouldShowMenuForItem:1;
    unsigned int collectionNodeCanPerformActionForItem:1;
    unsigned int collectionNodePerformActionForItem:1;
    unsigned int collectionNodeWillBeginBatchFetch:1;
    unsigned int collectionNodeWillDisplaySupplementaryElement:1;
    unsigned int collectionNodeDidEndDisplayingSupplementaryElement:1;
    unsigned int shouldBatchFetchForCollectionNode:1;

    // Interop flags
    unsigned int interop:1;
    unsigned int interopWillDisplayCell:1;
    unsigned int interopDidEndDisplayingCell:1;
    unsigned int interopWillDisplaySupplementaryView:1;
    unsigned int interopdidEndDisplayingSupplementaryView:1;
  } _asyncDelegateFlags;
  
  struct {
    unsigned int collectionViewNodeForItem:1;
    unsigned int collectionViewNodeBlockForItem:1;
    unsigned int collectionViewNodeForSupplementaryElement:1;
    unsigned int numberOfSectionsInCollectionView:1;
    unsigned int collectionViewNumberOfItemsInSection:1;
    unsigned int collectionNodeNodeForItem:1;
    unsigned int collectionNodeNodeBlockForItem:1;
    unsigned int nodeModelForItem:1;
    unsigned int collectionNodeNodeForSupplementaryElement:1;
    unsigned int collectionNodeNodeBlockForSupplementaryElement:1;
    unsigned int collectionNodeSupplementaryElementKindsInSection:1;
    unsigned int numberOfSectionsInCollectionNode:1;
    unsigned int collectionNodeNumberOfItemsInSection:1;
    unsigned int collectionNodeContextForSection:1;

    // Whether this data source conforms to A_SCollectionDataSourceInterop
    unsigned int interop:1;
    // Whether this interop data source returns YES from +dequeuesCellsForNodeBackedItems
    unsigned int interopAlwaysDequeue:1;
    // Whether this interop data source implements viewForSupplementaryElementOfKind:
    unsigned int interopViewForSupplementaryElement:1;
  } _asyncDataSourceFlags;
  
  struct {
    unsigned int constrainedSizeForSupplementaryNodeOfKindAtIndexPath:1;
    unsigned int supplementaryNodesOfKindInSection:1;
    unsigned int didChangeCollectionViewDataSource:1;
    unsigned int didChangeCollectionViewDelegate:1;
  } _layoutInspectorFlags;
  
  BOOL _hasDataControllerLayoutDelegate;
}

@end

@implementation A_SCollectionView
{
  __weak id<A_SCollectionDelegate> _asyncDelegate;
  __weak id<A_SCollectionDataSource> _asyncDataSource;
}

// Using _A_SDisplayLayer ensures things like -layout are properly forwarded to A_SCollectionNode.
+ (Class)layerClass
{
  return [_A_SDisplayLayer class];
}

#pragma mark -
#pragma mark Lifecycle.

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self initWithFrame:CGRectZero collectionViewLayout:layout];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self _initWithFrame:frame collectionViewLayout:layout layoutFacilitator:nil owningNode:nil eventLog:nil];
}

- (instancetype)_initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(id<A_SCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator owningNode:(A_SCollectionNode *)owningNode eventLog:(A_SEventLog *)eventLog
{
  if (!(self = [super initWithFrame:frame collectionViewLayout:layout]))
    return nil;

  // Disable UICollectionView prefetching. Use super, because self disables this method.
  // Experiments done by Instagram show that this option being YES (default)
  // when unused causes a significant hit to scroll performance.
  // https://github.com/Instagram/IGListKit/issues/318
  if (A_S_AT_LEA_ST_IOS10) {
    super.prefetchingEnabled = NO;
  }

  _layoutController = [[A_SCollectionViewLayoutController alloc] initWithCollectionView:self];
  
  _rangeController = [[A_SRangeController alloc] init];
  _rangeController.dataSource = self;
  _rangeController.delegate = self;
  _rangeController.layoutController = _layoutController;
  
  _dataController = [[A_SDataController alloc] initWithDataSource:self node:owningNode eventLog:eventLog];
  _dataController.delegate = _rangeController;
  
  _batchContext = [[A_SBatchContext alloc] init];
  
  _leadingScreensForBatching = 2.0;
  
  _lastBoundsSizeUsedForMeasuringNodes = self.bounds.size;
  
  _layoutFacilitator = layoutFacilitator;
  
  _proxyDelegate = [[A_SCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
  super.delegate = (id<UICollectionViewDelegate>)_proxyDelegate;
  
  _proxyDataSource = [[A_SCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
  super.dataSource = (id<UICollectionViewDataSource>)_proxyDataSource;
  
  _registeredSupplementaryKinds = [NSMutableSet set];
  _visibleElements = [[NSCountedSet alloc] init];
  
  _cellsForVisibilityUpdates = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  _cellsForLayoutUpdates = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  self.backgroundColor = [UIColor whiteColor];
  
  [self registerClass:[_A_SCollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifier];
  
  if (!A_S_AT_LEA_ST_IOS9) {
    _retainedLayer = self.layer;
  }
  
  [self _configureCollectionViewLayout:layout];
  
  return self;
}

- (void)dealloc
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeCAssert(_batchUpdateCount == 0, @"A_SCollectionView deallocated in the middle of a batch update.");
  
  // Sometimes the UIKit classes can call back to their delegate even during deallocation, due to animation completion blocks etc.
  _isDeallocating = YES;
  [self setAsyncDelegate:nil];
  [self setAsyncDataSource:nil];

  // Data controller & range controller may own a ton of nodes, let's deallocate those off-main.
  A_SPerformBackgroundDeallocation(&_dataController);
  A_SPerformBackgroundDeallocation(&_rangeController);
}

#pragma mark -
#pragma mark Overrides.

/**
 * This method is not available to be called by the public i.e.
 * it should only be called by UICollectionView itself. UICollectionView
 * does this e.g. during the first layout pass, or if you call -numberOfSections
 * before its content is loaded.
 */
- (void)reloadData
{
  [super reloadData];

  // UICollectionView calls -reloadData during first layoutSubviews and when the data source changes.
  // This fires off the first load of cell nodes.
  if (_asyncDataSource != nil && !self.dataController.initialReloadDataHasBeenCalled) {
    [self performBatchUpdates:^{
      [_changeSet reloadData];
    } completion:nil];
  }
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated
{
  if ([self validateIndexPath:indexPath]) {
    [super scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
  }
}

- (void)relayoutItems
{
  [_dataController relayoutAllNodesWithInvalidationBlock:^{
    [self.collectionViewLayout invalidateLayout];
    [self invalidateFlowLayoutDelegateMetrics];
  }];
}

- (BOOL)isProcessingUpdates
{
  return [_dataController isProcessingUpdates];
}

- (void)onDidFinishProcessingUpdates:(nullable void (^)())completion
{
  [_dataController onDidFinishProcessingUpdates:completion];
}

- (void)waitUntilAllUpdatesAreCommitted
{
  A_SDisplayNodeAssertMainThread();
  if (_batchUpdateCount > 0) {
    // This assertion will be enabled soon.
    //    A_SDisplayNodeFailAssert(@"Should not call %@ during batch update", NSStringFromSelector(_cmd));
    return;
  }

  [_dataController waitUntilAllUpdatesAreProcessed];
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
  // UIKit can internally generate a call to this method upon changing the asyncDataSource; only assert for non-nil. We also allow this when we're doing interop.
  A_SDisplayNodeAssert(_asyncDelegateFlags.interop || dataSource == nil, @"A_SCollectionView uses asyncDataSource, not UICollectionView's dataSource property.");
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
  // Our UIScrollView superclass sets its delegate to nil on dealloc. Only assert if we get a non-nil value here. We also allow this when we're doing interop.
  A_SDisplayNodeAssert(_asyncDelegateFlags.interop || delegate == nil, @"A_SCollectionView uses asyncDelegate, not UICollectionView's delegate property.");
}

- (void)proxyTargetHasDeallocated:(A_SDelegateProxy *)proxy
{
  if (proxy == _proxyDelegate) {
    [self setAsyncDelegate:nil];
  } else if (proxy == _proxyDataSource) {
    [self setAsyncDataSource:nil];
  }
}

- (id<A_SCollectionDataSource>)asyncDataSource
{
  return _asyncDataSource;
}

- (void)setAsyncDataSource:(id<A_SCollectionDataSource>)asyncDataSource
{
  // Changing super.dataSource will trigger a setNeedsLayout, so this must happen on the main thread.
  A_SDisplayNodeAssertMainThread();

  // Note: It's common to check if the value hasn't changed and short-circuit but we aren't doing that here to handle
  // the (common) case of nilling the asyncDataSource in the ViewController's dealloc. In this case our _asyncDataSource
  // will return as nil (ARC magic) even though the _proxyDataSource still exists. It's really important to hold a strong
  // reference to the old dataSource in this case because calls to A_SCollectionViewProxy will start failing and cause crashes.
  NS_VALID_UNTIL_END_OF_SCOPE id oldDataSource = super.dataSource;
  
  if (asyncDataSource == nil) {
    _asyncDataSource = nil;
    _proxyDataSource = _isDeallocating ? nil : [[A_SCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
    _asyncDataSourceFlags = {};

  } else {
    _asyncDataSource = asyncDataSource;
    _proxyDataSource = [[A_SCollectionViewProxy alloc] initWithTarget:_asyncDataSource interceptor:self];
    
    _asyncDataSourceFlags.collectionViewNodeForItem = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeForItemAtIndexPath:)];
    _asyncDataSourceFlags.collectionViewNodeBlockForItem = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeBlockForItemAtIndexPath:)];
    _asyncDataSourceFlags.numberOfSectionsInCollectionView = [_asyncDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)];
    _asyncDataSourceFlags.collectionViewNumberOfItemsInSection = [_asyncDataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)];
    _asyncDataSourceFlags.collectionViewNodeForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeForSupplementaryElementOfKind:atIndexPath:)];

    _asyncDataSourceFlags.collectionNodeNodeForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeForItemAtIndexPath:)];
    _asyncDataSourceFlags.collectionNodeNodeBlockForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeBlockForItemAtIndexPath:)];
    _asyncDataSourceFlags.numberOfSectionsInCollectionNode = [_asyncDataSource respondsToSelector:@selector(numberOfSectionsInCollectionNode:)];
    _asyncDataSourceFlags.collectionNodeNumberOfItemsInSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:numberOfItemsInSection:)];
    _asyncDataSourceFlags.collectionNodeContextForSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:contextForSection:)];
    _asyncDataSourceFlags.collectionNodeNodeForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeForSupplementaryElementOfKind:atIndexPath:)];
    _asyncDataSourceFlags.collectionNodeNodeBlockForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeBlockForSupplementaryElementOfKind:atIndexPath:)];
    _asyncDataSourceFlags.collectionNodeSupplementaryElementKindsInSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:supplementaryElementKindsInSection:)];
    _asyncDataSourceFlags.nodeModelForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeModelForItemAtIndexPath:)];

    _asyncDataSourceFlags.interop = [_asyncDataSource conformsToProtocol:@protocol(A_SCollectionDataSourceInterop)];
    if (_asyncDataSourceFlags.interop) {
      id<A_SCollectionDataSourceInterop> interopDataSource = (id<A_SCollectionDataSourceInterop>)_asyncDataSource;
      _asyncDataSourceFlags.interopAlwaysDequeue = [[interopDataSource class] respondsToSelector:@selector(dequeuesCellsForNodeBackedItems)] && [[interopDataSource class] dequeuesCellsForNodeBackedItems];
      _asyncDataSourceFlags.interopViewForSupplementaryElement = [interopDataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    }

    A_SDisplayNodeAssert(_asyncDataSourceFlags.collectionNodeNumberOfItemsInSection || _asyncDataSourceFlags.collectionViewNumberOfItemsInSection, @"Data source must implement collectionNode:numberOfItemsInSection:");
    A_SDisplayNodeAssert(_asyncDataSourceFlags.collectionNodeNodeBlockForItem
                        || _asyncDataSourceFlags.collectionNodeNodeForItem
                        || _asyncDataSourceFlags.collectionViewNodeBlockForItem
                        || _asyncDataSourceFlags.collectionViewNodeForItem, @"Data source must implement collectionNode:nodeBlockForItemAtIndexPath: or collectionNode:nodeForItemAtIndexPath:");
  }
  
  _dataController.validationErrorSource = asyncDataSource;
  super.dataSource = (id<UICollectionViewDataSource>)_proxyDataSource;
  
  //Cache results of layoutInspector to ensure flags are up to date if getter lazily loads a new one.
  id<A_SCollectionViewLayoutInspecting> layoutInspector = self.layoutInspector;
  if (_layoutInspectorFlags.didChangeCollectionViewDataSource) {
    [layoutInspector didChangeCollectionViewDataSource:asyncDataSource];
  }
}

- (id<A_SCollectionDelegate>)asyncDelegate
{
  return _asyncDelegate;
}

- (void)setAsyncDelegate:(id<A_SCollectionDelegate>)asyncDelegate
{
  // Changing super.delegate will trigger a setNeedsLayout, so this must happen on the main thread.
  A_SDisplayNodeAssertMainThread();

  // Note: It's common to check if the value hasn't changed and short-circuit but we aren't doing that here to handle
  // the (common) case of nilling the asyncDelegate in the ViewController's dealloc. In this case our _asyncDelegate
  // will return as nil (ARC magic) even though the _proxyDataSource still exists. It's really important to hold a strong
  // reference to the old delegate in this case because calls to A_SCollectionViewProxy will start failing and cause crashes.
  NS_VALID_UNTIL_END_OF_SCOPE id oldDelegate = super.delegate;
  
  if (asyncDelegate == nil) {
    _asyncDelegate = nil;
    _proxyDelegate = _isDeallocating ? nil : [[A_SCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
    _asyncDelegateFlags = {};
  } else {
    _asyncDelegate = asyncDelegate;
    _proxyDelegate = [[A_SCollectionViewProxy alloc] initWithTarget:_asyncDelegate interceptor:self];
    
    _asyncDelegateFlags.scrollViewDidScroll = [_asyncDelegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _asyncDelegateFlags.scrollViewWillEndDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)];
    _asyncDelegateFlags.scrollViewDidEndDecelerating = [_asyncDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
    _asyncDelegateFlags.scrollViewWillBeginDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    _asyncDelegateFlags.scrollViewDidEndDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _asyncDelegateFlags.collectionViewWillDisplayNodeForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:willDisplayNode:forItemAtIndexPath:)];
    if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItem == NO) {
      _asyncDelegateFlags.collectionViewWillDisplayNodeForItemDeprecated = [_asyncDelegate respondsToSelector:@selector(collectionView:willDisplayNodeForItemAtIndexPath:)];
    }
    _asyncDelegateFlags.collectionViewDidEndDisplayingNodeForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didEndDisplayingNode:forItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewWillBeginBatchFetch = [_asyncDelegate respondsToSelector:@selector(collectionView:willBeginBatchFetchWithContext:)];
    _asyncDelegateFlags.shouldBatchFetchForCollectionView = [_asyncDelegate respondsToSelector:@selector(shouldBatchFetchForCollectionView:)];
    _asyncDelegateFlags.collectionViewShouldSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidUnhighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldShowMenuForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldShowMenuForItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewCanPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)];
    _asyncDelegateFlags.collectionViewPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:performAction:forItemAtIndexPath:withSender:)];
    _asyncDelegateFlags.collectionNodeWillDisplayItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:willDisplayItemWithNode:)];
    _asyncDelegateFlags.collectionNodeDidEndDisplayingItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didEndDisplayingItemWithNode:)];
    _asyncDelegateFlags.collectionNodeWillBeginBatchFetch = [_asyncDelegate respondsToSelector:@selector(collectionNode:willBeginBatchFetchWithContext:)];
    _asyncDelegateFlags.shouldBatchFetchForCollectionNode = [_asyncDelegate respondsToSelector:@selector(shouldBatchFetchForCollectionNode:)];
    _asyncDelegateFlags.collectionNodeShouldSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidUnhighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didUnhighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldShowMenuForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldShowMenuForItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeCanPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:canPerformAction:forItemAtIndexPath:sender:)];
    _asyncDelegateFlags.collectionNodePerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:performAction:forItemAtIndexPath:sender:)];
    _asyncDelegateFlags.interop = [_asyncDelegate conformsToProtocol:@protocol(A_SCollectionDelegateInterop)];
    if (_asyncDelegateFlags.interop) {
      id<A_SCollectionDelegateInterop> interopDelegate = (id<A_SCollectionDelegateInterop>)_asyncDelegate;
      _asyncDelegateFlags.interopWillDisplayCell = [interopDelegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)];
      _asyncDelegateFlags.interopDidEndDisplayingCell = [interopDelegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)];
      _asyncDelegateFlags.interopWillDisplaySupplementaryView = [interopDelegate respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)];
      _asyncDelegateFlags.interopdidEndDisplayingSupplementaryView = [interopDelegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)];
    }
  }

  super.delegate = (id<UICollectionViewDelegate>)_proxyDelegate;
  
  //Cache results of layoutInspector to ensure flags are up to date if getter lazily loads a new one.
  id<A_SCollectionViewLayoutInspecting> layoutInspector = self.layoutInspector;
  if (_layoutInspectorFlags.didChangeCollectionViewDelegate) {
    [layoutInspector didChangeCollectionViewDelegate:asyncDelegate];
  }
}

- (void)setCollectionViewLayout:(nonnull UICollectionViewLayout *)collectionViewLayout
{
  A_SDisplayNodeAssertMainThread();
  [super setCollectionViewLayout:collectionViewLayout];
  
  [self _configureCollectionViewLayout:collectionViewLayout];
  
  // Trigger recreation of layout inspector with new collection view layout
  if (_layoutInspector != nil) {
    _layoutInspector = nil;
    [self layoutInspector];
  }
}

- (id<A_SCollectionViewLayoutInspecting>)layoutInspector
{
  if (_layoutInspector == nil) {
    UICollectionViewLayout *layout = self.collectionViewLayout;
    if (layout == nil) {
      // Layout hasn't been set yet, we're still init'ing
      return nil;
    }

    _defaultLayoutInspector = [layout asdk_layoutInspector];
    A_SDisplayNodeAssertNotNil(_defaultLayoutInspector, @"You must not return nil from -asdk_layoutInspector. Return [super asdk_layoutInspector] if you have to! Layout: %@", layout);
    
    // Explicitly call the setter to wire up the _layoutInspectorFlags
    self.layoutInspector = _defaultLayoutInspector;
  }

  return _layoutInspector;
}

- (void)setLayoutInspector:(id<A_SCollectionViewLayoutInspecting>)layoutInspector
{
  _layoutInspector = layoutInspector;
  
  _layoutInspectorFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath = [_layoutInspector respondsToSelector:@selector(collectionView:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:)];
  _layoutInspectorFlags.supplementaryNodesOfKindInSection = [_layoutInspector respondsToSelector:@selector(collectionView:supplementaryNodesOfKind:inSection:)];
  _layoutInspectorFlags.didChangeCollectionViewDataSource = [_layoutInspector respondsToSelector:@selector(didChangeCollectionViewDataSource:)];
  _layoutInspectorFlags.didChangeCollectionViewDelegate = [_layoutInspector respondsToSelector:@selector(didChangeCollectionViewDelegate:)];

  if (_layoutInspectorFlags.didChangeCollectionViewDataSource) {
    [_layoutInspector didChangeCollectionViewDataSource:self.asyncDataSource];
  }
  if (_layoutInspectorFlags.didChangeCollectionViewDelegate) {
    [_layoutInspector didChangeCollectionViewDelegate:self.asyncDelegate];
  }
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType
{
  [_rangeController setTuningParameters:tuningParameters forRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType
{
  return [_rangeController tuningParametersForRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  [_rangeController setTuningParameters:tuningParameters forRangeMode:rangeMode rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  return [_rangeController tuningParametersForRangeMode:rangeMode rangeType:rangeType];
}

- (void)setZeroContentInsets:(BOOL)zeroContentInsets
{
  _zeroContentInsets = zeroContentInsets;
}

- (BOOL)zeroContentInsets
{
  return _zeroContentInsets;
}

/// Uses latest size range from data source and -layoutThatFits:.
- (CGSize)sizeForElement:(A_SCollectionElement *)element
{
  A_SDisplayNodeAssertMainThread();
  if (element == nil) {
    return CGSizeZero;
  }

  A_SCellNode *node = element.node;
  BOOL useUIKitCell = node.shouldUseUIKitCell;
  if (useUIKitCell) {
    // In this case, we should use the exact value that was stashed earlier by calling sizeForItem:, referenceSizeFor*, etc.
    // Although the node would use the preferredSize in layoutThatFits, we can skip this because there's no constrainedSize.
    A_SDisplayNodeAssert([node.superclass isSubclassOfClass:[A_SCellNode class]] == NO,
                        @"Placeholder cells for UIKit passthrough should be generic A_SCellNodes: %@", node);
    return node.style.preferredSize;
  } else {
    return [node layoutThatFits:element.constrainedSize].size;
  }
}

- (CGSize)calculatedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();

  A_SCollectionElement *e = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  return [self sizeForElement:e];
}

- (A_SCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_dataController.visibleMap elementForItemAtIndexPath:indexPath].node;
}

- (NSIndexPath *)convertIndexPathFromCollectionNode:(NSIndexPath *)indexPath waitingIfNeeded:(BOOL)wait
{
  if (indexPath == nil) {
    return nil;
  }

  NSIndexPath *viewIndexPath = [_dataController.visibleMap convertIndexPath:indexPath fromMap:_dataController.pendingMap];
  if (viewIndexPath == nil && wait) {
    [self waitUntilAllUpdatesAreCommitted];
    return [self convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:NO];
  }
  return viewIndexPath;
}

/**
 * Asserts that the index path is a valid view-index-path, and returns it if so, nil otherwise.
 */
- (nullable NSIndexPath *)validateIndexPath:(nullable NSIndexPath *)indexPath
{
  if (indexPath == nil) {
    return nil;
  }

  NSInteger section = indexPath.section;
  if (section >= self.numberOfSections) {
    A_SDisplayNodeFailAssert(@"Collection view index path has invalid section %lu, section count = %lu", (unsigned long)section, (unsigned long)self.numberOfSections);
    return nil;
  }

  NSInteger item = indexPath.item;
  // item == NSNotFound means e.g. "scroll to this section" and is acceptable
  if (item != NSNotFound && item >= [self numberOfItemsInSection:section]) {
    A_SDisplayNodeFailAssert(@"Collection view index path has invalid item %lu in section %lu, item count = %lu", (unsigned long)indexPath.item, (unsigned long)section, (unsigned long)[self numberOfItemsInSection:section]);
    return nil;
  }

  return indexPath;
}

- (NSIndexPath *)convertIndexPathToCollectionNode:(NSIndexPath *)indexPath
{
  if ([self validateIndexPath:indexPath] == nil) {
    return nil;
  }

  return [_dataController.pendingMap convertIndexPath:indexPath fromMap:_dataController.visibleMap];
}

- (NSArray<NSIndexPath *> *)convertIndexPathsToCollectionNode:(NSArray<NSIndexPath *> *)indexPaths
{
  if (indexPaths == nil) {
    return nil;
  }

  NSMutableArray<NSIndexPath *> *indexPathsArray = [NSMutableArray arrayWithCapacity:indexPaths.count];

  for (NSIndexPath *indexPathInView in indexPaths) {
    NSIndexPath *indexPath = [self convertIndexPathToCollectionNode:indexPathInView];
    if (indexPath != nil) {
      [indexPathsArray addObject:indexPath];
    }
  }
  return indexPathsArray;
}

- (A_SCellNode *)supplementaryNodeForElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  return [_dataController.visibleMap supplementaryElementOfKind:elementKind atIndexPath:indexPath].node;
}

- (NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode
{
  return [_dataController.visibleMap indexPathForElement:cellNode.collectionElement];
}

- (NSArray *)visibleNodes
{
  NSArray *indexPaths = [self indexPathsForVisibleItems];
  NSMutableArray *visibleNodes = [[NSMutableArray alloc] init];
  
  for (NSIndexPath *indexPath in indexPaths) {
    A_SCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node) {
      // It is possible for UICollectionView to return indexPaths before the node is completed.
      [visibleNodes addObject:node];
    }
  }
  
  return visibleNodes;
}

- (BOOL)usesSynchronousDataLoading
{
  return self.dataController.usesSynchronousDataLoading;
}

- (void)setUsesSynchronousDataLoading:(BOOL)usesSynchronousDataLoading
{
  self.dataController.usesSynchronousDataLoading = usesSynchronousDataLoading;
}

- (void)invalidateFlowLayoutDelegateMetrics {
  for (A_SCollectionElement *element in self.dataController.pendingMap) {
    // This may be either a Supplementary or Item type element.
    // For UIKit passthrough cells of either type, re-fetch their sizes from the standard UIKit delegate methods.
    A_SCellNode *node = element.node;
    if (node.shouldUseUIKitCell) {
      NSIndexPath *indexPath = [self indexPathForNode:node];
      NSString *kind = [element supplementaryElementKind];
      CGSize previousSize = node.style.preferredSize;
      CGSize size = [self _sizeForUIKitCellWithKind:kind atIndexPath:indexPath];

      if (!CGSizeEqualToSize(previousSize, size)) {
        node.style.preferredSize = size;
        [node invalidateCalculatedLayout];
      }
    }
  }
}

#pragma mark Internal

- (void)_configureCollectionViewLayout:(nonnull UICollectionViewLayout *)layout
{
  _hasDataControllerLayoutDelegate = [layout conformsToProtocol:@protocol(A_SDataControllerLayoutDelegate)];
  if (_hasDataControllerLayoutDelegate) {
    _dataController.layoutDelegate = (id<A_SDataControllerLayoutDelegate>)layout;
  }
}

/**
 This method is called only for UIKit Passthrough cells - either regular Items or Supplementary elements.
 It checks if the delegate implements the UICollectionViewFlowLayout methods that provide sizes, and if not,
 uses the default values set on the flow layout. If a flow layout is not in use, UICollectionView Passthrough
 cells must be sized by logic in the Layout object, and Tex_ture does not participate in these paths.
*/
- (CGSize)_sizeForUIKitCellWithKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  CGSize size = CGSizeZero;
  UICollectionViewLayout *l = self.collectionViewLayout;

  if (kind == nil) {
    A_SDisplayNodeAssert(_asyncDataSourceFlags.interop, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForItem = @selector(collectionView:layout:sizeForItemAtIndexPath:);
    if ([_asyncDelegate respondsToSelector:sizeForItem]) {
      size = [(id)_asyncDelegate collectionView:self layout:l sizeForItemAtIndexPath:indexPath];
    } else {
      size = A_SFlowLayoutDefault(l, itemSize, CGSizeZero);
    }
  } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
    A_SDisplayNodeAssert(_asyncDataSourceFlags.interopViewForSupplementaryElement, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForHeader = @selector(collectionView:layout:referenceSizeForHeaderInSection:);
    if ([_asyncDelegate respondsToSelector:sizeForHeader]) {
      size = [(id)_asyncDelegate collectionView:self layout:l referenceSizeForHeaderInSection:indexPath.section];
    } else {
      size = A_SFlowLayoutDefault(l, headerReferenceSize, CGSizeZero);
    }
  } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
    A_SDisplayNodeAssert(_asyncDataSourceFlags.interopViewForSupplementaryElement, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForFooter = @selector(collectionView:layout:referenceSizeForFooterInSection:);
    if ([_asyncDelegate respondsToSelector:sizeForFooter]) {
      size = [(id)_asyncDelegate collectionView:self layout:l referenceSizeForFooterInSection:indexPath.section];
    } else {
      size = A_SFlowLayoutDefault(l, footerReferenceSize, CGSizeZero);
    }
  }

  return size;
}

/**
 Performing nested batch updates with super (e.g. resizing a cell node & updating collection view during same frame)
 can cause super to throw data integrity exceptions because it checks the data source counts before
 the update is complete.
 
 Always call [self _superPerform:] rather than [super performBatch:] so that we can keep our `superPerformingBatchUpdates` flag updated.
*/
- (void)_superPerformBatchUpdates:(void(^)())updates completion:(void(^)(BOOL finished))completion
{
  A_SDisplayNodeAssertMainThread();
  
  _superBatchUpdateCount++;
  [super performBatchUpdates:updates completion:completion];
  _superBatchUpdateCount--;
}

#pragma mark Assertions.

- (A_SDataController *)dataController
{
  return _dataController;
}

- (void)beginUpdates
{
  A_SDisplayNodeAssertMainThread();
  // _changeSet must be available during batch update
  A_SDisplayNodeAssertTrue((_batchUpdateCount > 0) == (_changeSet != nil));
  
  if (_batchUpdateCount == 0) {
    _changeSet = [[_A_SHierarchyChangeSet alloc] initWithOldData:[_dataController itemCountsFromDataSource]];
    _changeSet.rootActivity = as_activity_create("Perform async collection update", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT);
    _changeSet.submitActivity = as_activity_create("Submit changes for collection update", _changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT);
  }
  _batchUpdateCount++;  
}

- (void)endUpdatesAnimated:(BOOL)animated completion:(nullable void (^)(BOOL))completion
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssertNotNil(_changeSet, @"_changeSet must be available when batch update ends");

  _batchUpdateCount--;
  // Prevent calling endUpdatesAnimated:completion: in an unbalanced way
  NSAssert(_batchUpdateCount >= 0, @"endUpdatesAnimated:completion: called without having a balanced beginUpdates call");
  
  [_changeSet addCompletionHandler:completion];
  
  if (_batchUpdateCount == 0) {
    _A_SHierarchyChangeSet *changeSet = _changeSet;

    // Nil out _changeSet before forwarding to _dataController to allow the change set to cause subsequent batch updates on the same run loop
    _changeSet = nil;
    changeSet.animated = animated;
    [_dataController updateWithChangeSet:changeSet];
  }
}

- (void)performBatchAnimated:(BOOL)animated updates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  A_SDisplayNodeAssertMainThread();
  [self beginUpdates];
  as_activity_scope(_changeSet.rootActivity);
  {
    // Only include client code in the submit activity, the rest just lives in the root activity. 
    as_activity_scope(_changeSet.submitActivity);
    if (updates) {
      updates();
    }
  }
  [self endUpdatesAnimated:animated completion:completion];
}

- (void)performBatchUpdates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  // We capture the current state of whether animations are enabled if they don't provide us with one.
  [self performBatchAnimated:[UIView areAnimationsEnabled] updates:updates completion:completion];
}

- (void)registerSupplementaryNodeOfKind:(NSString *)elementKind
{
  A_SDisplayNodeAssert(elementKind != nil, @"A kind is needed for supplementary node registration");
  [_registeredSupplementaryKinds addObject:elementKind];
  [self registerClass:[_A_SCollectionReusableView class] forSupplementaryViewOfKind:elementKind withReuseIdentifier:kReuseIdentifier];
}

- (void)insertSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet insertSections:sections animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)deleteSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet deleteSections:sections animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)reloadSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet reloadSections:sections animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
  A_SDisplayNodeAssertMainThread();
  [self performBatchUpdates:^{
    [_changeSet moveSection:section toSection:newSection animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (id<A_SSectionContext>)contextForSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  return [_dataController.visibleMap contextForSection:section];
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet insertItems:indexPaths animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet deleteItems:indexPaths animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet reloadItems:indexPaths animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
  A_SDisplayNodeAssertMainThread();
  [self performBatchUpdates:^{
    [_changeSet moveItemAtIndexPath:indexPath toIndexPath:newIndexPath animationOptions:kA_SCollectionViewAnimationNone];
  } completion:nil];
}

#pragma mark -
#pragma mark Intercepted selectors.

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  if (_superIsPendingDataLoad) {
    [_rangeController setNeedsUpdate];
    [self _scheduleCheckForBatchFetchingForNumberOfChanges:1];
    _superIsPendingDataLoad = NO;
  }
  return _dataController.visibleMap.numberOfSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [_dataController.visibleMap numberOfItemsInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout
                                            sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionElement *e = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  return e ? [self sizeForElement:e] : A_SFlowLayoutDefault(layout, itemSize, CGSizeZero);
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                       referenceSizeForHeaderInSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  A_SElementMap *map = _dataController.visibleMap;
  A_SCollectionElement *e = [map supplementaryElementOfKind:UICollectionElementKindSectionHeader
                                               atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
  return e ? [self sizeForElement:e] : A_SFlowLayoutDefault(l, headerReferenceSize, CGSizeZero);
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                       referenceSizeForFooterInSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  A_SElementMap *map = _dataController.visibleMap;
  A_SCollectionElement *e = [map supplementaryElementOfKind:UICollectionElementKindSectionFooter
                                               atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
  return e ? [self sizeForElement:e] : A_SFlowLayoutDefault(l, footerReferenceSize, CGSizeZero);
}

// For the methods that call delegateIndexPathForSection:withSelector:, translate the section from
// visibleMap to pendingMap. If the section no longer exists, or the delegate doesn't implement
// the selector, we will return NSNotFound (and then use the A_SFlowLayoutDefault).
- (NSInteger)delegateIndexForSection:(NSInteger)section withSelector:(SEL)selector
{
  if ([_asyncDelegate respondsToSelector:selector]) {
    return [_dataController.pendingMap convertSection:section fromMap:_dataController.visibleMap];
  } else {
    return NSNotFound;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                                      insetForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l insetForSectionAtIndex:section];
  }
  return A_SFlowLayoutDefault(l, sectionInset, UIEdgeInsetsZero);
}

- (CGFloat)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
               minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l
               minimumInteritemSpacingForSectionAtIndex:section];
  }
  return A_SFlowLayoutDefault(l, minimumInteritemSpacing, 10.0); // Default is documented as 10.0
}

- (CGFloat)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                    minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l
                    minimumLineSpacingForSectionAtIndex:section];
  }
  return A_SFlowLayoutDefault(l, minimumLineSpacing, 10.0);      // Default is documented as 10.0
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if ([_registeredSupplementaryKinds containsObject:kind] == NO) {
    [self registerSupplementaryNodeOfKind:kind];
  }
  
  UICollectionReusableView *view = nil;
  A_SCollectionElement *element = [_dataController.visibleMap supplementaryElementOfKind:kind atIndexPath:indexPath];
  A_SCellNode *node = element.node;

  BOOL shouldDequeueExternally = _asyncDataSourceFlags.interopViewForSupplementaryElement && (_asyncDataSourceFlags.interopAlwaysDequeue || node.shouldUseUIKitCell);
  if (shouldDequeueExternally) {
    // This codepath is used for both IGListKit mode, and app-level UICollectionView interop.
    view = [(id<A_SCollectionDataSourceInterop>)_asyncDataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else {
    A_SDisplayNodeAssert(node != nil, @"Supplementary node should exist.  Kind = %@, indexPath = %@, collectionDataSource = %@", kind, indexPath, self);
    view = [self dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  }
  
  if (_A_SCollectionReusableView *reusableView = A_SDynamicCastStrict(view, _A_SCollectionReusableView)) {
    reusableView.element = element;
  }
  
  if (node) {
    [_rangeController configureContentView:view forCellNode:node];
  }

  return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *cell = nil;
  A_SCollectionElement *element = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  A_SCellNode *node = element.node;

  BOOL shouldDequeueExternally = _asyncDataSourceFlags.interopAlwaysDequeue || (_asyncDataSourceFlags.interop && node.shouldUseUIKitCell);
  if (shouldDequeueExternally) {
    cell = [(id<A_SCollectionDataSourceInterop>)_asyncDataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
  } else {
    cell = [self dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  }

  A_SDisplayNodeAssert(element != nil, @"Element should exist. indexPath = %@, collectionDataSource = %@", indexPath, self);

  if (_A_SCollectionViewCell *asCell = A_SDynamicCastStrict(cell, _A_SCollectionViewCell)) {
    asCell.element = element;
    [_rangeController configureContentView:cell.contentView forCellNode:node];
  }
  
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)rawCell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopWillDisplayCell) {
    A_SCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <A_SCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView willDisplayCell:rawCell forItemAtIndexPath:indexPath];
    }
  }

  _A_SCollectionViewCell *cell = A_SDynamicCastStrict(rawCell, _A_SCollectionViewCell);
  if (cell == nil) {
    [_rangeController setNeedsUpdate];
    return;
  }

  A_SCollectionElement *element = cell.element;
  if (element) {
    A_SDisplayNodeAssertTrue([_dataController.visibleMap elementForItemAtIndexPath:indexPath] == element);
    [_visibleElements addObject:element];
  } else {
    A_SDisplayNodeAssert(NO, @"Unexpected nil element for willDisplayCell: %@, %@, %@", rawCell, self, indexPath);
    return;
  }

  A_SCellNode *cellNode = element.node;
  cellNode.scrollView = collectionView;

  // Update the selected background view in collectionView:willDisplayCell:forItemAtIndexPath: otherwise it could be to
  // early e.g. if the selectedBackgroundView was set in didLoad()
  cell.selectedBackgroundView = cellNode.selectedBackgroundView;
  
  // Under iOS 10+, cells may be removed/re-added to the collection view without
  // receiving prepareForReuse/applyLayoutAttributes, as an optimization for e.g.
  // if the user is scrolling back and forth across a small set of items.
  // In this case, we have to fetch the layout attributes manually.
  // This may be possible under iOS < 10 but it has not been observed yet.
  if (cell.layoutAttributes == nil) {
    cell.layoutAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
  }

  A_SDisplayNodeAssertNotNil(cellNode, @"Expected node associated with cell that will be displayed not to be nil. indexPath: %@", indexPath);

  if (_asyncDelegateFlags.collectionNodeWillDisplayItem && self.collectionNode != nil) {
    [_asyncDelegate collectionNode:self.collectionNode willDisplayItemWithNode:cellNode];
  } else if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self willDisplayNode:cellNode forItemAtIndexPath:indexPath];
  } else if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItemDeprecated) {
    [_asyncDelegate collectionView:self willDisplayNodeForItemAtIndexPath:indexPath];
  }
#pragma clang diagnostic pop
  
  [_rangeController setNeedsUpdate];
  
  if ([cell consumesCellNodeVisibilityEvents]) {
    [_cellsForVisibilityUpdates addObject:cell];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)rawCell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopDidEndDisplayingCell) {
    A_SCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <A_SCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView didEndDisplayingCell:rawCell forItemAtIndexPath:indexPath];
    }
  }

  _A_SCollectionViewCell *cell = A_SDynamicCastStrict(rawCell, _A_SCollectionViewCell);
  if (cell == nil) {
    [_rangeController setNeedsUpdate];
    return;
  }

  // Retrieve the element from cell instead of visible map because at this point visible map could have been updated and no longer holds the element.
  A_SCollectionElement *element = cell.element;
  if (element) {
    [_visibleElements removeObject:element];
  } else {
    A_SDisplayNodeAssert(NO, @"Unexpected nil element for didEndDisplayingCell: %@, %@, %@", rawCell, self, indexPath);
    return;
  }

  A_SCellNode *cellNode = element.node;

  if (_asyncDelegateFlags.collectionNodeDidEndDisplayingItem) {
    if (A_SCollectionNode *collectionNode = self.collectionNode) {
    	[_asyncDelegate collectionNode:collectionNode didEndDisplayingItemWithNode:cellNode];
    }
  } else if (_asyncDelegateFlags.collectionViewDidEndDisplayingNodeForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didEndDisplayingNode:cellNode forItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  
  [_rangeController setNeedsUpdate];
  
  [_cellsForVisibilityUpdates removeObject:cell];
  
  cellNode.scrollView = nil;
  cell.layoutAttributes = nil;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)rawView forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopWillDisplaySupplementaryView) {
    A_SCellNode *node = [self supplementaryNodeForElementKind:elementKind atIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <A_SCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView willDisplaySupplementaryView:rawView forElementKind:elementKind atIndexPath:indexPath];
    }
  }

  _A_SCollectionReusableView *view = A_SDynamicCastStrict(rawView, _A_SCollectionReusableView);
  if (view == nil) {
    return;
  }

  A_SCollectionElement *element = view.element;
  if (element) {
    A_SDisplayNodeAssertTrue([_dataController.visibleMap supplementaryElementOfKind:elementKind atIndexPath:indexPath] == view.element);
    [_visibleElements addObject:element];
  } else {
    A_SDisplayNodeAssert(NO, @"Unexpected nil element for willDisplaySupplementaryView: %@, %@, %@", rawView, self, indexPath);
    return;
  }

  // Under iOS 10+, cells may be removed/re-added to the collection view without
  // receiving prepareForReuse/applyLayoutAttributes, as an optimization for e.g.
  // if the user is scrolling back and forth across a small set of items.
  // In this case, we have to fetch the layout attributes manually.
  // This may be possible under iOS < 10 but it has not been observed yet.
  if (view.layoutAttributes == nil) {
    view.layoutAttributes = [collectionView layoutAttributesForSupplementaryElementOfKind:elementKind atIndexPath:indexPath];
  }

  if (_asyncDelegateFlags.collectionNodeWillDisplaySupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    A_SCellNode *node = element.node;
    A_SDisplayNodeAssert([node.supplementaryElementKind isEqualToString:elementKind], @"Expected node for supplementary element to have kind '%@', got '%@'.", elementKind, node.supplementaryElementKind);
    [_asyncDelegate collectionNode:collectionNode willDisplaySupplementaryElementWithNode:node];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)rawView forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopdidEndDisplayingSupplementaryView) {
    A_SCellNode *node = [self supplementaryNodeForElementKind:elementKind atIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <A_SCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView didEndDisplayingSupplementaryView:rawView forElementOfKind:elementKind atIndexPath:indexPath];
    }
  }

  _A_SCollectionReusableView *view = A_SDynamicCastStrict(rawView, _A_SCollectionReusableView);
  if (view == nil) {
    return;
  }

  // Retrieve the element from cell instead of visible map because at this point visible map could have been updated and no longer holds the element.
  A_SCollectionElement *element = view.element;
  if (element) {
    [_visibleElements removeObject:element];
  } else {
    A_SDisplayNodeAssert(NO, @"Unexpected nil element for didEndDisplayingSupplementaryView: %@, %@, %@", rawView, self, indexPath);
    return;
  }

  if (_asyncDelegateFlags.collectionNodeDidEndDisplayingSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    A_SCellNode *node = element.node;
    A_SDisplayNodeAssert([node.supplementaryElementKind isEqualToString:elementKind], @"Expected node for supplementary element to have kind '%@', got '%@'.", elementKind, node.supplementaryElementKind);
    [_asyncDelegate collectionNode:collectionNode didEndDisplayingSupplementaryElementWithNode:node];
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldSelectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldSelectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldSelectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldSelectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidSelectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didSelectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidSelectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didSelectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldDeselectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldDeselectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldDeselectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldDeselectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidDeselectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didDeselectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidDeselectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didDeselectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldHighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldHighlightItemAtIndexPath:indexPath];
    } else {
      return YES;
    }
  } else if (_asyncDelegateFlags.collectionViewShouldHighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldHighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidHighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didHighlightItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidHighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didHighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidUnhighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didUnhighlightItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidUnhighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didUnhighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldShowMenuForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldShowMenuForItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldShowMenuForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldShowMenuForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(nonnull SEL)action forItemAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
  if (_asyncDelegateFlags.collectionNodeCanPerformActionForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode canPerformAction:action forItemAtIndexPath:indexPath sender:sender];
    }
  } else if (_asyncDelegateFlags.collectionViewCanPerformActionForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
#pragma clang diagnostic pop
  }
  return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(nonnull SEL)action forItemAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
  if (_asyncDelegateFlags.collectionNodePerformActionForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode performAction:action forItemAtIndexPath:indexPath sender:sender];
    }
  } else if (_asyncDelegateFlags.collectionViewPerformActionForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self performAction:action forItemAtIndexPath:indexPath withSender:sender];
#pragma clang diagnostic pop
  }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // If a scroll happenes the current range mode needs to go to full
  A_SInterfaceState interfaceState = [self interfaceStateForRangeController:_rangeController];
  if (A_SInterfaceStateIncludesVisible(interfaceState)) {
    [_rangeController updateCurrentRangeWithMode:A_SLayoutRangeModeFull];
    [self _checkForBatchFetching];
  }
  
  for (_A_SCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    // _cellsForVisibilityUpdates only includes cells for A_SCellNode subclasses with overrides of the visibility method.
    [cell cellNodeVisibilityEvent:A_SCellNodeVisibilityEventVisibleRectChanged inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewDidScroll) {
    [_asyncDelegate scrollViewDidScroll:scrollView];
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
  CGPoint contentOffset = scrollView.contentOffset;
  _deceleratingVelocity = CGPointMake(
    contentOffset.x - ((targetContentOffset != NULL) ? targetContentOffset->x : 0),
    contentOffset.y - ((targetContentOffset != NULL) ? targetContentOffset->y : 0)
  );

  if (targetContentOffset != NULL) {
    A_SDisplayNodeAssert(_batchContext != nil, @"Batch context should exist");
    [self _beginBatchFetchingIfNeededWithContentOffset:*targetContentOffset velocity:velocity];
  }
  
  if (_asyncDelegateFlags.scrollViewWillEndDragging) {
    [_asyncDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:(targetContentOffset ? : &contentOffset)];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  _deceleratingVelocity = CGPointZero;
    
  if (_asyncDelegateFlags.scrollViewDidEndDecelerating) {
    [_asyncDelegate scrollViewDidEndDecelerating:scrollView];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  for (_A_SCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    [cell cellNodeVisibilityEvent:A_SCellNodeVisibilityEventWillBeginDragging inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewWillBeginDragging) {
    [_asyncDelegate scrollViewWillBeginDragging:scrollView];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  for (_A_SCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    [cell cellNodeVisibilityEvent:A_SCellNodeVisibilityEventDidEndDragging inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewDidEndDragging) {
    [_asyncDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  }
}

#pragma mark - Scroll Direction.

- (BOOL)inverted
{
  return _inverted;
}

- (void)setInverted:(BOOL)inverted
{
  _inverted = inverted;
}

- (void)setLeadingScreensForBatching:(CGFloat)leadingScreensForBatching
{
  if (_leadingScreensForBatching != leadingScreensForBatching) {
    _leadingScreensForBatching = leadingScreensForBatching;
    A_SPerformBlockOnMainThread(^{
      [self _checkForBatchFetching];
    });
  }
}

- (CGFloat)leadingScreensForBatching
{
  return _leadingScreensForBatching;
}

- (A_SScrollDirection)scrollDirection
{
  CGPoint scrollVelocity;
  if (self.isTracking) {
    scrollVelocity = [self.panGestureRecognizer velocityInView:self.superview];
  } else {
    scrollVelocity = _deceleratingVelocity;
  }
  
  A_SScrollDirection scrollDirection = [self _scrollDirectionForVelocity:scrollVelocity];
  return A_SScrollDirectionApplyTransform(scrollDirection, self.transform);
}

- (A_SScrollDirection)_scrollDirectionForVelocity:(CGPoint)scrollVelocity
{
  A_SScrollDirection direction = A_SScrollDirectionNone;
  A_SScrollDirection scrollableDirections = [self scrollableDirections];
  
  if (A_SScrollDirectionContainsHorizontalDirection(scrollableDirections)) { // Can scroll horizontally.
    if (scrollVelocity.x < 0.0) {
      direction |= A_SScrollDirectionRight;
    } else if (scrollVelocity.x > 0.0) {
      direction |= A_SScrollDirectionLeft;
    }
  }
  if (A_SScrollDirectionContainsVerticalDirection(scrollableDirections)) { // Can scroll vertically.
    if (scrollVelocity.y < 0.0) {
      direction |= A_SScrollDirectionDown;
    } else if (scrollVelocity.y > 0.0) {
      direction |= A_SScrollDirectionUp;
    }
  }
  
  return direction;
}

- (A_SScrollDirection)scrollableDirections
{
  A_SDisplayNodeAssertNotNil(self.layoutInspector, @"Layout inspector should be assigned.");
  return [self.layoutInspector scrollableDirections];
}

- (void)layoutSubviews
{
  if (_cellsForLayoutUpdates.count > 0) {
    NSMutableArray<A_SCellNode *> *nodesSizesChanged = [NSMutableArray array];
    [_dataController relayoutNodes:_cellsForLayoutUpdates nodesSizeChanged:nodesSizesChanged];
    [self nodesDidRelayout:nodesSizesChanged];
  }
  [_cellsForLayoutUpdates removeAllObjects];

  // Flush any pending invalidation action if needed.
  A_SCollectionViewInvalidationStyle invalidationStyle = _nextLayoutInvalidationStyle;
  _nextLayoutInvalidationStyle = A_SCollectionViewInvalidationStyleNone;
  switch (invalidationStyle) {
    case A_SCollectionViewInvalidationStyleWithAnimation:
      if (0 == _superBatchUpdateCount) {
        [self _superPerformBatchUpdates:^{ } completion:nil];
      }
      break;
    case A_SCollectionViewInvalidationStyleWithoutAnimation:
      [self.collectionViewLayout invalidateLayout];
      break;
    default:
      break;
  }
  
  // To ensure _maxSizeForNodesConstrainedSize is up-to-date for every usage, this call to super must be done last
  [super layoutSubviews];
    
  if (_zeroContentInsets) {
    self.contentInset = UIEdgeInsetsZero;
  }
  
  // Update range controller immediately if possible & needed.
  // Calling -updateIfNeeded in here with self.window == nil (early in the collection view's life)
  // may cause UICollectionView data related crashes. We'll update in -didMoveToWindow anyway.
  if (self.window != nil) {
    [_rangeController updateIfNeeded];
  }
}


#pragma mark - Batch Fetching

- (A_SBatchContext *)batchContext
{
  return _batchContext;
}

- (BOOL)canBatchFetch
{
  // if the delegate does not respond to this method, there is no point in starting to fetch
  BOOL canFetch = _asyncDelegateFlags.collectionNodeWillBeginBatchFetch || _asyncDelegateFlags.collectionViewWillBeginBatchFetch;
  if (canFetch && _asyncDelegateFlags.shouldBatchFetchForCollectionNode) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    return [_asyncDelegate shouldBatchFetchForCollectionNode:collectionNode];
  } else if (canFetch && _asyncDelegateFlags.shouldBatchFetchForCollectionView) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate shouldBatchFetchForCollectionView:self];
#pragma clang diagnostic pop
  } else {
    return canFetch;
  }
}

- (id<A_SBatchFetchingDelegate>)batchFetchingDelegate{
  return self.collectionNode.batchFetchingDelegate;
}

- (void)_scheduleCheckForBatchFetchingForNumberOfChanges:(NSUInteger)changes
{
  // Prevent fetching will continually trigger in a loop after reaching end of content and no new content was provided
  if (changes == 0 && _hasEverCheckedForBatchFetchingDueToUpdate) {
    return;
  }
  _hasEverCheckedForBatchFetchingDueToUpdate = YES;
  
  // Push this to the next runloop to be sure the scroll view has the right content size
  dispatch_async(dispatch_get_main_queue(), ^{
    [self _checkForBatchFetching];
  });
}

- (void)_checkForBatchFetching
{
  // Dragging will be handled in scrollViewWillEndDragging:withVelocity:targetContentOffset:
  if (self.isDragging || self.isTracking) {
    return;
  }
  
  [self _beginBatchFetchingIfNeededWithContentOffset:self.contentOffset velocity:CGPointZero];
}

- (void)_beginBatchFetchingIfNeededWithContentOffset:(CGPoint)contentOffset velocity:(CGPoint)velocity
{
  if (A_SDisplayShouldFetchBatchForScrollView(self, self.scrollDirection, self.scrollableDirections, contentOffset, velocity)) {
    [self _beginBatchFetching];
  }
}

- (void)_beginBatchFetching
{
  as_activity_create_for_scope("Batch fetch for collection node");
  [_batchContext beginBatchFetching];
  if (_asyncDelegateFlags.collectionNodeWillBeginBatchFetch) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
      as_log_debug(A_SCollectionLog(), "Beginning batch fetch for %@ with context %@", collectionNode, _batchContext);
      [_asyncDelegate collectionNode:collectionNode willBeginBatchFetchWithContext:_batchContext];
    });
  } else if (_asyncDelegateFlags.collectionViewWillBeginBatchFetch) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      [_asyncDelegate collectionView:self willBeginBatchFetchWithContext:_batchContext];
#pragma clang diagnostic pop
    });
  }
}

#pragma mark - A_SDataControllerSource

- (id)dataController:(A_SDataController *)dataController nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_asyncDataSourceFlags.nodeModelForItem) {
    return nil;
  }

  GET_COLLECTIONNODE_OR_RETURN(collectionNode, nil);
  return [_asyncDataSource collectionNode:collectionNode nodeModelForItemAtIndexPath:indexPath];
}

- (A_SCellNodeBlock)dataController:(A_SDataController *)dataController nodeBlockAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_SCellNodeBlock block = nil;
  A_SCellNode *cell = nil;

  if (_asyncDataSourceFlags.collectionNodeNodeBlockForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[A_SCellNode alloc] init]; });
    block = [_asyncDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionNodeNodeForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[A_SCellNode alloc] init]; });
    cell = [_asyncDataSource collectionNode:collectionNode nodeForItemAtIndexPath:indexPath];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  } else if (_asyncDataSourceFlags.collectionViewNodeBlockForItem) {
    block = [_asyncDataSource collectionView:self nodeBlockForItemAtIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionViewNodeForItem) {
    cell = [_asyncDataSource collectionView:self nodeForItemAtIndexPath:indexPath];
  }
#pragma clang diagnostic pop

  // Handle nil node block or cell
  if (cell && [cell isKindOfClass:[A_SCellNode class]]) {
    block = ^{
      return cell;
    };
  }

  if (block == nil) {
    if (_asyncDataSourceFlags.interop) {
      CGSize preferredSize = [self _sizeForUIKitCellWithKind:nil atIndexPath:indexPath];
      block = ^{
        A_SCellNode *node = [[A_SCellNode alloc] init];
        node.shouldUseUIKitCell = YES;
        node.style.preferredSize = preferredSize;
        return node;
      };
    } else {
      A_SDisplayNodeFailAssert(@"A_SCollection could not get a node block for item at index path %@: %@, %@. If you are trying to display a UICollectionViewCell, make sure your dataSource conforms to the <A_SCollectionDataSourceInterop> protocol!", indexPath, cell, block);
      block = ^{
        return [[A_SCellNode alloc] init];
      };
    }
  }

  // Wrap the node block
  __weak __typeof__(self) weakSelf = self;
  return ^{
    __typeof__(self) strongSelf = weakSelf;
    A_SCellNode *node = (block != nil ? block() : [[A_SCellNode alloc] init]);
    [node enterHierarchyState:A_SHierarchyStateRangeManaged];
    if (node.interactionDelegate == nil) {
      node.interactionDelegate = strongSelf;
    }
    if (strongSelf.inverted) {
      node.transform = CATransform3DMakeScale(1, -1, 1) ;
    }
    return node;
  };
  return block;
}

- (NSUInteger)dataController:(A_SDataController *)dataController rowsInSection:(NSUInteger)section
{
  if (_asyncDataSourceFlags.collectionNodeNumberOfItemsInSection) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, 0);
    return [_asyncDataSource collectionNode:collectionNode numberOfItemsInSection:section];
  } else if (_asyncDataSourceFlags.collectionViewNumberOfItemsInSection) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDataSource collectionView:self numberOfItemsInSection:section];
#pragma clang diagnostic pop
  } else {
    return 0;
  }
}

- (NSUInteger)numberOfSectionsInDataController:(A_SDataController *)dataController {
  if (_asyncDataSourceFlags.numberOfSectionsInCollectionNode) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, 0);
    return [_asyncDataSource numberOfSectionsInCollectionNode:collectionNode];
  } else if (_asyncDataSourceFlags.numberOfSectionsInCollectionView) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDataSource numberOfSectionsInCollectionView:self];
#pragma clang diagnostic pop
  } else {
    return 1;
  }
}

- (BOOL)dataController:(A_SDataController *)dataController presentedSizeForElement:(A_SCollectionElement *)element matchesSize:(CGSize)size
{
  NSIndexPath *indexPath = [self indexPathForNode:element.node];
  if (indexPath == nil) {
    A_SDisplayNodeFailAssert(@"Data controller should not ask for presented size for element that is not presented.");
    return YES;
  }
  UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
  return CGSizeEqualToSizeWithIn(attributes.size, size, FLT_EPSILON);
}

#pragma mark - A_SDataControllerSource optional methods

- (A_SCellNodeBlock)dataController:(A_SDataController *)dataController supplementaryNodeBlockOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_SCellNodeBlock nodeBlock = nil;
  A_SCellNode *node = nil;
  if (_asyncDataSourceFlags.collectionNodeNodeBlockForSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[A_SCellNode alloc] init]; });
    nodeBlock = [_asyncDataSource collectionNode:collectionNode nodeBlockForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionNodeNodeForSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[A_SCellNode alloc] init]; });
    node = [_asyncDataSource collectionNode:collectionNode nodeForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionViewNodeForSupplementaryElement) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    node = [_asyncDataSource collectionView:self nodeForSupplementaryElementOfKind:kind atIndexPath:indexPath];
#pragma clang diagnostic pop
  }

  if (nodeBlock == nil) {
    if (node) {
      nodeBlock = ^{ return node; };
    } else {
      // In this case, the app code returned nil for the node and the nodeBlock.
      // If the UIKit method is implemented, then we should use it. Otherwise the CGSizeZero default will cause UIKit to not show it.
      CGSize preferredSize = CGSizeZero;
      BOOL useUIKitCell = _asyncDataSourceFlags.interopViewForSupplementaryElement;
      if (useUIKitCell) {
        preferredSize = [self _sizeForUIKitCellWithKind:kind atIndexPath:indexPath];
      }
      nodeBlock = ^{
        A_SCellNode *node = [[A_SCellNode alloc] init];
        node.shouldUseUIKitCell = useUIKitCell;
        node.style.preferredSize = preferredSize;
        return node;
      };
    }
  }

  return nodeBlock;
}

- (NSArray<NSString *> *)dataController:(A_SDataController *)dataController supplementaryNodeKindsInSections:(NSIndexSet *)sections
{
  if (_asyncDataSourceFlags.collectionNodeSupplementaryElementKindsInSection) {
    NSMutableSet *kinds = [NSMutableSet set];
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, @[]);
    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
      NSArray<NSString *> *kindsForSection = [_asyncDataSource collectionNode:collectionNode supplementaryElementKindsInSection:section];
      [kinds addObjectsFromArray:kindsForSection];
    }];
    return [kinds allObjects];
  } else {
    // TODO: Lock this
    return [_registeredSupplementaryKinds allObjects];
  }
}

- (A_SSizeRange)dataController:(A_SDataController *)dataController constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  return [self.layoutInspector collectionView:self constrainedSizeForNodeAtIndexPath:indexPath];
}

- (A_SSizeRange)dataController:(A_SDataController *)dataController constrainedSizeForSupplementaryNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (_layoutInspectorFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath) {
    return [self.layoutInspector collectionView:self constrainedSizeForSupplementaryNodeOfKind:kind atIndexPath:indexPath];
  }
  
  A_SDisplayNodeAssert(NO, @"To support supplementary nodes in A_SCollectionView, it must have a layoutInspector for layout inspection. (See A_SCollectionViewFlowLayoutInspector for an example.)");
  return A_SSizeRangeMake(CGSizeZero, CGSizeZero);
}

- (NSUInteger)dataController:(A_SDataController *)dataController supplementaryNodesOfKind:(NSString *)kind inSection:(NSUInteger)section
{
  if (_asyncDataSource == nil) {
    return 0;
  }
  
  if (_layoutInspectorFlags.supplementaryNodesOfKindInSection) {
    return [self.layoutInspector collectionView:self supplementaryNodesOfKind:kind inSection:section];
  }

  A_SDisplayNodeAssert(NO, @"To support supplementary nodes in A_SCollectionView, it must have a layoutInspector for layout inspection. (See A_SCollectionViewFlowLayoutInspector for an example.)");
  return 0;
}

- (id<A_SSectionContext>)dataController:(A_SDataController *)dataController contextForSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  id<A_SSectionContext> context = nil;
  
  if (_asyncDataSourceFlags.collectionNodeContextForSection) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, nil);
    context = [_asyncDataSource collectionNode:collectionNode contextForSection:section];
  }
  
  if (context != nil) {
    context.collectionView = self;
  }
  return context;
}

#pragma mark - A_SRangeControllerDataSource

- (A_SRangeController *)rangeController
{
  return _rangeController;
}

/// The UIKit version of this method is only available on iOS >= 9
- (NSArray<NSIndexPath *> *)asdk_indexPathsForVisibleSupplementaryElementsOfKind:(NSString *)kind
{
  if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
    return [self indexPathsForVisibleSupplementaryElementsOfKind:kind];
  }

  // iOS 8 workaround
  // We cannot use willDisplaySupplementaryView/didEndDisplayingSupplementaryView
  // because those methods send index paths for _deleted items_ (invalid index paths)
  [self layoutIfNeeded];
  NSArray<UICollectionViewLayoutAttributes *> *visibleAttributes = [self.collectionViewLayout layoutAttributesForElementsInRect:self.bounds];
  NSMutableArray *result = [NSMutableArray array];
  for (UICollectionViewLayoutAttributes *attributes in visibleAttributes) {
    if (attributes.representedElementCategory == UICollectionElementCategorySupplementaryView
        && [attributes.representedElementKind isEqualToString:kind]) {
      [result addObject:attributes.indexPath];
    }
  }
  return result;
}

- (NSHashTable<A_SCollectionElement *> *)visibleElementsForRangeController:(A_SRangeController *)rangeController
{
  return A_SPointerTableByFlatMapping(_visibleElements, id element, element);
}

- (A_SElementMap *)elementMapForRangeController:(A_SRangeController *)rangeController
{
  return _dataController.visibleMap;
}

- (A_SScrollDirection)scrollDirectionForRangeController:(A_SRangeController *)rangeController
{
  return self.scrollDirection;
}

- (A_SInterfaceState)interfaceStateForRangeController:(A_SRangeController *)rangeController
{
  return A_SInterfaceStateForDisplayNode(self.collectionNode, self.window);
}

- (NSString *)nameForRangeControllerDataSource
{
  return self.asyncDataSource ? NSStringFromClass([self.asyncDataSource class]) : NSStringFromClass([self class]);
}

#pragma mark - A_SRangeControllerDelegate

- (void)rangeController:(A_SRangeController *)rangeController updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet updates:(dispatch_block_t)updates
{
  A_SDisplayNodeAssertMainThread();
  if (!self.asyncDataSource || _superIsPendingDataLoad) {
    updates();
    [changeSet executeCompletionHandlerWithFinished:NO];
    return; // if the asyncDataSource has become invalid while we are processing, ignore this request to avoid crashes
  }

  //TODO Do we need to notify _layoutFacilitator before reloadData?
  for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeDelete]) {
    [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:change.indexPaths batched:YES];
  }

  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeDelete]) {
    [_layoutFacilitator collectionViewWillEditSectionsAtIndexSet:change.indexSet batched:YES];
  }

  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeInsert]) {
    [_layoutFacilitator collectionViewWillEditSectionsAtIndexSet:change.indexSet batched:YES];
  }

  for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeInsert]) {
    [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:change.indexPaths batched:YES];
  }

  A_SPerformBlockWithoutAnimation(!changeSet.animated, ^{
    as_activity_scope(as_activity_create("Commit collection update", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
    if (changeSet.includesReloadData) {
      _superIsPendingDataLoad = YES;
      updates();
      [super reloadData];
      as_log_debug(A_SCollectionLog(), "Did reloadData %@", self.collectionNode);
      [changeSet executeCompletionHandlerWithFinished:YES];
    } else {
      [_layoutFacilitator collectionViewWillPerformBatchUpdates];
      
      __block NSUInteger numberOfUpdates = 0;
      [self _superPerformBatchUpdates:^{
        updates();

        for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeReload]) {
          [super reloadItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
        
        for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeReload]) {
          [super reloadSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeOriginalDelete]) {
          [super deleteItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
        
        for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeOriginalDelete]) {
          [super deleteSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeOriginalInsert]) {
          [super insertSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeOriginalInsert]) {
          [super insertItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
      } completion:^(BOOL finished){
        as_activity_scope(as_activity_create("Handle collection update completion", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
        as_log_verbose(A_SCollectionLog(), "Update animation finished %{public}@", self.collectionNode);
        // Flush any range changes that happened as part of the update animations ending.
        [_rangeController updateIfNeeded];
        [self _scheduleCheckForBatchFetchingForNumberOfChanges:numberOfUpdates];
        [changeSet executeCompletionHandlerWithFinished:finished];
      }];
      as_log_debug(A_SCollectionLog(), "Completed batch update %{public}@", self.collectionNode);
      
      // Flush any range changes that happened as part of submitting the update.
      as_activity_scope(changeSet.rootActivity);
      [_rangeController updateIfNeeded];
    }
  });
}

#pragma mark - A_SCellNodeDelegate

- (void)nodeSelectedStateDidChange:(A_SCellNode *)node
{
  NSIndexPath *indexPath = [self indexPathForNode:node];
  if (indexPath) {
    if (node.isSelected) {
      [super selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
      [super deselectItemAtIndexPath:indexPath animated:NO];
    }
  }
}

- (void)nodeHighlightedStateDidChange:(A_SCellNode *)node
{
  NSIndexPath *indexPath = [self indexPathForNode:node];
  if (indexPath) {
    [self cellForItemAtIndexPath:indexPath].highlighted = node.isHighlighted;
  }
}

- (void)nodeDidInvalidateSize:(A_SCellNode *)node
{
  [_cellsForLayoutUpdates addObject:node];
  [self setNeedsLayout];
}

- (void)nodesDidRelayout:(NSArray<A_SCellNode *> *)nodes
{
  A_SDisplayNodeAssertMainThread();
  
  if (nodes.count == 0) {
    return;
  }

  NSMutableArray<NSIndexPath *> *uikitIndexPaths = [NSMutableArray arrayWithCapacity:nodes.count];
  for (A_SCellNode *node in nodes) {
    NSIndexPath *uikitIndexPath = [self indexPathForNode:node];
    if (uikitIndexPath != nil) {
      [uikitIndexPaths addObject:uikitIndexPath];
    }
  }
  
  [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:uikitIndexPaths batched:NO];
  
  A_SCollectionViewInvalidationStyle invalidationStyle = _nextLayoutInvalidationStyle;
  for (A_SCellNode *node in nodes) {
    if (invalidationStyle == A_SCollectionViewInvalidationStyleNone) {
      // We nodesDidRelayout also while we are in layoutSubviews. This should be no problem as CA will ignore this
      // call while be in a layout pass
      [self setNeedsLayout];
      invalidationStyle = A_SCollectionViewInvalidationStyleWithAnimation;
    }
    
    // If we think we're going to animate, check if this node will prevent it.
    if (invalidationStyle == A_SCollectionViewInvalidationStyleWithAnimation) {
      // TODO: Incorporate `shouldAnimateSizeChanges` into A_SEnvironmentState for performance benefit.
      static dispatch_once_t onceToken;
      static BOOL (^shouldNotAnimateBlock)(A_SDisplayNode *);
      dispatch_once(&onceToken, ^{
        shouldNotAnimateBlock = ^BOOL(A_SDisplayNode * _Nonnull node) {
          return (node.shouldAnimateSizeChanges == NO);
        };
      });
      if (A_SDisplayNodeFindFirstNode(node, shouldNotAnimateBlock) != nil) {
        // One single non-animated node causes the whole layout update to be non-animated
        invalidationStyle = A_SCollectionViewInvalidationStyleWithoutAnimation;
        break;
      }
    }
  }
  _nextLayoutInvalidationStyle = invalidationStyle;
}

#pragma mark - _A_SDisplayView behavior substitutions
// Need these to drive interfaceState so we know when we are visible, if not nested in another range-managing element.
// Because our superclass is a true UIKit class, we cannot also subclass _A_SDisplayView.
- (void)willMoveToWindow:(UIWindow *)newWindow
{
  BOOL visible = (newWindow != nil);
  A_SDisplayNode *node = self.collectionNode;
  if (visible && !node.inHierarchy) {
    [node __enterHierarchy];
  }
}

- (void)didMoveToWindow
{
  BOOL visible = (self.window != nil);
  A_SDisplayNode *node = self.collectionNode;
  if (!visible && node.inHierarchy) {
    [node __exitHierarchy];
  }

  // Updating the visible node index paths only for not range managed nodes. Range managed nodes will get their
  // their update in the layout pass
  if (![node supportsRangeManagedInterfaceState]) {
    [_rangeController setNeedsUpdate];
    [_rangeController updateIfNeeded];
  }

  // When we aren't visible, we will only fetch up to the visible area. Now that we are visible,
  // we will fetch visible area + leading screens, so we need to check.
  if (visible) {
    [self _checkForBatchFetching];
  }
}

#pragma mark A_SCALayerExtendedDelegate

/**
 * TODO: This code was added when we used @c calculatedSize as the size for 
 * items (e.g. collectionView:layout:sizeForItemAtIndexPath:) and so it
 * was critical that we remeasured all nodes at this time.
 *
 * The assumption was that cv-bounds-size-change -> constrained-size-change, so
 * this was the time when we get new constrained sizes for all items and remeasure
 * them. However, the constrained sizes for items can be invalidated for many other
 * reasons, hence why we never reuse the old constrained size anymore.
 *
 * UICollectionView inadvertently triggers a -prepareLayout call to its layout object
 * between [super setFrame:] and [self layoutSubviews] during size changes. So we need
 * to get in there and re-measure our nodes before that -prepareLayout call.
 * We can't wait until -layoutSubviews or the end of -setFrame:.
 *
 * @see @p testThatNodeCalculatedSizesAreUpdatedBeforeFirstPrepareLayoutAfterRotation
 */
- (void)layer:(CALayer *)layer didChangeBoundsWithOldValue:(CGRect)oldBounds newValue:(CGRect)newBounds
{
  CGSize newSize = newBounds.size;
  CGSize lastUsedSize = _lastBoundsSizeUsedForMeasuringNodes;
  if (CGSizeEqualToSize(lastUsedSize, newSize)) {
    return;
  }
  if (_hasDataControllerLayoutDelegate || self.collectionViewLayout == nil) {
    // Let the layout delegate handle bounds changes if it's available. If no layout, it will init in the new state.
    return;
  }

  _lastBoundsSizeUsedForMeasuringNodes = newSize;

  // Laying out all nodes is expensive.
  // We only need to do this if the bounds changed in the non-scrollable direction.
  // If, for example, a vertical flow layout has its height changed due to a status bar
  // appearance update, we do not need to relayout all nodes.
  // For a more permanent fix to the unsafety mentioned above, see https://github.com/facebook/Async_DisplayKit/pull/2182
  A_SScrollDirection scrollDirection = self.scrollableDirections;
  BOOL fixedVertically   = (A_SScrollDirectionContainsVerticalDirection  (scrollDirection) == NO);
  BOOL fixedHorizontally = (A_SScrollDirectionContainsHorizontalDirection(scrollDirection) == NO);

  BOOL changedInNonScrollingDirection = (fixedHorizontally && newSize.width  != lastUsedSize.width) ||
                                        (fixedVertically   && newSize.height != lastUsedSize.height);

  if (changedInNonScrollingDirection) {
    [self relayoutItems];
  }
}

#pragma mark - UICollectionView dead-end intercepts

- (void)setPrefetchDataSource:(id<UICollectionViewDataSourcePrefetching>)prefetchDataSource
{
  return;
}

- (void)setPrefetchingEnabled:(BOOL)prefetchingEnabled
{
  return;
}

#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED // Remove implementations entirely for efficiency if not asserting.

// intercepted due to not being supported by A_SCollectionView (prevent bugs caused by usage)

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(9_0)
{
  A_SDisplayNodeAssert(![self.asyncDataSource respondsToSelector:_cmd], @"%@ is not supported by A_SCollectionView - please remove or disable this data source method.", NSStringFromSelector(_cmd));
  return NO;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath*)destinationIndexPath NS_AVAILABLE_IOS(9_0)
{
  A_SDisplayNodeAssert(![self.asyncDataSource respondsToSelector:_cmd], @"%@ is not supported by A_SCollectionView - please remove or disable this data source method.", NSStringFromSelector(_cmd));
}

#endif

@end
