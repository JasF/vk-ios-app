//
//  A_SDataController.mm
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

#import <Async_DisplayKit/A_SDataController.h>

#import <Async_DisplayKit/_A_SHierarchyChangeSet.h>
#import <Async_DisplayKit/_A_SScopeTimer.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext.h>
#import <Async_DisplayKit/A_SDispatch.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SSignpost.h>
#import <Async_DisplayKit/A_SMainSerialQueue.h>
#import <Async_DisplayKit/A_SMutableElementMap.h>
#import <Async_DisplayKit/A_SRangeManagingNode.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_STwoDimensionalArrayUtils.h>
#import <Async_DisplayKit/A_SSection.h>

#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/NSIndexSet+A_SHelpers.h>

//#define LOG(...) NSLog(__VA_ARGS__)
#define LOG(...)

#define A_SSERT_ON_EDITING_QUEUE A_SDisplayNodeAssertNotNil(dispatch_get_specific(&kA_SDataControllerEditingQueueKey), @"%@ must be called on the editing transaction queue.", NSStringFromSelector(_cmd))

const static char * kA_SDataControllerEditingQueueKey = "kA_SDataControllerEditingQueueKey";
const static char * kA_SDataControllerEditingQueueContext = "kA_SDataControllerEditingQueueContext";

NSString * const A_SDataControllerRowNodeKind = @"_A_SDataControllerRowNodeKind";
NSString * const A_SCollectionInvalidUpdateException = @"A_SCollectionInvalidUpdateException";

typedef dispatch_block_t A_SDataControllerCompletionBlock;

@interface A_SDataController () {
  id<A_SDataControllerLayoutDelegate> _layoutDelegate;

  NSInteger _nextSectionID;
  
  BOOL _itemCountsFromDataSourceAreValid;     // Main thread only.
  std::vector<NSInteger> _itemCountsFromDataSource;         // Main thread only.
  
  A_SMainSerialQueue *_mainSerialQueue;

  dispatch_queue_t _editingTransactionQueue;  // Serial background queue.  Dispatches concurrent layout and manages _editingNodes.
  dispatch_group_t _editingTransactionGroup;     // Group of all edit transaction blocks. Useful for waiting.
  
  BOOL _initialReloadDataHasBeenCalled;

  struct {
    unsigned int supplementaryNodeKindsInSections:1;
    unsigned int supplementaryNodesOfKindInSection:1;
    unsigned int supplementaryNodeBlockOfKindAtIndexPath:1;
    unsigned int constrainedSizeForNodeAtIndexPath:1;
    unsigned int constrainedSizeForSupplementaryNodeOfKindAtIndexPath:1;
    unsigned int contextForSection:1;
  } _dataSourceFlags;
}

@property (atomic, copy, readwrite) A_SElementMap *pendingMap;
@property (atomic, copy, readwrite) A_SElementMap *visibleMap;
@end

@implementation A_SDataController

#pragma mark - Lifecycle

- (instancetype)initWithDataSource:(id<A_SDataControllerSource>)dataSource node:(nullable id<A_SRangeManagingNode>)node eventLog:(A_SEventLog *)eventLog
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _node = node;
  _dataSource = dataSource;
  
  _dataSourceFlags.supplementaryNodeKindsInSections = [_dataSource respondsToSelector:@selector(dataController:supplementaryNodeKindsInSections:)];
  _dataSourceFlags.supplementaryNodesOfKindInSection = [_dataSource respondsToSelector:@selector(dataController:supplementaryNodesOfKind:inSection:)];
  _dataSourceFlags.supplementaryNodeBlockOfKindAtIndexPath = [_dataSource respondsToSelector:@selector(dataController:supplementaryNodeBlockOfKind:atIndexPath:)];
  _dataSourceFlags.constrainedSizeForNodeAtIndexPath = [_dataSource respondsToSelector:@selector(dataController:constrainedSizeForNodeAtIndexPath:)];
  _dataSourceFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath = [_dataSource respondsToSelector:@selector(dataController:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:)];
  _dataSourceFlags.contextForSection = [_dataSource respondsToSelector:@selector(dataController:contextForSection:)];
  
#if A_SEVENTLOG_ENABLE
  _eventLog = eventLog;
#endif

  self.visibleMap = self.pendingMap = [[A_SElementMap alloc] init];
  
  _nextSectionID = 0;
  
  _mainSerialQueue = [[A_SMainSerialQueue alloc] init];
  
  const char *queueName = [[NSString stringWithFormat:@"org.Async_DisplayKit.A_SDataController.editingTransactionQueue:%p", self] cStringUsingEncoding:NSASCIIStringEncoding];
  _editingTransactionQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL);
  dispatch_queue_set_specific(_editingTransactionQueue, &kA_SDataControllerEditingQueueKey, &kA_SDataControllerEditingQueueContext, NULL);
  _editingTransactionGroup = dispatch_group_create();
  
  return self;
}

- (id<A_SDataControllerLayoutDelegate>)layoutDelegate
{
  A_SDisplayNodeAssertMainThread();
  return _layoutDelegate;
}

- (void)setLayoutDelegate:(id<A_SDataControllerLayoutDelegate>)layoutDelegate
{
  A_SDisplayNodeAssertMainThread();
  if (layoutDelegate != _layoutDelegate) {
    _layoutDelegate = layoutDelegate;
  }
}

#pragma mark - Cell Layout

- (void)_allocateNodesFromElements:(NSArray<A_SCollectionElement *> *)elements completion:(A_SDataControllerCompletionBlock)completionHandler
{
  A_SSERT_ON_EDITING_QUEUE;
  
  NSUInteger nodeCount = elements.count;
  __weak id<A_SDataControllerSource> weakDataSource = _dataSource;
  if (nodeCount == 0 || weakDataSource == nil) {
    completionHandler();
    return;
  }

  A_SSignpostStart(A_SSignpostDataControllerBatch);

  {
    as_activity_create_for_scope("Data controller batch");

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    A_SDispatchApply(nodeCount, queue, 0, ^(size_t i) {
      __strong id<A_SDataControllerSource> strongDataSource = weakDataSource;
      if (strongDataSource == nil) {
        return;
      }

      // Allocate the node.
      A_SCollectionElement *context = elements[i];
      A_SCellNode *node = context.node;
      if (node == nil) {
        A_SDisplayNodeAssertNotNil(node, @"Node block created nil node; %@, %@", self, strongDataSource);
        node = [[A_SCellNode alloc] init]; // Fallback to avoid crash for production apps.
      }

      // Layout the node if the size range is valid.
      A_SSizeRange sizeRange = context.constrainedSize;
      if (A_SSizeRangeHasSignificantArea(sizeRange)) {
        [self _layoutNode:node withConstrainedSize:sizeRange];
      }
    });
  }

  completionHandler();
  A_SSignpostEndCustom(A_SSignpostDataControllerBatch, self, 0, (weakDataSource != nil ? A_SSignpostColorDefault : A_SSignpostColorRed));
}

/**
 * Measure and layout the given node with the constrained size range.
 */
- (void)_layoutNode:(A_SCellNode *)node withConstrainedSize:(A_SSizeRange)constrainedSize
{
  A_SDisplayNodeAssert(A_SSizeRangeHasSignificantArea(constrainedSize), @"Attempt to layout cell node with invalid size range %@", NSStringFromA_SSizeRange(constrainedSize));

  CGRect frame = CGRectZero;
  frame.size = [node layoutThatFits:constrainedSize].size;
  node.frame = frame;
}

#pragma mark - Data Source Access (Calling _dataSource)

- (NSArray<NSIndexPath *> *)_allIndexPathsForItemsOfKind:(NSString *)kind inSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  
  if (sections.count == 0 || _dataSource == nil) {
    return @[];
  }
  
  NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
  if ([kind isEqualToString:A_SDataControllerRowNodeKind]) {
    std::vector<NSInteger> counts = [self itemCountsFromDataSource];
    [sections enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
      for (NSUInteger sectionIndex = range.location; sectionIndex < NSMaxRange(range); sectionIndex++) {
        NSUInteger itemCount = counts[sectionIndex];
        for (NSUInteger i = 0; i < itemCount; i++) {
          [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
        }
      }
    }];
  } else if (_dataSourceFlags.supplementaryNodesOfKindInSection) {
    id<A_SDataControllerSource> dataSource = _dataSource;
    [sections enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
      for (NSUInteger sectionIndex = range.location; sectionIndex < NSMaxRange(range); sectionIndex++) {
        NSUInteger itemCount = [dataSource dataController:self supplementaryNodesOfKind:kind inSection:sectionIndex];
        for (NSUInteger i = 0; i < itemCount; i++) {
          [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
        }
      }
    }];
  }
  
  return indexPaths;
}

/**
 * Agressively repopulates supplementary nodes of all kinds for sections that contains some given index paths.
 *
 * @param map The element map into which to apply the change.
 * @param indexPaths The index paths belongs to sections whose supplementary nodes need to be repopulated.
 * @param changeSet The changeset that triggered this repopulation.
 * @param traitCollection The trait collection needed to initialize elements
 * @param indexPathsAreNew YES if index paths are "after the update," NO otherwise.
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_repopulateSupplementaryNodesIntoMap:(A_SMutableElementMap *)map
             forSectionsContainingIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                   changeSet:(_A_SHierarchyChangeSet *)changeSet
                             traitCollection:(A_SPrimitiveTraitCollection)traitCollection
                            indexPathsAreNew:(BOOL)indexPathsAreNew
                       shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                                 previousMap:(A_SElementMap *)previousMap
{
  A_SDisplayNodeAssertMainThread();

  if (indexPaths.count ==  0) {
    return;
  }

  // Remove all old supplementaries from these sections
  NSIndexSet *oldSections = [NSIndexSet as_sectionsFromIndexPaths:indexPaths];

  // Add in new ones with the new kinds.
  NSIndexSet *newSections;
  if (indexPathsAreNew) {
    newSections = oldSections;
  } else {
    newSections = [oldSections as_indexesByMapping:^NSUInteger(NSUInteger oldSection) {
      return [changeSet newSectionForOldSection:oldSection];
    }];
  }

  for (NSString *kind in [self supplementaryKindsInSections:newSections]) {
    [self _insertElementsIntoMap:map kind:kind forSections:newSections traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
  }
}

/**
 * Inserts new elements of a certain kind for some sections
 *
 * @param kind The kind of the elements, e.g A_SDataControllerRowNodeKind
 * @param sections The sections that should be populated by new elements
 * @param traitCollection The trait collection needed to initialize elements
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_insertElementsIntoMap:(A_SMutableElementMap *)map
                          kind:(NSString *)kind
                   forSections:(NSIndexSet *)sections
               traitCollection:(A_SPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_A_SHierarchyChangeSet *)changeSet
                   previousMap:(A_SElementMap *)previousMap
{
  A_SDisplayNodeAssertMainThread();
  
  if (sections.count == 0 || _dataSource == nil) {
    return;
  }
  
  NSArray<NSIndexPath *> *indexPaths = [self _allIndexPathsForItemsOfKind:kind inSections:sections];
  [self _insertElementsIntoMap:map kind:kind atIndexPaths:indexPaths traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
}

/**
 * Inserts new elements of a certain kind at some index paths
 *
 * @param map The map to insert the elements into.
 * @param kind The kind of the elements, e.g A_SDataControllerRowNodeKind
 * @param indexPaths The index paths at which new elements should be populated
 * @param traitCollection The trait collection needed to initialize elements
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_insertElementsIntoMap:(A_SMutableElementMap *)map
                          kind:(NSString *)kind
                  atIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
               traitCollection:(A_SPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_A_SHierarchyChangeSet *)changeSet
                   previousMap:(A_SElementMap *)previousMap
{
  A_SDisplayNodeAssertMainThread();
  
  if (indexPaths.count == 0 || _dataSource == nil) {
    return;
  }
  
  BOOL isRowKind = [kind isEqualToString:A_SDataControllerRowNodeKind];
  if (!isRowKind && !_dataSourceFlags.supplementaryNodeBlockOfKindAtIndexPath) {
    // Populating supplementary elements but data source doesn't support.
    return;
  }
  
  LOG(@"Populating elements of kind: %@, for index paths: %@", kind, indexPaths);
  id<A_SDataControllerSource> dataSource = self.dataSource;
  id<A_SRangeManagingNode> node = self.node;
  for (NSIndexPath *indexPath in indexPaths) {
    A_SCellNodeBlock nodeBlock;
    id nodeModel;
    if (isRowKind) {
      nodeModel = [dataSource dataController:self nodeModelForItemAtIndexPath:indexPath];
      
      // Get the prior element and attempt to update the existing cell node.
      if (nodeModel != nil && !changeSet.includesReloadData) {
        NSIndexPath *oldIndexPath = [changeSet oldIndexPathForNewIndexPath:indexPath];
        if (oldIndexPath != nil) {
          A_SCollectionElement *oldElement = [previousMap elementForItemAtIndexPath:oldIndexPath];
          A_SCellNode *oldNode = oldElement.node;
          if ([oldNode canUpdateToNodeModel:nodeModel]) {
            // Just wrap the node in a block. The collection element will -setNodeModel:
            nodeBlock = ^{
              return oldNode;
            };
          }
        }
      }
      if (nodeBlock == nil) {
        nodeBlock = [dataSource dataController:self nodeBlockAtIndexPath:indexPath];
      }
    } else {
      nodeBlock = [dataSource dataController:self supplementaryNodeBlockOfKind:kind atIndexPath:indexPath];
    }
    
    A_SSizeRange constrainedSize = A_SSizeRangeUnconstrained;
    if (shouldFetchSizeRanges) {
      constrainedSize = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPath];
    }
    
    A_SCollectionElement *element = [[A_SCollectionElement alloc] initWithNodeModel:nodeModel
                                                                        nodeBlock:nodeBlock
                                                         supplementaryElementKind:isRowKind ? nil : kind
                                                                  constrainedSize:constrainedSize
                                                                       owningNode:node
                                                                  traitCollection:traitCollection];
    [map insertElement:element atIndexPath:indexPath];
  }
}

- (void)invalidateDataSourceItemCounts
{
  A_SDisplayNodeAssertMainThread();
  _itemCountsFromDataSourceAreValid = NO;
}

- (std::vector<NSInteger>)itemCountsFromDataSource
{
  A_SDisplayNodeAssertMainThread();
  if (NO == _itemCountsFromDataSourceAreValid) {
    id<A_SDataControllerSource> source = self.dataSource;
    NSInteger sectionCount = [source numberOfSectionsInDataController:self];
    std::vector<NSInteger> newCounts;
    newCounts.reserve(sectionCount);
    for (NSInteger i = 0; i < sectionCount; i++) {
      newCounts.push_back([source dataController:self rowsInSection:i]);
    }
    _itemCountsFromDataSource = newCounts;
    _itemCountsFromDataSourceAreValid = YES;
  }
  return _itemCountsFromDataSource;
}

- (NSArray<NSString *> *)supplementaryKindsInSections:(NSIndexSet *)sections
{
  if (_dataSourceFlags.supplementaryNodeKindsInSections) {
    return [_dataSource dataController:self supplementaryNodeKindsInSections:sections];
  }
  
  return @[];
}

/**
 * Returns constrained size for the node of the given kind and at the given index path.
 * NOTE: index path must be in the data-source index space.
 */
- (A_SSizeRange)constrainedSizeForNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  
  id<A_SDataControllerSource> dataSource = _dataSource;
  if (dataSource == nil || indexPath == nil) {
    return A_SSizeRangeZero;
  }
  
  if ([kind isEqualToString:A_SDataControllerRowNodeKind]) {
    A_SDisplayNodeAssert(_dataSourceFlags.constrainedSizeForNodeAtIndexPath, @"-dataController:constrainedSizeForNodeAtIndexPath: must also be implemented");
    return [dataSource dataController:self constrainedSizeForNodeAtIndexPath:indexPath];
  }
  
  if (_dataSourceFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath){
    return [dataSource dataController:self constrainedSizeForSupplementaryNodeOfKind:kind atIndexPath:indexPath];
  }
  
  A_SDisplayNodeAssert(NO, @"Unknown constrained size for node of kind %@ by data source %@", kind, dataSource);
  return A_SSizeRangeZero;
}

#pragma mark - Batching (External API)

- (void)waitUntilAllUpdatesAreProcessed
{
  // Schedule block in main serial queue to wait until all operations are finished that are
  // where scheduled while waiting for the _editingTransactionQueue to finish
  [self _scheduleBlockOnMainSerialQueue:^{ }];
}

- (BOOL)isProcessingUpdates
{
  A_SDisplayNodeAssertMainThread();
  if (_mainSerialQueue.numberOfScheduledBlocks > 0) {
    return YES;
  } else if (dispatch_group_wait(_editingTransactionGroup, DISPATCH_TIME_NOW) != 0) {
    // After waiting for zero duration, a nonzero value is returned if blocks are still running.
    return YES;
  }
  // Both the _mainSerialQueue and _editingTransactionQueue are drained; we are fully quiesced.
  return NO;
}

- (void)onDidFinishProcessingUpdates:(nullable void (^)())completion
{
  A_SDisplayNodeAssertMainThread();
  if ([self isProcessingUpdates] == NO) {
    A_SPerformBlockOnMainThread(completion);
  } else {
    dispatch_async(_editingTransactionQueue, ^{
      // Retry the block. If we're done processing updates, it'll run immediately, otherwise
      // wait again for updates to quiesce completely.
      [_mainSerialQueue performBlockOnMainThread:^{
        [self onDidFinishProcessingUpdates:completion];
      }];
    });
  }
}

- (void)updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet
{
  A_SDisplayNodeAssertMainThread();
  
  if (changeSet.includesReloadData) {
    if (_initialReloadDataHasBeenCalled) {
      as_log_debug(A_SCollectionLog(), "reloadData %@", A_SViewToDisplayNode(A_SDynamicCast(self.dataSource, UIView)));
    } else {
      as_log_debug(A_SCollectionLog(), "Initial reloadData %@", A_SViewToDisplayNode(A_SDynamicCast(self.dataSource, UIView)));
      _initialReloadDataHasBeenCalled = YES;
    }
  } else {
    as_log_debug(A_SCollectionLog(), "performBatchUpdates %@ %@", A_SViewToDisplayNode(A_SDynamicCast(self.dataSource, UIView)), changeSet);
  }
  
  NSTimeInterval transactionQueueFlushDuration = 0.0f;
  {
    A_SDN::ScopeTimer t(transactionQueueFlushDuration);
    dispatch_group_wait(_editingTransactionGroup, DISPATCH_TIME_FOREVER);
  }
  
  // If the initial reloadData has not been called, just bail because we don't have our old data source counts.
  // See A_SUICollectionViewTests.testThatIssuingAnUpdateBeforeInitialReloadIsUnacceptable
  // for the issue that UICollectionView has that we're choosing to workaround.
  if (!_initialReloadDataHasBeenCalled) {
    as_log_debug(A_SCollectionLog(), "%@ Skipped update because load hasn't happened.", A_SObjectDescriptionMakeTiny(_dataSource));
    [changeSet executeCompletionHandlerWithFinished:YES];
    return;
  }
  
  [self invalidateDataSourceItemCounts];
  
  // Log events
#if A_SEVENTLOG_ENABLE
  A_SDataControllerLogEvent(self, @"updateWithChangeSet waited on previous update for %fms. changeSet: %@",
                           transactionQueueFlushDuration * 1000.0f, changeSet);
  NSTimeInterval changeSetStartTime = CACurrentMediaTime();
  NSString *changeSetDescription = A_SObjectDescriptionMakeTiny(changeSet);
  [changeSet addCompletionHandler:^(BOOL finished) {
    A_SDataControllerLogEvent(self, @"finishedUpdate in %fms: %@",
                             (CACurrentMediaTime() - changeSetStartTime) * 1000.0f, changeSetDescription);
  }];
#endif
  
  // Attempt to mark the update completed. This is when update validation will occur inside the changeset.
  // If an invalid update exception is thrown, we catch it and inject our "validationErrorSource" object,
  // which is the table/collection node's data source, into the exception reason to help debugging.
  @try {
    [changeSet markCompletedWithNewItemCounts:[self itemCountsFromDataSource]];
  } @catch (NSException *e) {
    id responsibleDataSource = self.validationErrorSource;
    if (e.name == A_SCollectionInvalidUpdateException && responsibleDataSource != nil) {
      [NSException raise:A_SCollectionInvalidUpdateException format:@"%@: %@", [responsibleDataSource class], e.reason];
    } else {
      @throw e;
    }
  }

  BOOL canDelegate = (self.layoutDelegate != nil);
  A_SElementMap *newMap;
  id layoutContext;
  {
    as_activity_scope(as_activity_create("Latch new data for collection update", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));

    // Step 1: Populate a new map that reflects the data source's state and use it as pendingMap
    A_SElementMap *previousMap = self.pendingMap;
    if (changeSet.isEmpty) {
      // If the change set is empty, nothing has changed so we can just reuse the previous map
      newMap = previousMap;
    } else {
      // Mutable copy of current data.
      A_SMutableElementMap *mutableMap = [previousMap mutableCopy];

      // Step 1.1: Update the mutable copies to match the data source's state
      [self _updateSectionsInMap:mutableMap changeSet:changeSet];
      A_SPrimitiveTraitCollection existingTraitCollection = [self.node primitiveTraitCollection];
      [self _updateElementsInMap:mutableMap changeSet:changeSet traitCollection:existingTraitCollection shouldFetchSizeRanges:(! canDelegate) previousMap:previousMap];

      // Step 1.2: Clone the new data
      newMap = [mutableMap copy];
    }
    self.pendingMap = newMap;

    // Step 2: Ask layout delegate for contexts
    if (canDelegate) {
      layoutContext = [self.layoutDelegate layoutContextWithElements:newMap];
    }
  }

  as_log_debug(A_SCollectionLog(), "New content: %@", newMap.smallDescription);

  Class<A_SDataControllerLayoutDelegate> layoutDelegateClass = [self.layoutDelegate class];
  dispatch_group_async(_editingTransactionGroup, _editingTransactionQueue, ^{
    __block __unused os_activity_scope_state_s preparationScope = {}; // unused if deployment target < iOS10
    as_activity_scope_enter(as_activity_create("Prepare nodes for collection update", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT), &preparationScope);

    dispatch_block_t completion = ^() {
      [_mainSerialQueue performBlockOnMainThread:^{
        as_activity_scope_leave(&preparationScope);
        // Step 4: Inform the delegate
        [_delegate dataController:self updateWithChangeSet:changeSet updates:^{
          // Step 5: Deploy the new data as "completed"
          //
          // Note that since the backing collection view might be busy responding to user events (e.g scrolling),
          // it will not consume the batch update blocks immediately.
          // As a result, in a short intermidate time, the view will still be relying on the old data source state.
          // Thus, we can't just swap the new map immediately before step 4, but until this update block is executed.
          // (https://github.com/Tex_tureGroup/Tex_ture/issues/378)
          self.visibleMap = newMap;
        }];
      }];
    };

    // Step 3: Call the layout delegate if possible. Otherwise, allocate and layout all elements
    if (canDelegate) {
      [layoutDelegateClass calculateLayoutWithContext:layoutContext];
      completion();
    } else {
      NSArray<A_SCollectionElement *> *elementsToProcess = A_SArrayByFlatMapping(newMap,
                                                                               A_SCollectionElement *element,
                                                                               (element.nodeIfAllocated.calculatedLayout == nil ? element : nil));
      [self _allocateNodesFromElements:elementsToProcess completion:completion];
    }
  });
  
  if (_usesSynchronousDataLoading) {
    [self waitUntilAllUpdatesAreProcessed];
  }
}

/**
 * Update sections based on the given change set.
 */
- (void)_updateSectionsInMap:(A_SMutableElementMap *)map changeSet:(_A_SHierarchyChangeSet *)changeSet
{
  A_SDisplayNodeAssertMainThread();
  
  if (changeSet.includesReloadData) {
    [map removeAllSections];
    
    NSUInteger sectionCount = [self itemCountsFromDataSource].size();
    NSIndexSet *sectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
    [self _insertSectionsIntoMap:map indexes:sectionIndexes];
    // Return immediately because reloadData can't be used in conjuntion with other updates.
    return;
  }
  
  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeDelete]) {
    [map removeSectionsAtIndexes:change.indexSet];
  }
  
  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeInsert]) {
    [self _insertSectionsIntoMap:map indexes:change.indexSet];
  }
}

- (void)_insertSectionsIntoMap:(A_SMutableElementMap *)map indexes:(NSIndexSet *)sectionIndexes
{
  A_SDisplayNodeAssertMainThread();

  [sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
    id<A_SSectionContext> context;
    if (_dataSourceFlags.contextForSection) {
      context = [_dataSource dataController:self contextForSection:idx];
    }
    A_SSection *section = [[A_SSection alloc] initWithSectionID:_nextSectionID context:context];
    [map insertSection:section atIndex:idx];
    _nextSectionID++;
  }];
}

/**
 * Update elements based on the given change set.
 */
- (void)_updateElementsInMap:(A_SMutableElementMap *)map
                   changeSet:(_A_SHierarchyChangeSet *)changeSet
             traitCollection:(A_SPrimitiveTraitCollection)traitCollection
       shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                 previousMap:(A_SElementMap *)previousMap
{
  A_SDisplayNodeAssertMainThread();

  if (changeSet.includesReloadData) {
    [map removeAllElements];
    
    NSUInteger sectionCount = [self itemCountsFromDataSource].size();
    if (sectionCount > 0) {
      NSIndexSet *sectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
      [self _insertElementsIntoMap:map sections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
    }
    // Return immediately because reloadData can't be used in conjuntion with other updates.
    return;
  }
  
  // Migrate old supplementary nodes to their new index paths.
  [map migrateSupplementaryElementsWithSectionMapping:changeSet.sectionMapping];

  for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeDelete]) {
    [map removeItemsAtIndexPaths:change.indexPaths];
    // Aggressively repopulate supplementary nodes (#1773 & #1629)
    [self _repopulateSupplementaryNodesIntoMap:map forSectionsContainingIndexPaths:change.indexPaths
                                     changeSet:changeSet
                               traitCollection:traitCollection
                              indexPathsAreNew:NO
                         shouldFetchSizeRanges:shouldFetchSizeRanges
                                   previousMap:previousMap];
  }

  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeDelete]) {
    NSIndexSet *sectionIndexes = change.indexSet;
    [map removeSectionsOfItems:sectionIndexes];
  }
  
  for (_A_SHierarchySectionChange *change in [changeSet sectionChangesOfType:_A_SHierarchyChangeTypeInsert]) {
    [self _insertElementsIntoMap:map sections:change.indexSet traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
  }
  
  for (_A_SHierarchyItemChange *change in [changeSet itemChangesOfType:_A_SHierarchyChangeTypeInsert]) {
    [self _insertElementsIntoMap:map kind:A_SDataControllerRowNodeKind atIndexPaths:change.indexPaths traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
    // Aggressively reload supplementary nodes (#1773 & #1629)
    [self _repopulateSupplementaryNodesIntoMap:map forSectionsContainingIndexPaths:change.indexPaths
                                     changeSet:changeSet
                               traitCollection:traitCollection
                              indexPathsAreNew:YES
                         shouldFetchSizeRanges:shouldFetchSizeRanges
                                   previousMap:previousMap];
  }
}

- (void)_insertElementsIntoMap:(A_SMutableElementMap *)map
                      sections:(NSIndexSet *)sectionIndexes
               traitCollection:(A_SPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_A_SHierarchyChangeSet *)changeSet
                   previousMap:(A_SElementMap *)previousMap
{
  A_SDisplayNodeAssertMainThread();
  
  if (sectionIndexes.count == 0 || _dataSource == nil) {
    return;
  }

  // Items
  [map insertEmptySectionsOfItemsAtIndexes:sectionIndexes];
  [self _insertElementsIntoMap:map kind:A_SDataControllerRowNodeKind forSections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];

  // Supplementaries
  for (NSString *kind in [self supplementaryKindsInSections:sectionIndexes]) {
    // Step 2: Populate new elements for all sections
    [self _insertElementsIntoMap:map kind:kind forSections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet previousMap:previousMap];
  }
}

#pragma mark - Relayout

- (void)relayoutNodes:(id<NSFastEnumeration>)nodes nodesSizeChanged:(NSMutableArray *)nodesSizesChanged
{
  NSParameterAssert(nodesSizesChanged);
  
  A_SDisplayNodeAssertMainThread();
  if (!_initialReloadDataHasBeenCalled) {
    return;
  }
  
  id<A_SDataControllerSource> dataSource = self.dataSource;
  auto visibleMap = self.visibleMap;
  auto pendingMap = self.pendingMap;
  for (A_SCellNode *node in nodes) {
    auto element = node.collectionElement;
    NSIndexPath *indexPathInPendingMap = [pendingMap indexPathForElement:element];
    // Ensure the element is present in both maps or skip it. If it's not in the visible map,
    // then we can't check the presented size. If it's not in the pending map, we can't get the constrained size.
    // This will only happen if the element has been deleted, so the specifics of this behavior aren't important.
    if (indexPathInPendingMap == nil || [visibleMap indexPathForElement:element] == nil) {
      continue;
    }

    NSString *kind = element.supplementaryElementKind ?: A_SDataControllerRowNodeKind;
    A_SSizeRange constrainedSize = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPathInPendingMap];
    [self _layoutNode:node withConstrainedSize:constrainedSize];

    BOOL matchesSize = [dataSource dataController:self presentedSizeForElement:element matchesSize:node.frame.size];
    if (! matchesSize) {
      [nodesSizesChanged addObject:node];
    }
  }
}

- (void)relayoutAllNodesWithInvalidationBlock:(nullable void (^)())invalidationBlock
{
  A_SDisplayNodeAssertMainThread();
  if (!_initialReloadDataHasBeenCalled) {
    return;
  }
  
  // Can't relayout right away because _visibleMap may not be up-to-date,
  // i.e there might be some nodes that were measured using the old constrained size but haven't been added to _visibleMap
  LOG(@"Edit Command - relayoutRows");
  [self _scheduleBlockOnMainSerialQueue:^{
    // Because -invalidateLayout doesn't trigger any operations by itself, and we answer queries from UICollectionView using layoutThatFits:,
    // we invalidate the layout before we have updated all of the cells. Any cells that the collection needs the size of immediately will get
    // -layoutThatFits: with a new constraint, on the main thread, and synchronously calculate them. Meanwhile, relayoutAllNodes will update
    // the layout of any remaining nodes on background threads (and fast-return for any nodes that the UICV got to first).
    if (invalidationBlock) {
      invalidationBlock();
    }
    [self _relayoutAllNodes];
  }];
}

- (void)_relayoutAllNodes
{
  A_SDisplayNodeAssertMainThread();
  for (A_SCollectionElement *element in _visibleMap) {
    // Ignore this element if it is no longer in the latest data. It is still recognized in the UIKit world but will be deleted soon.
    NSIndexPath *indexPathInPendingMap = [_pendingMap indexPathForElement:element];
    if (indexPathInPendingMap == nil) {
      continue;
    }

    NSString *kind = element.supplementaryElementKind ?: A_SDataControllerRowNodeKind;
    A_SSizeRange newConstrainedSize = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPathInPendingMap];

    if (A_SSizeRangeHasSignificantArea(newConstrainedSize)) {
      element.constrainedSize = newConstrainedSize;

      // Node may not be allocated yet (e.g node virtualization or same size optimization)
      // Call context.nodeIfAllocated here to avoid premature node allocation and layout
      A_SCellNode *node = element.nodeIfAllocated;
      if (node) {
        [self _layoutNode:node withConstrainedSize:newConstrainedSize];
      }
    }
  }
}

# pragma mark - A_SPrimitiveTraitCollection

- (void)environmentDidChange
{
  A_SPerformBlockOnMainThread(^{
    if (!_initialReloadDataHasBeenCalled) {
      return;
    }

    // Can't update the trait collection right away because _visibleMap may not be up-to-date,
    // i.e there might be some elements that were allocated using the old trait collection but haven't been added to _visibleMap
    [self _scheduleBlockOnMainSerialQueue:^{
      A_SPrimitiveTraitCollection newTraitCollection = [self.node primitiveTraitCollection];
      for (A_SCollectionElement *element in _visibleMap) {
        element.traitCollection = newTraitCollection;
      }
    }];
  });
}

# pragma mark - Helper methods

- (void)_scheduleBlockOnMainSerialQueue:(dispatch_block_t)block
{
  A_SDisplayNodeAssertMainThread();
  dispatch_group_wait(_editingTransactionGroup, DISPATCH_TIME_FOREVER);
  [_mainSerialQueue performBlockOnMainThread:block];
}

@end
