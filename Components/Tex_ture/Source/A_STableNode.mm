//
//  A_STableNode.mm
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

#import <Async_DisplayKit/A_STableNode.h>
#import <Async_DisplayKit/A_STableNode+Beta.h>

#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_STableViewInternal.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/Async_DisplayKit+Debug.h>
#import <Async_DisplayKit/A_STableView+Undeprecated.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SRangeController.h>

#pragma mark - _A_STablePendingState

@interface _A_STablePendingState : NSObject
@property (weak, nonatomic) id <A_STableDelegate>   delegate;
@property (weak, nonatomic) id <A_STableDataSource> dataSource;
@property (nonatomic, assign) A_SLayoutRangeMode rangeMode;
@property (nonatomic, assign) BOOL allowsSelection;
@property (nonatomic, assign) BOOL allowsSelectionDuringEditing;
@property (nonatomic, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) BOOL allowsMultipleSelectionDuringEditing;
@property (nonatomic, assign) BOOL inverted;
@property (nonatomic, assign) CGFloat leadingScreensForBatching;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) BOOL animatesContentOffset;
@property (nonatomic, assign) BOOL automaticallyAdjustsContentOffset;
@end

@implementation _A_STablePendingState
- (instancetype)init
{
  self = [super init];
  if (self) {
    _rangeMode = A_SLayoutRangeModeUnspecified;
    _allowsSelection = YES;
    _allowsSelectionDuringEditing = NO;
    _allowsMultipleSelection = NO;
    _allowsMultipleSelectionDuringEditing = NO;
    _inverted = NO;
    _leadingScreensForBatching = 2;
    _contentInset = UIEdgeInsetsZero;
    _contentOffset = CGPointZero;
    _animatesContentOffset = NO;
    _automaticallyAdjustsContentOffset = NO;
  }
  return self;
}

@end

#pragma mark - A_STableView

@interface A_STableNode ()
{
  A_SDN::RecursiveMutex _environmentStateLock;
  id<A_SBatchFetchingDelegate> _batchFetchingDelegate;
}

@property (nonatomic, strong) _A_STablePendingState *pendingState;
@end

@implementation A_STableNode

#pragma mark Lifecycle

- (instancetype)initWithStyle:(UITableViewStyle)style
{
  if (self = [super init]) {
    __weak __typeof__(self) weakSelf = self;
    [self setViewBlock:^{
      // Variable will be unused if event logging is off.
      __unused __typeof__(self) strongSelf = weakSelf;
      return [[A_STableView alloc] _initWithFrame:CGRectZero style:style dataControllerClass:nil owningNode:strongSelf eventLog:A_SDisplayNodeGetEventLog(strongSelf)];
    }];
  }
  return self;
}

- (instancetype)init
{
  return [self initWithStyle:UITableViewStylePlain];
}

#pragma mark A_SDisplayNode

- (void)didLoad
{
  [super didLoad];
  
  A_STableView *view = self.view;
  view.tableNode    = self;

  if (_pendingState) {
    _A_STablePendingState *pendingState = _pendingState;
    view.asyncDelegate                        = pendingState.delegate;
    view.asyncDataSource                      = pendingState.dataSource;
    view.inverted                             = pendingState.inverted;
    view.allowsSelection                      = pendingState.allowsSelection;
    view.allowsSelectionDuringEditing         = pendingState.allowsSelectionDuringEditing;
    view.allowsMultipleSelection              = pendingState.allowsMultipleSelection;
    view.allowsMultipleSelectionDuringEditing = pendingState.allowsMultipleSelectionDuringEditing;
    view.contentInset                         = pendingState.contentInset;
    self.pendingState                         = nil;
    
    if (pendingState.rangeMode != A_SLayoutRangeModeUnspecified) {
      [view.rangeController updateCurrentRangeWithMode:pendingState.rangeMode];
    }

    [view setContentOffset:pendingState.contentOffset animated:pendingState.animatesContentOffset];
  }
}

- (A_STableView *)view
{
  return (A_STableView *)[super view];
}

- (void)clearContents
{
  [super clearContents];
  [self.rangeController clearContents];
}

- (void)interfaceStateDidChange:(A_SInterfaceState)newState fromState:(A_SInterfaceState)oldState
{
  [super interfaceStateDidChange:newState fromState:oldState];
  [A_SRangeController layoutDebugOverlayIfNeeded];
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  // Intentionally allocate the view here and trigger a layout pass on it, which in turn will trigger the intial data load.
  // We can get rid of this call later when A_SDataController, A_SRangeController and A_SCollectionLayout can operate without the view.
  [[self view] layoutIfNeeded];
}

#if A_SRangeControllerLoggingEnabled
- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  NSLog(@"%@ - visible: YES", self);
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  NSLog(@"%@ - visible: NO", self);
}
#endif

- (void)didExitPreloadState
{
  [super didExitPreloadState];
  [self.rangeController clearPreloadedData];
}

#pragma mark Setter / Getter

// TODO: Implement this without the view. Then revisit A_SLayoutElementCollectionTableSetTraitCollection
- (A_SDataController *)dataController
{
  return self.view.dataController;
}

// TODO: Implement this without the view.
- (A_SRangeController *)rangeController
{
  return self.view.rangeController;
}

- (_A_STablePendingState *)pendingState
{
  if (!_pendingState && ![self isNodeLoaded]) {
    _pendingState = [[_A_STablePendingState alloc] init];
  }
  A_SDisplayNodeAssert(![self isNodeLoaded] || !_pendingState, @"A_STableNode should not have a pendingState once it is loaded");
  return _pendingState;
}

- (void)setInverted:(BOOL)inverted
{
  self.transform = inverted ? CATransform3DMakeScale(1, -1, 1)  : CATransform3DIdentity;
  if ([self pendingState]) {
    _pendingState.inverted = inverted;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.inverted = inverted;
  }
}

- (BOOL)inverted
{
  if ([self pendingState]) {
    return _pendingState.inverted;
  } else {
    return self.view.inverted;
  }
}

- (void)setLeadingScreensForBatching:(CGFloat)leadingScreensForBatching
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    pendingState.leadingScreensForBatching = leadingScreensForBatching;
  } else {
    A_SDisplayNodeAssert(self.nodeLoaded, @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.leadingScreensForBatching = leadingScreensForBatching;
  }
}

- (CGFloat)leadingScreensForBatching
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    return pendingState.leadingScreensForBatching;
  } else {
    return self.view.leadingScreensForBatching;
  }
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    pendingState.contentInset = contentInset;
  } else {
    A_SDisplayNodeAssert(self.nodeLoaded, @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.contentInset = contentInset;
  }
}

- (UIEdgeInsets)contentInset
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    return pendingState.contentInset;
  } else {
    return self.view.contentInset;
  }
}

- (void)setContentOffset:(CGPoint)contentOffset
{
  [self setContentOffset:contentOffset animated:NO];
}

- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    pendingState.contentOffset = contentOffset;
    pendingState.animatesContentOffset = animated;
  } else {
    A_SDisplayNodeAssert(self.nodeLoaded, @"A_STableNode should be loaded if pendingState doesn't exist");
    [self.view setContentOffset:contentOffset animated:animated];
  }
}

- (CGPoint)contentOffset
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    return pendingState.contentOffset;
  } else {
    return self.view.contentOffset;
  }
}

- (void)setAutomaticallyAdjustsContentOffset:(BOOL)automaticallyAdjustsContentOffset
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    pendingState.automaticallyAdjustsContentOffset = automaticallyAdjustsContentOffset;
  } else {
    A_SDisplayNodeAssert(self.nodeLoaded, @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.automaticallyAdjustsContentOffset = automaticallyAdjustsContentOffset;
  }
}

- (BOOL)automaticallyAdjustsContentOffset
{
  _A_STablePendingState *pendingState = self.pendingState;
  if (pendingState) {
    return pendingState.automaticallyAdjustsContentOffset;
  } else {
    return self.view.automaticallyAdjustsContentOffset;
  }
}

- (void)setDelegate:(id <A_STableDelegate>)delegate
{
  if ([self pendingState]) {
    _pendingState.delegate = delegate;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");

    // Manually trampoline to the main thread. The view requires this be called on main
    // and asserting here isn't an option – it is a common pattern for users to clear
    // the delegate/dataSource in dealloc, which may be running on a background thread.
    // It is important that we avoid retaining self in this block, so that this method is dealloc-safe.
    A_STableView *view = self.view;
    A_SPerformBlockOnMainThread(^{
      view.asyncDelegate = delegate;
    });
  }
}

- (id <A_STableDelegate>)delegate
{
  if ([self pendingState]) {
    return _pendingState.delegate;
  } else {
    return self.view.asyncDelegate;
  }
}

- (void)setDataSource:(id <A_STableDataSource>)dataSource
{
  if ([self pendingState]) {
    _pendingState.dataSource = dataSource;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");

    // Manually trampoline to the main thread. The view requires this be called on main
    // and asserting here isn't an option – it is a common pattern for users to clear
    // the delegate/dataSource in dealloc, which may be running on a background thread.
    // It is important that we avoid retaining self in this block, so that this method is dealloc-safe.
    A_STableView *view = self.view;
    A_SPerformBlockOnMainThread(^{
      view.asyncDataSource = dataSource;
    });
  }
}

- (id <A_STableDataSource>)dataSource
{
  if ([self pendingState]) {
    return _pendingState.dataSource;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    return self.view.asyncDataSource;
  }
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
  if ([self pendingState]) {
    _pendingState.allowsSelection = allowsSelection;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.allowsSelection = allowsSelection;
  }
}

- (BOOL)allowsSelection
{
  if ([self pendingState]) {
    return _pendingState.allowsSelection;
  } else {
    return self.view.allowsSelection;
  }
}

- (void)setAllowsSelectionDuringEditing:(BOOL)allowsSelectionDuringEditing
{
  if ([self pendingState]) {
    _pendingState.allowsSelectionDuringEditing = allowsSelectionDuringEditing;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.allowsSelectionDuringEditing = allowsSelectionDuringEditing;
  }
}

- (BOOL)allowsSelectionDuringEditing
{
  if ([self pendingState]) {
    return _pendingState.allowsSelectionDuringEditing;
  } else {
    return self.view.allowsSelectionDuringEditing;
  }
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
  if ([self pendingState]) {
    _pendingState.allowsMultipleSelection = allowsMultipleSelection;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.allowsMultipleSelection = allowsMultipleSelection;
  }
}

- (BOOL)allowsMultipleSelection
{
  if ([self pendingState]) {
    return _pendingState.allowsMultipleSelection;
  } else {
    return self.view.allowsMultipleSelection;
  }
}

- (void)setAllowsMultipleSelectionDuringEditing:(BOOL)allowsMultipleSelectionDuringEditing
{
  if ([self pendingState]) {
    _pendingState.allowsMultipleSelectionDuringEditing = allowsMultipleSelectionDuringEditing;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    self.view.allowsMultipleSelectionDuringEditing = allowsMultipleSelectionDuringEditing;
  }
}

- (BOOL)allowsMultipleSelectionDuringEditing
{
  if ([self pendingState]) {
    return _pendingState.allowsMultipleSelectionDuringEditing;
  } else {
    return self.view.allowsMultipleSelectionDuringEditing;
  }
}

- (void)setBatchFetchingDelegate:(id<A_SBatchFetchingDelegate>)batchFetchingDelegate
{
  _batchFetchingDelegate = batchFetchingDelegate;
}

- (id<A_SBatchFetchingDelegate>)batchFetchingDelegate
{
  return _batchFetchingDelegate;
}

#pragma mark A_SRangeControllerUpdateRangeProtocol

- (void)updateCurrentRangeWithMode:(A_SLayoutRangeMode)rangeMode
{
  if ([self pendingState]) {
    _pendingState.rangeMode = rangeMode;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_STableNode should be loaded if pendingState doesn't exist");
    [self.rangeController updateCurrentRangeWithMode:rangeMode];
  }
}

#pragma mark A_SEnvironment

A_SLayoutElementCollectionTableSetTraitCollection(_environmentStateLock)

#pragma mark - Range Tuning

- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType
{
  return [self.rangeController tuningParametersForRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType
{
  [self.rangeController setTuningParameters:tuningParameters forRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  return [self.rangeController tuningParametersForRangeMode:rangeMode rangeType:rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  return [self.rangeController setTuningParameters:tuningParameters forRangeMode:rangeMode rangeType:rangeType];
}

#pragma mark - Selection

- (void)selectRowAtIndexPath:(nullable NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UITableViewScrollPosition)scrollPosition
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  indexPath = [tableView convertIndexPathFromTableNode:indexPath waitingIfNeeded:YES];
  if (indexPath != nil) {
    [tableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
  } else {
    NSLog(@"Failed to select row at index path %@ because the row never reached the view.", indexPath);
  }

}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  indexPath = [tableView convertIndexPathFromTableNode:indexPath waitingIfNeeded:YES];
  if (indexPath != nil) {
    [tableView deselectRowAtIndexPath:indexPath animated:animated];
  } else {
    NSLog(@"Failed to deselect row at index path %@ because the row never reached the view.", indexPath);
  }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)scrollPosition animated:(BOOL)animated
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  indexPath = [tableView convertIndexPathFromTableNode:indexPath waitingIfNeeded:YES];

  if (indexPath != nil) {
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
  } else {
    NSLog(@"Failed to scroll to row at index path %@ because the row never reached the view.", indexPath);
  }
}

#pragma mark - Querying Data

- (void)reloadDataInitiallyIfNeeded
{
  A_SDisplayNodeAssertMainThread();
  if (!self.dataController.initialReloadDataHasBeenCalled) {
    // Note: Just calling reloadData isn't enough here – we need to
    // ensure that _nodesConstrainedWidth is updated first.
    [self.view layoutIfNeeded];
  }
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap numberOfItemsInSection:section];
}

- (NSInteger)numberOfSections
{
  A_SDisplayNodeAssertMainThread();
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap numberOfSections];
}

- (NSArray<__kindof A_SCellNode *> *)visibleNodes
{
  A_SDisplayNodeAssertMainThread();
  return self.isNodeLoaded ? [self.view visibleNodes] : @[];
}

- (NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode
{
  return [self.dataController.pendingMap indexPathForElement:cellNode.collectionElement];
}

- (A_SCellNode *)nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap elementForItemAtIndexPath:indexPath].node;
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  indexPath = [tableView convertIndexPathFromTableNode:indexPath waitingIfNeeded:YES];
  return [tableView rectForRowAtIndexPath:indexPath];
}

- (nullable __kindof UITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  indexPath = [tableView convertIndexPathFromTableNode:indexPath waitingIfNeeded:YES];
  if (indexPath == nil) {
    return nil;
  }
  return [tableView cellForRowAtIndexPath:indexPath];
}

- (nullable NSIndexPath *)indexPathForSelectedRow
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  NSIndexPath *indexPath = tableView.indexPathForSelectedRow;
  if (indexPath != nil) {
    return [tableView convertIndexPathToTableNode:indexPath];
  }
  return indexPath;
}

- (NSArray<NSIndexPath *> *)indexPathsForSelectedRows
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  return [tableView convertIndexPathsToTableNode:tableView.indexPathsForSelectedRows];
}

- (nullable NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;

  NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:point];
  if (indexPath != nil) {
    return [tableView convertIndexPathToTableNode:indexPath];
  }
  return indexPath;
}

- (nullable NSArray<NSIndexPath *> *)indexPathsForRowsInRect:(CGRect)rect
{
  A_SDisplayNodeAssertMainThread();
  A_STableView *tableView = self.view;
  return [tableView convertIndexPathsToTableNode:[tableView indexPathsForRowsInRect:rect]];
}

- (NSArray<NSIndexPath *> *)indexPathsForVisibleRows
{
  A_SDisplayNodeAssertMainThread();
  NSMutableArray *indexPathsArray = [NSMutableArray new];
  for (A_SCellNode *cell in [self visibleNodes]) {
    NSIndexPath *indexPath = [self indexPathForNode:cell];
    if (indexPath) {
      [indexPathsArray addObject:indexPath];
    }
  }
  return indexPathsArray;
}

#pragma mark - Editing

- (void)reloadDataWithCompletion:(void (^)())completion
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view reloadDataWithCompletion:completion];
  } else {
    if (completion) {
      completion();
    }
  }
}

- (void)reloadData
{
  [self reloadDataWithCompletion:nil];
}

- (void)relayoutItems
{
  [self.view relayoutItems];
}

- (void)performBatchAnimated:(BOOL)animated updates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    A_STableView *tableView = self.view;
    [tableView beginUpdates];
    if (updates) {
      updates();
    }
    [tableView endUpdatesAnimated:animated completion:completion];
  } else {
    if (updates) {
      updates();
    }
  }
}

- (void)performBatchUpdates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  [self performBatchAnimated:YES updates:updates completion:completion];
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view insertSections:sections withRowAnimation:animation];
  }
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view deleteSections:sections withRowAnimation:animation];
  }
}

- (void)reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view reloadSections:sections withRowAnimation:animation];
  }
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view moveSection:section toSection:newSection];
  }
}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view insertRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  }
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view deleteRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  }
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view reloadRowsAtIndexPaths:indexPaths withRowAnimation:animation];
  }
}

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
  }
}

- (BOOL)isProcessingUpdates
{
  return (self.nodeLoaded ? [self.view isProcessingUpdates] : NO);
}

- (void)onDidFinishProcessingUpdates:(nullable void (^)())completion
{
  if (!self.nodeLoaded) {
    completion();
  } else {
    [self.view onDidFinishProcessingUpdates:completion];
  }
}

- (void)waitUntilAllUpdatesAreProcessed
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view waitUntilAllUpdatesAreCommitted];
  }
}

- (void)waitUntilAllUpdatesAreCommitted
{
  [self waitUntilAllUpdatesAreProcessed];
}

#pragma mark - Debugging (Private)

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray<NSDictionary *> *result = [super propertiesForDebugDescription];
  [result addObject:@{ @"dataSource" : A_SObjectDescriptionMakeTiny(self.dataSource) }];
  [result addObject:@{ @"delegate" : A_SObjectDescriptionMakeTiny(self.delegate) }];
  return result;
}

@end
