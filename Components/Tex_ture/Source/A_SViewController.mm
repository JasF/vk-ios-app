//
//  A_SViewController.mm
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

#import <Async_DisplayKit/A_SViewController.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_STraitCollection.h>
#import <Async_DisplayKit/A_SRangeControllerUpdateRangeProtocol+Beta.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>

@implementation A_SViewController
{
  BOOL _ensureDisplayed;
  BOOL _automaticallyAdjustRangeModeBasedOnViewEvents;
  BOOL _parentManagesVisibilityDepth;
  NSInteger _visibilityDepth;
  BOOL _selfConformsToRangeModeProtocol;
  BOOL _nodeConformsToRangeModeProtocol;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (!(self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
    return nil;
  }
  
  [self _initializeInstance];
  
  return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
  if (!(self = [super initWithCoder:aDecoder])) {
    return nil;
  }
  
  [self _initializeInstance];
  
  return self;
}

- (instancetype)initWithNode:(A_SDisplayNode *)node
{
  if (!(self = [super initWithNibName:nil bundle:nil])) {
    return nil;
  }
  
  _node = node;
  [self _initializeInstance];

  return self;
}

- (void)_initializeInstance
{
  if (_node == nil) {
    return;
  }
  
  _selfConformsToRangeModeProtocol = [self conformsToProtocol:@protocol(A_SRangeControllerUpdateRangeProtocol)];
  _nodeConformsToRangeModeProtocol = [_node conformsToProtocol:@protocol(A_SRangeControllerUpdateRangeProtocol)];
  _automaticallyAdjustRangeModeBasedOnViewEvents = _selfConformsToRangeModeProtocol || _nodeConformsToRangeModeProtocol;
  
  // In case the node will get loaded
  if (_node.nodeLoaded) {
    // Node already loaded the view
    [self view];
  } else {
    // If the node didn't load yet add ourselves as on did load observer to load the view in case the node gets loaded
    // before the view controller
    __weak __typeof__(self) weakSelf = self;
    [_node onDidLoad:^(__kindof A_SDisplayNode * _Nonnull node) {
      if ([weakSelf isViewLoaded] == NO) {
        [weakSelf view];
      }
    }];
  }
}

- (void)dealloc
{
  A_SPerformBackgroundDeallocation(&_node);
}

- (void)loadView
{
  // Apple applies a frame and autoresizing masks we need.  Allocating a view is not
  // nearly as expensive as adding and removing it from a hierarchy, and fortunately
  // we can avoid that here.  Enabling layerBacking on a single node in the hierarchy
  // will have a greater performance benefit than the impact of this transient view.
  [super loadView];
  
  if (_node == nil) {
    return;
  }
  
  A_SDisplayNodeAssertTrue(!_node.layerBacked);
  
  UIView *view = self.view;
  CGRect frame = view.frame;
  UIViewAutoresizing autoresizingMask = view.autoresizingMask;
  
  // We have what we need, so now create and assign the view we actually want.
  view = _node.view;
  _node.frame = frame;
  _node.autoresizingMask = autoresizingMask;
  self.view = view;
  
  // ensure that self.node has a valid trait collection before a subclass's implementation of viewDidLoad.
  // Any subnodes added in viewDidLoad will then inherit the proper environment.
  A_SPrimitiveTraitCollection traitCollection = [self primitiveTraitCollectionForUITraitCollection:self.traitCollection];
  [self propagateNewTraitCollection:traitCollection];
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  
  // Before layout, make sure that our trait collection containerSize actually matches the size of our bounds.
  // If not, we need to update the traits and propagate them.

  CGSize boundsSize = self.view.bounds.size;
  if (CGSizeEqualToSize(self.node.primitiveTraitCollection.containerSize, boundsSize) == NO) {
    [UIView performWithoutAnimation:^{
      A_SPrimitiveTraitCollection traitCollection = [self primitiveTraitCollectionForUITraitCollection:self.traitCollection];
      traitCollection.containerSize = boundsSize;
        
      // this method will call measure
      [self propagateNewTraitCollection:traitCollection];
    }];
  } else {
    // Call layoutThatFits: to let the node prepare for a layout that will happen shortly in the layout pass of the view.
    // If the node's constrained size didn't change between the last layout pass it's a no-op
    [_node layoutThatFits:[self nodeConstrainedSize]];
  }
}

- (void)viewDidLayoutSubviews
{
  if (_ensureDisplayed && self.neverShowPlaceholders) {
    _ensureDisplayed = NO;
    [_node recursivelyEnsureDisplaySynchronously:YES];
  }
  [super viewDidLayoutSubviews];
}

A_SVisibilityDidMoveToParentViewController;

- (void)viewWillAppear:(BOOL)animated
{
  as_activity_create_for_scope("A_SViewController will appear");
  as_log_debug(A_SNodeLog(), "View controller %@ will appear", self);

  [super viewWillAppear:animated];

  _ensureDisplayed = YES;

  // A layout pass is forced this early to get nodes like A_SCollectionNode, A_STableNode etc.
  // into the hierarchy before UIKit applies the scroll view inset adjustments, if automatic subnode management
  // is enabled. Otherwise the insets would not be applied.
  [_node.view layoutIfNeeded];
  
  if (_parentManagesVisibilityDepth == NO) {
    [self setVisibilityDepth:0];
  }
}

A_SVisibilitySetVisibilityDepth;

A_SVisibilityViewDidDisappearImplementation;

A_SVisibilityDepthImplementation;

- (void)visibilityDepthDidChange
{
  A_SLayoutRangeMode rangeMode = A_SLayoutRangeModeForVisibilityDepth(self.visibilityDepth);
#if A_SEnableVerboseLogging
  NSString *rangeModeString;
  switch (rangeMode) {
    case A_SLayoutRangeModeMinimum:
      rangeModeString = @"Minimum";
      break;
      
    case A_SLayoutRangeModeFull:
      rangeModeString = @"Full";
      break;
      
    case A_SLayoutRangeModeVisibleOnly:
      rangeModeString = @"Visible Only";
      break;
      
    case A_SLayoutRangeModeLowMemory:
      rangeModeString = @"Low Memory";
      break;
      
    default:
      break;
  }
  as_log_verbose(A_SNodeLog(), "Updating visibility of %@ to: %@ (visibility depth: %zd)", self, rangeModeString, self.visibilityDepth);
#endif
  [self updateCurrentRangeModeWithModeIfPossible:rangeMode];
}

#pragma mark - Automatic range mode

- (BOOL)automaticallyAdjustRangeModeBasedOnViewEvents
{
  return _automaticallyAdjustRangeModeBasedOnViewEvents;
}

- (void)setAutomaticallyAdjustRangeModeBasedOnViewEvents:(BOOL)automaticallyAdjustRangeModeBasedOnViewEvents
{
  if (automaticallyAdjustRangeModeBasedOnViewEvents != _automaticallyAdjustRangeModeBasedOnViewEvents) {
    if (automaticallyAdjustRangeModeBasedOnViewEvents && _selfConformsToRangeModeProtocol == NO && _nodeConformsToRangeModeProtocol == NO) {
      NSLog(@"Warning: automaticallyAdjustRangeModeBasedOnViewEvents set to YES in %@, but range mode updating is not possible because neither view controller nor node %@ conform to A_SRangeControllerUpdateRangeProtocol.", self, _node);
    }
    _automaticallyAdjustRangeModeBasedOnViewEvents = automaticallyAdjustRangeModeBasedOnViewEvents;
  }
}

- (void)updateCurrentRangeModeWithModeIfPossible:(A_SLayoutRangeMode)rangeMode
{
  if (!_automaticallyAdjustRangeModeBasedOnViewEvents) {
    return;
  }
  
  if (_selfConformsToRangeModeProtocol) {
    id<A_SRangeControllerUpdateRangeProtocol> rangeUpdater = (id<A_SRangeControllerUpdateRangeProtocol>)self;
    [rangeUpdater updateCurrentRangeWithMode:rangeMode];
  }
  
  if (_nodeConformsToRangeModeProtocol) {
    id<A_SRangeControllerUpdateRangeProtocol> rangeUpdater = (id<A_SRangeControllerUpdateRangeProtocol>)_node;
    [rangeUpdater updateCurrentRangeWithMode:rangeMode];
  }
}

#pragma mark - Layout Helpers

- (A_SSizeRange)nodeConstrainedSize
{
  return A_SSizeRangeMake(self.view.bounds.size);
}

- (A_SInterfaceState)interfaceState
{
  return _node.interfaceState;
}

#pragma mark - A_STraitEnvironment

- (A_SPrimitiveTraitCollection)primitiveTraitCollectionForUITraitCollection:(UITraitCollection *)traitCollection
{
  if (self.overrideDisplayTraitsWithTraitCollection) {
    A_STraitCollection *asyncTraitCollection = self.overrideDisplayTraitsWithTraitCollection(traitCollection);
    return [asyncTraitCollection primitiveTraitCollection];
  }
  
  A_SDisplayNodeAssertMainThread();
  A_SPrimitiveTraitCollection asyncTraitCollection = A_SPrimitiveTraitCollectionFromUITraitCollection(traitCollection);
  asyncTraitCollection.containerSize = self.view.frame.size;
  return asyncTraitCollection;
}

- (void)propagateNewTraitCollection:(A_SPrimitiveTraitCollection)traitCollection
{
  A_SPrimitiveTraitCollection oldTraitCollection = self.node.primitiveTraitCollection;
  
  if (A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(traitCollection, oldTraitCollection) == NO) {
    as_activity_scope_verbose(as_activity_create("Propagate A_SViewController trait collection", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
    as_log_debug(A_SNodeLog(), "Propagating new traits for %@: %@", self, NSStringFromA_SPrimitiveTraitCollection(traitCollection));
    self.node.primitiveTraitCollection = traitCollection;
    
    NSArray<id<A_SLayoutElement>> *children = [self.node sublayoutElements];
    for (id<A_SLayoutElement> child in children) {
      A_STraitCollectionPropagateDown(child, traitCollection);
    }
    
    // Once we've propagated all the traits, layout this node.
    // Remeasure the node with the latest constrained size – old constrained size may be incorrect.
    as_activity_scope_verbose(as_activity_create("Layout A_SViewController node with new traits", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
    [_node layoutThatFits:[self nodeConstrainedSize]];
  }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
  [super traitCollectionDidChange:previousTraitCollection];
  
  A_SPrimitiveTraitCollection traitCollection = [self primitiveTraitCollectionForUITraitCollection:self.traitCollection];
  traitCollection.containerSize = self.view.bounds.size;
  [self propagateNewTraitCollection:traitCollection];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  
  A_SPrimitiveTraitCollection traitCollection = _node.primitiveTraitCollection;
  traitCollection.containerSize = self.view.bounds.size;
  [self propagateNewTraitCollection:traitCollection];
}

@end
