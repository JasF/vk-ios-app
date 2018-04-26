//
//  A_SCollectionNode.mm
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

#import <Async_DisplayKit/A_SCollectionNode.h>
#import <Async_DisplayKit/A_SCollectionNode+Beta.h>

#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SCollectionInternal.h>
#import <Async_DisplayKit/A_SCollectionLayout.h>
#import <Async_DisplayKit/A_SCollectionViewLayoutFacilitatorProtocol.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/_A_SHierarchyChangeSet.h>
#import <Async_DisplayKit/Async_DisplayKit+Debug.h>
#import <Async_DisplayKit/A_SSectionContext.h>
#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SRangeController.h>

#pragma mark - _A_SCollectionPendingState

@interface _A_SCollectionPendingState : NSObject
@property (weak, nonatomic) id <A_SCollectionDelegate>   delegate;
@property (weak, nonatomic) id <A_SCollectionDataSource> dataSource;
@property (strong, nonatomic) UICollectionViewLayout *collectionViewLayout;
@property (nonatomic, assign) A_SLayoutRangeMode rangeMode;
@property (nonatomic, assign) BOOL allowsSelection; // default is YES
@property (nonatomic, assign) BOOL allowsMultipleSelection; // default is NO
@property (nonatomic, assign) BOOL inverted; //default is NO
@property (nonatomic, assign) BOOL usesSynchronousDataLoading;
@property (nonatomic, assign) CGFloat leadingScreensForBatching;
@property (weak, nonatomic) id <A_SCollectionViewLayoutInspecting> layoutInspector;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) BOOL animatesContentOffset;
@end

@implementation _A_SCollectionPendingState

- (instancetype)init
{
  self = [super init];
  if (self) {
    _rangeMode = A_SLayoutRangeModeUnspecified;
    _allowsSelection = YES;
    _allowsMultipleSelection = NO;
    _inverted = NO;
    _contentInset = UIEdgeInsetsZero;
    _contentOffset = CGPointZero;
    _animatesContentOffset = NO;
  }
  return self;
}
@end

// TODO: Add support for tuning parameters in the pending state
#if 0  // This is not used yet, but will provide a way to avoid creating the view to set range values.
@implementation _A_SCollectionPendingState {
  std::vector<std::vector<A_SRangeTuningParameters>> _tuningParameters;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _tuningParameters = std::vector<std::vector<A_SRangeTuningParameters>> (A_SLayoutRangeModeCount, std::vector<A_SRangeTuningParameters> (A_SLayoutRangeTypeCount));
    _rangeMode = A_SLayoutRangeModeUnspecified;
  }
  return self;
}

- (A_SRangeTuningParameters)tuningParametersForRangeType:(A_SLayoutRangeType)rangeType
{
  return [self tuningParametersForRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeType:(A_SLayoutRangeType)rangeType
{
  return [self setTuningParameters:tuningParameters forRangeMode:A_SLayoutRangeModeFull rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  A_SDisplayNodeAssert(rangeMode < _tuningParameters.size() && rangeType < _tuningParameters[rangeMode].size(), @"Requesting a range that is OOB for the configured tuning parameters");
  return _tuningParameters[rangeMode][rangeType];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  A_SDisplayNodeAssert(rangeMode < _tuningParameters.size() && rangeType < _tuningParameters[rangeMode].size(), @"Setting a range that is OOB for the configured tuning parameters");
  _tuningParameters[rangeMode][rangeType] = tuningParameters;
}

@end
#endif

#pragma mark - A_SCollectionNode

@interface A_SCollectionNode ()
{
  A_SDN::RecursiveMutex _environmentStateLock;
  Class _collectionViewClass;
  id<A_SBatchFetchingDelegate> _batchFetchingDelegate;
}
@property (nonatomic) _A_SCollectionPendingState *pendingState;
@end

@implementation A_SCollectionNode

#pragma mark Lifecycle

- (Class)collectionViewClass
{
  return _collectionViewClass ? : [A_SCollectionView class];
}

- (void)setCollectionViewClass:(Class)collectionViewClass
{
  if (_collectionViewClass != collectionViewClass) {
    A_SDisplayNodeAssert([collectionViewClass isSubclassOfClass:[A_SCollectionView class]] || collectionViewClass == Nil, @"A_SCollectionNode requires that .collectionViewClass is an A_SCollectionView subclass");
    A_SDisplayNodeAssert([self isNodeLoaded] == NO, @"A_SCollectionNode's .collectionViewClass cannot be changed after the view is loaded");
    _collectionViewClass = collectionViewClass;
  }
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self initWithFrame:CGRectZero collectionViewLayout:layout layoutFacilitator:nil];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self initWithFrame:frame collectionViewLayout:layout layoutFacilitator:nil];
}

- (instancetype)initWithLayoutDelegate:(id<A_SCollectionLayoutDelegate>)layoutDelegate layoutFacilitator:(id<A_SCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator
{
  return [self initWithFrame:CGRectZero collectionViewLayout:[[A_SCollectionLayout alloc] initWithLayoutDelegate:layoutDelegate] layoutFacilitator:layoutFacilitator];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(id<A_SCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator
{
  if (self = [super init]) {
    // Must call the setter here to make sure pendingState is created and the layout is configured.
    [self setCollectionViewLayout:layout];
    
    __weak __typeof__(self) weakSelf = self;
    [self setViewBlock:^{
      __typeof__(self) strongSelf = weakSelf;
      return [[[strongSelf collectionViewClass] alloc] _initWithFrame:frame collectionViewLayout:strongSelf->_pendingState.collectionViewLayout layoutFacilitator:layoutFacilitator owningNode:strongSelf eventLog:A_SDisplayNodeGetEventLog(strongSelf)];
    }];
  }
  return self;
}

#pragma mark A_SDisplayNode

- (void)didLoad
{
  [super didLoad];
  
  A_SCollectionView *view = self.view;
  view.collectionNode    = self;
  
  if (_pendingState) {
    _A_SCollectionPendingState *pendingState = _pendingState;
    self.pendingState               = nil;
    view.asyncDelegate              = pendingState.delegate;
    view.asyncDataSource            = pendingState.dataSource;
    view.inverted                   = pendingState.inverted;
    view.allowsSelection            = pendingState.allowsSelection;
    view.allowsMultipleSelection    = pendingState.allowsMultipleSelection;
    view.usesSynchronousDataLoading = pendingState.usesSynchronousDataLoading;
    view.layoutInspector            = pendingState.layoutInspector;
    view.contentInset               = pendingState.contentInset;
    
    if (pendingState.rangeMode != A_SLayoutRangeModeUnspecified) {
      [view.rangeController updateCurrentRangeWithMode:pendingState.rangeMode];
    }

    [view setContentOffset:pendingState.contentOffset animated:pendingState.animatesContentOffset];
    
    // Don't need to set collectionViewLayout to the view as the layout was already used to init the view in view block.
  }
}

- (A_SCollectionView *)view
{
  return (A_SCollectionView *)[super view];
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
  // TODO (A_SCL) If this node supports async layout, kick off the initial data load without allocating the view
  if (CGRectEqualToRect(self.bounds, CGRectZero) == NO) {
    [[self view] layoutIfNeeded];
  }
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

- (_A_SCollectionPendingState *)pendingState
{
  if (!_pendingState && ![self isNodeLoaded]) {
    self.pendingState = [[_A_SCollectionPendingState alloc] init];
  }
  A_SDisplayNodeAssert(![self isNodeLoaded] || !_pendingState, @"A_SCollectionNode should not have a pendingState once it is loaded");
  return _pendingState;
}

- (void)setInverted:(BOOL)inverted
{
  self.transform = inverted ? CATransform3DMakeScale(1, -1, 1)  : CATransform3DIdentity;
  if ([self pendingState]) {
    _pendingState.inverted = inverted;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
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

- (void)setLayoutInspector:(id<A_SCollectionViewLayoutInspecting>)layoutInspector
{
  if ([self pendingState]) {
    _pendingState.layoutInspector = layoutInspector;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
    self.view.layoutInspector = layoutInspector;
  }
}

- (id<A_SCollectionViewLayoutInspecting>)layoutInspector
{
  if ([self pendingState]) {
    return _pendingState.layoutInspector;
  } else {
    return self.view.layoutInspector;
  }
}

- (void)setLeadingScreensForBatching:(CGFloat)leadingScreensForBatching
{
  if ([self pendingState]) {
    _pendingState.leadingScreensForBatching = leadingScreensForBatching;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
    self.view.leadingScreensForBatching = leadingScreensForBatching;
  }
}

- (CGFloat)leadingScreensForBatching
{
  if ([self pendingState]) {
    return _pendingState.leadingScreensForBatching;
  } else {
    return self.view.leadingScreensForBatching;
  }
}

- (void)setDelegate:(id <A_SCollectionDelegate>)delegate
{
  if ([self pendingState]) {
    _pendingState.delegate = delegate;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");

    // Manually trampoline to the main thread. The view requires this be called on main
    // and asserting here isn't an option – it is a common pattern for users to clear
    // the delegate/dataSource in dealloc, which may be running on a background thread.
    // It is important that we avoid retaining self in this block, so that this method is dealloc-safe.
    A_SCollectionView *view = self.view;
    A_SPerformBlockOnMainThread(^{
      view.asyncDelegate = delegate;
    });
  }
}

- (id <A_SCollectionDelegate>)delegate
{
  if ([self pendingState]) {
    return _pendingState.delegate;
  } else {
    return self.view.asyncDelegate;
  }
}

- (void)setDataSource:(id <A_SCollectionDataSource>)dataSource
{
  if ([self pendingState]) {
    _pendingState.dataSource = dataSource;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
    // Manually trampoline to the main thread. The view requires this be called on main
    // and asserting here isn't an option – it is a common pattern for users to clear
    // the delegate/dataSource in dealloc, which may be running on a background thread.
    // It is important that we avoid retaining self in this block, so that this method is dealloc-safe.
    A_SCollectionView *view = self.view;
    A_SPerformBlockOnMainThread(^{
      view.asyncDataSource = dataSource;
    });
  }
}

- (id <A_SCollectionDataSource>)dataSource
{
  if ([self pendingState]) {
    return _pendingState.dataSource;
  } else {
    return self.view.asyncDataSource;
  }
}

- (void)setAllowsSelection:(BOOL)allowsSelection
{
  if ([self pendingState]) {
    _pendingState.allowsSelection = allowsSelection;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
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

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection
{
  if ([self pendingState]) {
    _pendingState.allowsMultipleSelection = allowsMultipleSelection;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
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

- (void)setCollectionViewLayout:(UICollectionViewLayout *)layout
{
  if ([self pendingState]) {
    [self _configureCollectionViewLayout:layout];
    _pendingState.collectionViewLayout = layout;
  } else {
    [self _configureCollectionViewLayout:layout];
    self.view.collectionViewLayout = layout;
  }
}

- (UICollectionViewLayout *)collectionViewLayout
{
  if ([self pendingState]) {
    return _pendingState.collectionViewLayout;
  } else {
    return self.view.collectionViewLayout;
  }
}

- (void)setContentInset:(UIEdgeInsets)contentInset
{
  if ([self pendingState]) {
    _pendingState.contentInset = contentInset;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
    self.view.contentInset = contentInset;
  }
}

- (UIEdgeInsets)contentInset
{
  if ([self pendingState]) {
    return _pendingState.contentInset;
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
  if ([self pendingState]) {
    _pendingState.contentOffset = contentOffset;
    _pendingState.animatesContentOffset = animated;
  } else {
    A_SDisplayNodeAssert([self isNodeLoaded], @"A_SCollectionNode should be loaded if pendingState doesn't exist");
    [self.view setContentOffset:contentOffset animated:animated];
  }
}

- (CGPoint)contentOffset
{
  if ([self pendingState]) {
    return _pendingState.contentOffset;
  } else {
    return self.view.contentOffset;
  }
}

- (A_SScrollDirection)scrollDirection
{
  return [self isNodeLoaded] ? self.view.scrollDirection : A_SScrollDirectionNone;
}

- (A_SScrollDirection)scrollableDirections
{
  return [self isNodeLoaded] ? self.view.scrollableDirections : A_SScrollDirectionNone;
}

- (A_SElementMap *)visibleElements
{
  A_SDisplayNodeAssertMainThread();
  // TODO Own the data controller when view is not yet loaded
  return self.dataController.visibleMap;
}

- (id<A_SCollectionLayoutDelegate>)layoutDelegate
{
  UICollectionViewLayout *layout = self.collectionViewLayout;
  if ([layout isKindOfClass:[A_SCollectionLayout class]]) {
    return ((A_SCollectionLayout *)layout).layoutDelegate;
  }
  return nil;
}

- (void)setBatchFetchingDelegate:(id<A_SBatchFetchingDelegate>)batchFetchingDelegate
{
  _batchFetchingDelegate = batchFetchingDelegate;
}

- (id<A_SBatchFetchingDelegate>)batchFetchingDelegate
{
  return _batchFetchingDelegate;
}

- (BOOL)usesSynchronousDataLoading
{
  if ([self pendingState]) {
    return _pendingState.usesSynchronousDataLoading; 
  } else {
    return self.view.usesSynchronousDataLoading;
  }
}

- (void)setUsesSynchronousDataLoading:(BOOL)usesSynchronousDataLoading
{
  if ([self pendingState]) {
    _pendingState.usesSynchronousDataLoading = usesSynchronousDataLoading; 
  } else {
    self.view.usesSynchronousDataLoading = usesSynchronousDataLoading;
  }
}

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

- (NSArray<NSIndexPath *> *)indexPathsForSelectedItems
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *view = self.view;
  return [view convertIndexPathsToCollectionNode:view.indexPathsForSelectedItems];
}

- (void)selectItemAtIndexPath:(nullable NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(UICollectionViewScrollPosition)scrollPosition
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *collectionView = self.view;

  indexPath = [collectionView convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:YES];

  if (indexPath != nil) {
    [collectionView selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition];
  } else {
    NSLog(@"Failed to select item at index path %@ because the item never reached the view.", indexPath);
  }
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *collectionView = self.view;

  indexPath = [collectionView convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:YES];

  if (indexPath != nil) {
    [collectionView deselectItemAtIndexPath:indexPath animated:animated];
  } else {
    NSLog(@"Failed to deselect item at index path %@ because the item never reached the view.", indexPath);
  }
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *collectionView = self.view;

  indexPath = [collectionView convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:YES];

  if (indexPath != nil) {
    [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
  } else {
    NSLog(@"Failed to scroll to item at index path %@ because the item never reached the view.", indexPath);
  }
}

#pragma mark - Querying Data

- (void)reloadDataInitiallyIfNeeded
{
  if (!self.dataController.initialReloadDataHasBeenCalled) {
    [self reloadData];
  }
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section
{
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap numberOfItemsInSection:section];
}

- (NSInteger)numberOfSections
{
  [self reloadDataInitiallyIfNeeded];
  return self.dataController.pendingMap.numberOfSections;
}

- (NSArray<__kindof A_SCellNode *> *)visibleNodes
{
  A_SDisplayNodeAssertMainThread();
  return self.isNodeLoaded ? [self.view visibleNodes] : @[];
}

- (A_SCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap elementForItemAtIndexPath:indexPath].node;
}

- (id)nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self reloadDataInitiallyIfNeeded];
  return [self.dataController.pendingMap elementForItemAtIndexPath:indexPath].nodeModel;
}

- (NSIndexPath *)indexPathForNode:(A_SCellNode *)cellNode
{
  return [self.dataController.pendingMap indexPathForElement:cellNode.collectionElement];
}

- (NSArray<NSIndexPath *> *)indexPathsForVisibleItems
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

- (nullable NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *collectionView = self.view;

  NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:point];
  if (indexPath != nil) {
    return [collectionView convertIndexPathToCollectionNode:indexPath];
  }
  return indexPath;
}

- (nullable UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();
  A_SCollectionView *collectionView = self.view;

  indexPath = [collectionView convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:YES];
  if (indexPath == nil) {
    return nil;
  }
  return [collectionView cellForItemAtIndexPath:indexPath];
}

- (id<A_SSectionContext>)contextForSection:(NSInteger)section
{
  A_SDisplayNodeAssertMainThread();
  return [self.dataController.pendingMap contextForSection:section];
}

#pragma mark - Editing

- (void)registerSupplementaryNodeOfKind:(NSString *)elementKind
{
  [self.view registerSupplementaryNodeOfKind:elementKind];
}

- (void)performBatchAnimated:(BOOL)animated updates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view performBatchAnimated:animated updates:updates completion:completion];
  } else {
    if (updates) {
      updates();
    }
    if (completion) {
      completion(YES);
    }
  }
}

- (void)performBatchUpdates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  [self performBatchAnimated:UIView.areAnimationsEnabled updates:updates completion:completion];
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

- (void)reloadDataWithCompletion:(void (^)())completion
{
  A_SDisplayNodeAssertMainThread();
  if (!self.nodeLoaded) {
    return;
  }
  
  [self performBatchUpdates:^{
    [self.view.changeSet reloadData];
  } completion:^(BOOL finished){
    if (completion) {
      completion();
    }
  }];
}

- (void)reloadData
{
  [self reloadDataWithCompletion:nil];
}

- (void)relayoutItems
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
  	[self.view relayoutItems];
  }
}

- (void)beginUpdates
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view beginUpdates];
  }
}

- (void)endUpdatesAnimated:(BOOL)animated
{
  [self endUpdatesAnimated:animated completion:nil];
}

- (void)endUpdatesAnimated:(BOOL)animated completion:(void (^)(BOOL))completion
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view endUpdatesAnimated:animated completion:completion];
  }
}

- (void)invalidateFlowLayoutDelegateMetrics {
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view invalidateFlowLayoutDelegateMetrics];
  }
}

- (void)insertSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view insertSections:sections];
  }
}

- (void)deleteSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view deleteSections:sections];
  }
}

- (void)reloadSections:(NSIndexSet *)sections
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view reloadSections:sections];
  }
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view moveSection:section toSection:newSection];
  }
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view insertItemsAtIndexPaths:indexPaths];
  }
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view deleteItemsAtIndexPaths:indexPaths];
  }
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view reloadItemsAtIndexPaths:indexPaths];
  }
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
  A_SDisplayNodeAssertMainThread();
  if (self.nodeLoaded) {
    [self.view moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
  }
}

#pragma mark - A_SRangeControllerUpdateRangeProtocol

- (void)updateCurrentRangeWithMode:(A_SLayoutRangeMode)rangeMode;
{
  if ([self pendingState]) {
    _pendingState.rangeMode = rangeMode;
  } else {
    [self.rangeController updateCurrentRangeWithMode:rangeMode];
  }
}

#pragma mark - A_SPrimitiveTraitCollection

A_SLayoutElementCollectionTableSetTraitCollection(_environmentStateLock)

#pragma mark - Debugging (Private)

- (NSMutableArray<NSDictionary *> *)propertiesForDebugDescription
{
  NSMutableArray<NSDictionary *> *result = [super propertiesForDebugDescription];
  [result addObject:@{ @"dataSource" : A_SObjectDescriptionMakeTiny(self.dataSource) }];
  [result addObject:@{ @"delegate" : A_SObjectDescriptionMakeTiny(self.delegate) }];
  return result;
}

#pragma mark - Private methods

- (void)_configureCollectionViewLayout:(UICollectionViewLayout *)layout
{
  if ([layout isKindOfClass:[A_SCollectionLayout class]]) {
    A_SCollectionLayout *collectionLayout = (A_SCollectionLayout *)layout;
    collectionLayout.collectionNode = self;
  }
}

@end
