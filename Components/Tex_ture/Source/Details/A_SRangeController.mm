//
//  A_SRangeController.mm
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

#import <Async_DisplayKit/A_SRangeController.h>

#import <Async_DisplayKit/_A_SHierarchyChangeSet.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h> // Required for interfaceState and hierarchyState setter methods.
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SSignpost.h>
#import <Async_DisplayKit/A_STwoDimensionalArrayUtils.h>
#import <Async_DisplayKit/A_SWeakSet.h>

#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/Async_DisplayKit+Debug.h>

#define A_S_RANGECONTROLLER_LOG_UPDATE_FREQ 0

#ifndef A_SRangeControllerAutomaticLowMemoryHandling
#define A_SRangeControllerAutomaticLowMemoryHandling 1
#endif

@interface A_SRangeController ()
{
  BOOL _rangeIsValid;
  BOOL _needsRangeUpdate;
  NSSet<NSIndexPath *> *_allPreviousIndexPaths;
  NSHashTable<A_SCellNode *> *_visibleNodes;
  A_SLayoutRangeMode _currentRangeMode;
  BOOL _preserveCurrentRangeMode;
  BOOL _didRegisterForNodeDisplayNotifications;
  CFTimeInterval _pendingDisplayNodesTimestamp;

  // If the user is not currently scrolling, we will keep our ranges
  // configured to match their previous scroll direction. Defaults
  // to [.right, .down] so that when the user first opens a screen
  // the ranges point down into the content.
  A_SScrollDirection _previousScrollDirection;
  
#if A_S_RANGECONTROLLER_LOG_UPDATE_FREQ
  NSUInteger _updateCountThisFrame;
  CADisplayLink *_displayLink;
#endif
}

@end

static UIApplicationState __ApplicationState = UIApplicationStateActive;

@implementation A_SRangeController

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _rangeIsValid = YES;
  _currentRangeMode = A_SLayoutRangeModeUnspecified;
  _preserveCurrentRangeMode = NO;
  _previousScrollDirection = A_SScrollDirectionDown | A_SScrollDirectionRight;
  
  [[[self class] allRangeControllersWeakSet] addObject:self];
  
#if A_S_RANGECONTROLLER_LOG_UPDATE_FREQ
  _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_updateCountDisplayLinkDidFire)];
  [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
#endif
  
  if (A_SDisplayNode.shouldShowRangeDebugOverlay) {
    [self addRangeControllerToRangeDebugOverlay];
  }
  
  return self;
}

- (void)dealloc
{
#if A_S_RANGECONTROLLER_LOG_UPDATE_FREQ
  [_displayLink invalidate];
#endif
  
  if (_didRegisterForNodeDisplayNotifications) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:A_SRenderingEngineDidDisplayScheduledNodesNotification object:nil];
  }
}

#pragma mark - Core visible node range management API

+ (BOOL)isFirstRangeUpdateForRangeMode:(A_SLayoutRangeMode)rangeMode
{
  return (rangeMode == A_SLayoutRangeModeUnspecified);
}

+ (A_SLayoutRangeMode)rangeModeForInterfaceState:(A_SInterfaceState)interfaceState
                               currentRangeMode:(A_SLayoutRangeMode)currentRangeMode
{
  BOOL isVisible = (A_SInterfaceStateIncludesVisible(interfaceState));
  BOOL isFirstRangeUpdate = [self isFirstRangeUpdateForRangeMode:currentRangeMode];
  if (!isVisible || isFirstRangeUpdate) {
    return A_SLayoutRangeModeMinimum;
  }
  
  return A_SLayoutRangeModeFull;
}

- (A_SInterfaceState)interfaceState
{
  A_SInterfaceState selfInterfaceState = A_SInterfaceStateNone;
  if (_dataSource) {
    selfInterfaceState = [_dataSource interfaceStateForRangeController:self];
  }
  if (__ApplicationState == UIApplicationStateBackground) {
    // If the app is background, pretend to be invisible so that we inform each cell it is no longer being viewed by the user
    selfInterfaceState &= ~(A_SInterfaceStateVisible);
  }
  return selfInterfaceState;
}

- (void)setNeedsUpdate
{
  if (!_needsRangeUpdate) {
    _needsRangeUpdate = YES;
      
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf updateIfNeeded];
    });
  }
}

- (void)updateIfNeeded
{
  if (_needsRangeUpdate) {
    _needsRangeUpdate = NO;
      
    [self _updateVisibleNodeIndexPaths];
  }
}

- (void)updateCurrentRangeWithMode:(A_SLayoutRangeMode)rangeMode
{
  _preserveCurrentRangeMode = YES;
  if (_currentRangeMode != rangeMode) {
    _currentRangeMode = rangeMode;

    [self setNeedsUpdate];
  }
}

- (void)setLayoutController:(id<A_SLayoutController>)layoutController
{
  _layoutController = layoutController;
  if (layoutController && _dataSource) {
    [self updateIfNeeded];
  }
}

- (void)setDataSource:(id<A_SRangeControllerDataSource>)dataSource
{
  _dataSource = dataSource;
  if (dataSource && _layoutController) {
    [self updateIfNeeded];
  }
}

// Clear the visible bit from any nodes that disappeared since last update.
// Currently we guarantee that nodes will not be marked visible when deallocated,
// but it's OK to be in e.g. the preload range. So for the visible bit specifically,
// we add this extra mechanism to account for e.g. deleted items.
//
// NOTE: There is a minor risk here, if a node is transferred from one range controller
// to another before the first rc updates and clears the node out of this set. It's a pretty
// wild scenario that I doubt happens in practice.
- (void)_setVisibleNodes:(NSHashTable *)newVisibleNodes
{
  for (A_SCellNode *node in _visibleNodes) {
    if (![newVisibleNodes containsObject:node] && node.isVisible) {
      [node exitInterfaceState:A_SInterfaceStateVisible];
    }
  }
  _visibleNodes = newVisibleNodes;
}

- (void)_updateVisibleNodeIndexPaths
{
  as_activity_scope_verbose(as_activity_create("Update range controller", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
  as_log_verbose(A_SCollectionLog(), "Updating ranges for %@", A_SViewToDisplayNode(A_SDynamicCast(self.delegate, UIView)));
  A_SDisplayNodeAssert(_layoutController, @"An A_SLayoutController is required by A_SRangeController");
  if (!_layoutController || !_dataSource) {
    return;
  }
  
#if A_S_RANGECONTROLLER_LOG_UPDATE_FREQ
  _updateCountThisFrame += 1;
#endif
  
  A_SElementMap *map = [_dataSource elementMapForRangeController:self];

  // TODO: Consider if we need to use this codepath, or can rely on something more similar to the data & display ranges
  // Example: ... = [_layoutController indexPathsForScrolling:scrollDirection rangeType:A_SLayoutRangeTypeVisible];
  auto visibleElements = [_dataSource visibleElementsForRangeController:self];
  NSHashTable *newVisibleNodes = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];

  if (visibleElements.count == 0) { // if we don't have any visibleNodes currently (scrolled before or after content)...
    [self _setVisibleNodes:newVisibleNodes];
    return; // don't do anything for this update, but leave _rangeIsValid == NO to make sure we update it later
  }
  A_SSignpostStart(A_SSignpostRangeControllerUpdate);

  // Get the scroll direction. Default to using the previous one, if they're not scrolling.
  A_SScrollDirection scrollDirection = [_dataSource scrollDirectionForRangeController:self];
  if (scrollDirection == A_SScrollDirectionNone) {
    scrollDirection = _previousScrollDirection;
  }
  _previousScrollDirection = scrollDirection;
  
  A_SInterfaceState selfInterfaceState = [self interfaceState];
  A_SLayoutRangeMode rangeMode = _currentRangeMode;
  // If the range mode is explicitly set via updateCurrentRangeWithMode: it will last in that mode until the
  // range controller becomes visible again or explicitly changes the range mode again
  if ((!_preserveCurrentRangeMode && A_SInterfaceStateIncludesVisible(selfInterfaceState)) || [[self class] isFirstRangeUpdateForRangeMode:rangeMode]) {
    rangeMode = [A_SRangeController rangeModeForInterfaceState:selfInterfaceState currentRangeMode:_currentRangeMode];
  }

  A_SRangeTuningParameters parametersPreload = [_layoutController tuningParametersForRangeMode:rangeMode
                                                                                    rangeType:A_SLayoutRangeTypePreload];
  A_SRangeTuningParameters parametersDisplay = [_layoutController tuningParametersForRangeMode:rangeMode
                                                                                    rangeType:A_SLayoutRangeTypeDisplay];

  // Preload can express the ultra-low-memory state with 0, 0 returned for its tuningParameters above, and will match Visible.
  // However, in this rangeMode, Display is not supposed to contain *any* paths -- not even the visible bounds. TuningParameters can't express this.
  BOOL emptyDisplayRange = (rangeMode == A_SLayoutRangeModeLowMemory);
  BOOL equalDisplayPreload = A_SRangeTuningParametersEqualToRangeTuningParameters(parametersDisplay, parametersPreload);
  BOOL equalDisplayVisible = (A_SRangeTuningParametersEqualToRangeTuningParameters(parametersDisplay, A_SRangeTuningParametersZero)
                              && emptyDisplayRange == NO);

  // Check if both Display and Preload are unique. If they are, we load them with a single fetch from the layout controller for performance.
  BOOL optimizedLoadingOfBothRanges = (equalDisplayPreload == NO && equalDisplayVisible == NO && emptyDisplayRange == NO);

  NSHashTable<A_SCollectionElement *> *displayElements = nil;
  NSHashTable<A_SCollectionElement *> *preloadElements = nil;
  
  if (optimizedLoadingOfBothRanges) {
    [_layoutController allElementsForScrolling:scrollDirection rangeMode:rangeMode displaySet:&displayElements preloadSet:&preloadElements map:map];
  } else {
    if (emptyDisplayRange == YES) {
      displayElements = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
    } if (equalDisplayVisible == YES) {
      displayElements = visibleElements;
    } else {
      // Calculating only the Display range means the Preload range is either the same as Display or Visible.
      displayElements = [_layoutController elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:A_SLayoutRangeTypeDisplay map:map];
    }
    
    BOOL equalPreloadVisible = A_SRangeTuningParametersEqualToRangeTuningParameters(parametersPreload, A_SRangeTuningParametersZero);
    if (equalDisplayPreload == YES) {
      preloadElements = displayElements;
    } else if (equalPreloadVisible == YES) {
      preloadElements = visibleElements;
    } else {
      preloadElements = [_layoutController elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:A_SLayoutRangeTypePreload map:map];
    }
  }
  
  // For now we are only interested in items. Filter-map out from element to item-index-path.
  NSSet<NSIndexPath *> *visibleIndexPaths = A_SSetByFlatMapping(visibleElements, A_SCollectionElement *element, [map indexPathForElementIfCell:element]);
  NSSet<NSIndexPath *> *displayIndexPaths = A_SSetByFlatMapping(displayElements, A_SCollectionElement *element, [map indexPathForElementIfCell:element]);
  NSSet<NSIndexPath *> *preloadIndexPaths = A_SSetByFlatMapping(preloadElements, A_SCollectionElement *element, [map indexPathForElementIfCell:element]);

  // Prioritize the order in which we visit each.  Visible nodes should be updated first so they are enqueued on
  // the network or display queues before preloading (offscreen) nodes are enqueued.
  NSMutableOrderedSet<NSIndexPath *> *allIndexPaths = [[NSMutableOrderedSet alloc] initWithSet:visibleIndexPaths];
  
  // Typically the preloadIndexPaths will be the largest, and be a superset of the others, though it may be disjoint.
  // Because allIndexPaths is an NSMutableOrderedSet, this adds the non-duplicate items /after/ the existing items.
  // This means that during iteration, we will first visit visible, then display, then preload nodes.
  [allIndexPaths unionSet:displayIndexPaths];
  [allIndexPaths unionSet:preloadIndexPaths];
  
  // Add anything we had applied interfaceState to in the last update, but is no longer in range, so we can clear any
  // range flags it still has enabled.  Most of the time, all but a few elements are equal; a large programmatic
  // scroll or major main thread stall could cause entirely disjoint sets.  In either case we must visit all.
  // Calling "-set" on NSMutableOrderedSet just references the underlying mutable data store, so we must copy it.
  NSSet<NSIndexPath *> *allCurrentIndexPaths = [[allIndexPaths set] copy];
  [allIndexPaths unionSet:_allPreviousIndexPaths];
  _allPreviousIndexPaths = allCurrentIndexPaths;
  
  _currentRangeMode = rangeMode;
  _preserveCurrentRangeMode = NO;
  
  if (!_rangeIsValid) {
    [allIndexPaths addObjectsFromArray:map.itemIndexPaths];
  }
  
#if A_SRangeControllerLoggingEnabled
  A_SDisplayNodeAssertTrue([visibleIndexPaths isSubsetOfSet:displayIndexPaths]);
  NSMutableArray<NSIndexPath *> *modifiedIndexPaths = (A_SRangeControllerLoggingEnabled ? [NSMutableArray array] : nil);
#endif

  for (NSIndexPath *indexPath in allIndexPaths) {
    // Before a node / indexPath is exposed to A_SRangeController, A_SDataController should have already measured it.
    // For consistency, make sure each node knows that it should measure itself if something changes.
    A_SInterfaceState interfaceState = A_SInterfaceStateMeasureLayout;
    
    if (A_SInterfaceStateIncludesVisible(selfInterfaceState)) {
      if ([visibleIndexPaths containsObject:indexPath]) {
        interfaceState |= (A_SInterfaceStateVisible | A_SInterfaceStateDisplay | A_SInterfaceStatePreload);
      } else {
        if ([preloadIndexPaths containsObject:indexPath]) {
          interfaceState |= A_SInterfaceStatePreload;
        }
        if ([displayIndexPaths containsObject:indexPath]) {
          interfaceState |= A_SInterfaceStateDisplay;
        }
      }
    } else {
      // If selfInterfaceState isn't visible, then visibleIndexPaths represents what /will/ be immediately visible at the
      // instant we come onscreen.  So, preload and display all of those things, but don't waste resources preloading yet.
      // We handle this as a separate case to minimize set operations for offscreen preloading, including containsObject:.
      
      if ([allCurrentIndexPaths containsObject:indexPath]) {
        // DO NOT set Visible: even though these elements are in the visible range / "viewport",
        // our overall container object is itself not visible yet.  The moment it becomes visible, we will run the condition above
        
        // Set Layout, Preload
        interfaceState |= A_SInterfaceStatePreload;
        
        if (rangeMode != A_SLayoutRangeModeLowMemory) {
          // Add Display.
          // We might be looking at an indexPath that was previously in-range, but now we need to clear it.
          // In that case we'll just set it back to MeasureLayout.  Only set Display | Preload if in allCurrentIndexPaths.
          interfaceState |= A_SInterfaceStateDisplay;
        }
      }
    }

    A_SCellNode *node = [map elementForItemAtIndexPath:indexPath].nodeIfAllocated;
    if (node != nil) {
      A_SDisplayNodeAssert(node.hierarchyState & A_SHierarchyStateRangeManaged, @"All nodes reaching this point should be range-managed, or interfaceState may be incorrectly reset.");
      if (A_SInterfaceStateIncludesVisible(interfaceState)) {
        [newVisibleNodes addObject:node];
      }
      // Skip the many method calls of the recursive operation if the top level cell node already has the right interfaceState.
      if (node.interfaceState != interfaceState) {
#if A_SRangeControllerLoggingEnabled
        [modifiedIndexPaths addObject:indexPath];
#endif

        BOOL nodeShouldScheduleDisplay = [node shouldScheduleDisplayWithNewInterfaceState:interfaceState];
        [node recursivelySetInterfaceState:interfaceState];

        if (nodeShouldScheduleDisplay) {
          [self registerForNodeDisplayNotificationsForInterfaceStateIfNeeded:selfInterfaceState];
          if (_didRegisterForNodeDisplayNotifications) {
            _pendingDisplayNodesTimestamp = CACurrentMediaTime();
          }
        }
      }
    }
  }

  [self _setVisibleNodes:newVisibleNodes];
  
  // TODO: This code is for debugging only, but would be great to clean up with a delegate method implementation.
  if (A_SDisplayNode.shouldShowRangeDebugOverlay) {
    A_SScrollDirection scrollableDirections = A_SScrollDirectionUp | A_SScrollDirectionDown;
    if ([_dataSource isKindOfClass:NSClassFromString(@"A_SCollectionView")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
      scrollableDirections = (A_SScrollDirection)[_dataSource performSelector:@selector(scrollableDirections)];
#pragma clang diagnostic pop
    }
    
    [self updateRangeController:self
       withScrollableDirections:scrollableDirections
                scrollDirection:scrollDirection
                      rangeMode:rangeMode
        displayTuningParameters:parametersDisplay
        preloadTuningParameters:parametersPreload
                 interfaceState:selfInterfaceState];
  }
  
  _rangeIsValid = YES;
  
#if A_SRangeControllerLoggingEnabled
//  NSSet *visibleNodePathsSet = [NSSet setWithArray:visibleNodePaths];
//  BOOL setsAreEqual = [visibleIndexPaths isEqualToSet:visibleNodePathsSet];
//  NSLog(@"visible sets are equal: %d", setsAreEqual);
//  if (!setsAreEqual) {
//    NSLog(@"standard: %@", visibleIndexPaths);
//    NSLog(@"custom: %@", visibleNodePathsSet);
//  }
  [modifiedIndexPaths sortUsingSelector:@selector(compare:)];
  NSLog(@"Range update complete; modifiedIndexPaths: %@", [self descriptionWithIndexPaths:modifiedIndexPaths]);
#endif
  
  A_SSignpostEnd(A_SSignpostRangeControllerUpdate);
}

#pragma mark - Notification observers

/**
 * If we're in a restricted range mode, but we're going to change to a full range mode soon,
 * go ahead and schedule the transition as soon as all the currently-scheduled rendering is done #1163.
 */
- (void)registerForNodeDisplayNotificationsForInterfaceStateIfNeeded:(A_SInterfaceState)interfaceState
{
  // Do not schedule to listen if we're already in full range mode.
  // This avoids updating the range controller during a collection teardown when it is removed
  // from the hierarchy and its data source is cleared, causing UIKit to call -reloadData.
  if (!_didRegisterForNodeDisplayNotifications && _currentRangeMode != A_SLayoutRangeModeFull) {
    A_SLayoutRangeMode nextRangeMode = [A_SRangeController rangeModeForInterfaceState:interfaceState
                                                                   currentRangeMode:_currentRangeMode];
    if (_currentRangeMode != nextRangeMode) {
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(scheduledNodesDidDisplay:)
                                                   name:A_SRenderingEngineDidDisplayScheduledNodesNotification
                                                 object:nil];
      _didRegisterForNodeDisplayNotifications = YES;
    }
  }
}

- (void)scheduledNodesDidDisplay:(NSNotification *)notification
{
  CFAbsoluteTime notificationTimestamp = ((NSNumber *) notification.userInfo[A_SRenderingEngineDidDisplayNodesScheduledBeforeTimestamp]).doubleValue;
  if (_pendingDisplayNodesTimestamp < notificationTimestamp) {
    // The rendering engine has processed all the nodes this range controller scheduled. Let's schedule a range update
    [[NSNotificationCenter defaultCenter] removeObserver:self name:A_SRenderingEngineDidDisplayScheduledNodesNotification object:nil];
    _didRegisterForNodeDisplayNotifications = NO;
    
    [self setNeedsUpdate];
  }
}

#pragma mark - Cell node view handling

- (void)configureContentView:(UIView *)contentView forCellNode:(A_SCellNode *)node
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(node, @"Cannot move a nil node to a view");
  A_SDisplayNodeAssert(contentView, @"Cannot move a node to a non-existent view");

  if (node.shouldUseUIKitCell) {
    // When using UIKit cells, the A_SCellNode is just a placeholder object with a preferredSize.
    // In this case, we should not disrupt the subviews of the contentView.
    return;
  }

  if (node.view.superview == contentView) {
    // this content view is already correctly configured
    return;
  }
  
  // clean the content view
  for (UIView *view in contentView.subviews) {
    [view removeFromSuperview];
  }
  
  [contentView addSubview:node.view];
}

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  [_layoutController setTuningParameters:tuningParameters forRangeMode:rangeMode rangeType:rangeType];
}

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType
{
  return [_layoutController tuningParametersForRangeMode:rangeMode rangeType:rangeType];
}

#pragma mark - A_SDataControllerDelegete

- (void)dataController:(A_SDataController *)dataController updateWithChangeSet:(_A_SHierarchyChangeSet *)changeSet updates:(dispatch_block_t)updates
{
  A_SDisplayNodeAssertMainThread();
  if (changeSet.includesReloadData) {
    [self _setVisibleNodes:nil];
  }
  _rangeIsValid = NO;
  [_delegate rangeController:self updateWithChangeSet:changeSet updates:updates];
}

#pragma mark - Memory Management

// Skip the many method calls of the recursive operation if the top level cell node already has the right interfaceState.
- (void)clearContents
{
  for (A_SCollectionElement *element in [_dataSource elementMapForRangeController:self]) {
    A_SCellNode *node = element.nodeIfAllocated;
    if (A_SInterfaceStateIncludesDisplay(node.interfaceState)) {
      [node exitInterfaceState:A_SInterfaceStateDisplay];
    }
  }
}

- (void)clearPreloadedData
{
  for (A_SCollectionElement *element in [_dataSource elementMapForRangeController:self]) {
    A_SCellNode *node = element.nodeIfAllocated;
    if (A_SInterfaceStateIncludesPreload(node.interfaceState)) {
      [node exitInterfaceState:A_SInterfaceStatePreload];
    }
  }
}

#pragma mark - Class Methods (Application Notification Handlers)

+ (A_SWeakSet *)allRangeControllersWeakSet
{
  static A_SWeakSet<A_SRangeController *> *__allRangeControllersWeakSet;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __allRangeControllersWeakSet = [[A_SWeakSet alloc] init];
    [self registerSharedApplicationNotifications];
  });
  return __allRangeControllersWeakSet;
}

+ (void)registerSharedApplicationNotifications
{
  NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
#if A_SRangeControllerAutomaticLowMemoryHandling
  [center addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
  [center addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
  [center addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

static A_SLayoutRangeMode __rangeModeForMemoryWarnings = A_SLayoutRangeModeLowMemory;
+ (void)setRangeModeForMemoryWarnings:(A_SLayoutRangeMode)rangeMode
{
  A_SDisplayNodeAssert(rangeMode == A_SLayoutRangeModeVisibleOnly || rangeMode == A_SLayoutRangeModeLowMemory, @"It is highly inadvisable to engage a larger range mode when a memory warning occurs, as this will almost certainly cause app eviction");
  __rangeModeForMemoryWarnings = rangeMode;
}

+ (void)didReceiveMemoryWarning:(NSNotification *)notification
{
  NSArray *allRangeControllers = [[self allRangeControllersWeakSet] allObjects];
  for (A_SRangeController *rangeController in allRangeControllers) {
    BOOL isDisplay = A_SInterfaceStateIncludesDisplay([rangeController interfaceState]);
    [rangeController updateCurrentRangeWithMode:isDisplay ? A_SLayoutRangeModeVisibleOnly : __rangeModeForMemoryWarnings];
    // There's no need to call needs update as updateCurrentRangeWithMode sets this if necessary.
    [rangeController updateIfNeeded];
  }
  
#if A_SRangeControllerLoggingEnabled
  NSLog(@"+[A_SRangeController didReceiveMemoryWarning] with controllers: %@", allRangeControllers);
#endif
}

+ (void)didEnterBackground:(NSNotification *)notification
{
  NSArray *allRangeControllers = [[self allRangeControllersWeakSet] allObjects];
  for (A_SRangeController *rangeController in allRangeControllers) {
    // We do not want to fully collapse the Display ranges of any visible range controllers so that flashes can be avoided when
    // the app is resumed.  Non-visible controllers can be more aggressively culled to the LowMemory state (see definitions for documentation)
    BOOL isVisible = A_SInterfaceStateIncludesVisible([rangeController interfaceState]);
    [rangeController updateCurrentRangeWithMode:isVisible ? A_SLayoutRangeModeVisibleOnly : A_SLayoutRangeModeLowMemory];
  }
  
  // Because -interfaceState checks __ApplicationState and always clears the "visible" bit if Backgrounded, we must set this after updating the range mode.
  __ApplicationState = UIApplicationStateBackground;
  for (A_SRangeController *rangeController in allRangeControllers) {
    // Trigger a range update immediately, as we may not be allowed by the system to run the update block scheduled by changing range mode.
    // There's no need to call needs update as updateCurrentRangeWithMode sets this if necessary.
    [rangeController updateIfNeeded];
  }
  
#if A_SRangeControllerLoggingEnabled
  NSLog(@"+[A_SRangeController didEnterBackground] with controllers, after backgrounding: %@", allRangeControllers);
#endif
}

+ (void)willEnterForeground:(NSNotification *)notification
{
  NSArray *allRangeControllers = [[self allRangeControllersWeakSet] allObjects];
  __ApplicationState = UIApplicationStateActive;
  for (A_SRangeController *rangeController in allRangeControllers) {
    BOOL isVisible = A_SInterfaceStateIncludesVisible([rangeController interfaceState]);
    [rangeController updateCurrentRangeWithMode:isVisible ? A_SLayoutRangeModeMinimum : A_SLayoutRangeModeVisibleOnly];
    // There's no need to call needs update as updateCurrentRangeWithMode sets this if necessary.
    [rangeController updateIfNeeded];
  }
  
#if A_SRangeControllerLoggingEnabled
  NSLog(@"+[A_SRangeController willEnterForeground] with controllers, after foregrounding: %@", allRangeControllers);
#endif
}

#pragma mark - Debugging

#if A_S_RANGECONTROLLER_LOG_UPDATE_FREQ
- (void)_updateCountDisplayLinkDidFire
{
  if (_updateCountThisFrame > 1) {
    NSLog(@"A_SRangeController %p updated %lu times this frame.", self, (unsigned long)_updateCountThisFrame);
  }
  _updateCountThisFrame = 0;
}
#endif

- (NSString *)descriptionWithIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
{
  NSMutableString *description = [NSMutableString stringWithFormat:@"%@ %@", [super description], @" allPreviousIndexPaths:\n"];
  for (NSIndexPath *indexPath in indexPaths) {
    A_SDisplayNode *node = [[_dataSource elementMapForRangeController:self] elementForItemAtIndexPath:indexPath].nodeIfAllocated;
    A_SInterfaceState interfaceState = node.interfaceState;
    BOOL inVisible = A_SInterfaceStateIncludesVisible(interfaceState);
    BOOL inDisplay = A_SInterfaceStateIncludesDisplay(interfaceState);
    BOOL inPreload = A_SInterfaceStateIncludesPreload(interfaceState);
    [description appendFormat:@"indexPath %@, Visible: %d, Display: %d, Preload: %d\n", indexPath, inVisible, inDisplay, inPreload];
  }
  return description;
}

- (NSString *)description
{
  NSArray<NSIndexPath *> *indexPaths = [[_allPreviousIndexPaths allObjects] sortedArrayUsingSelector:@selector(compare:)];
  return [self descriptionWithIndexPaths:indexPaths];
}

@end

@implementation A_SDisplayNode (RangeModeConfiguring)

+ (void)setRangeModeForMemoryWarnings:(A_SLayoutRangeMode)rangeMode
{
  [A_SRangeController setRangeModeForMemoryWarnings:rangeMode];
}

@end
