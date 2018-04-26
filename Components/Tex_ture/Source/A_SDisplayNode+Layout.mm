//
//  A_SDisplayNode+Layout.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>
#import <Async_DisplayKit/A_SLog.h>

#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>

#pragma mark -
#pragma mark - A_SDisplayNode (A_SLayoutElement)

@implementation A_SDisplayNode (A_SLayoutElement)

#pragma mark <A_SLayoutElement>

- (BOOL)implementsLayoutMethod
{
  A_SDN::MutexLocker l(__instanceLock__);
  return (_methodOverrides & (A_SDisplayNodeMethodOverrideLayoutSpecThatFits |
                              A_SDisplayNodeMethodOverrideCalcLayoutThatFits |
                              A_SDisplayNodeMethodOverrideCalcSizeThatFits)) != 0 || _layoutSpecBlock != nil;
}


- (A_SLayoutElementStyle *)style
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_style == nil) {
    _style = [[A_SLayoutElementStyle alloc] init];
  }
  return _style;
}

- (A_SLayoutElementType)layoutElementType
{
  return A_SLayoutElementTypeDisplayNode;
}

- (NSArray<id<A_SLayoutElement>> *)sublayoutElements
{
  return self.subnodes;
}

#pragma mark Measurement Pass

- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize
{
  return [self layoutThatFits:constrainedSize parentSize:constrainedSize.max];
}

- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize parentSize:(CGSize)parentSize
{
  A_SDN::MutexLocker l(__instanceLock__);

  // If one or multiple layout transitions are in flight it still can happen that layout information is requested
  // on other threads. As the pending and calculated layout to be updated in the layout transition in here just a
  // layout calculation wil be performed without side effect
  if ([self _isLayoutTransitionInvalid]) {
    return [self calculateLayoutThatFits:constrainedSize restrictedToSize:self.style.size relativeToParentSize:parentSize];
  }

  A_SLayout *layout = nil;
  NSUInteger version = _layoutVersion;
  if (_calculatedDisplayNodeLayout->isValid(constrainedSize, parentSize, version)) {
    A_SDisplayNodeAssertNotNil(_calculatedDisplayNodeLayout->layout, @"-[A_SDisplayNode layoutThatFits:parentSize:] _calculatedDisplayNodeLayout->layout should not be nil! %@", self);
    layout = _calculatedDisplayNodeLayout->layout;
  } else if (_pendingDisplayNodeLayout != nullptr && _pendingDisplayNodeLayout->isValid(constrainedSize, parentSize, version)) {
    A_SDisplayNodeAssertNotNil(_pendingDisplayNodeLayout->layout, @"-[A_SDisplayNode layoutThatFits:parentSize:] _pendingDisplayNodeLayout->layout should not be nil! %@", self);
    layout = _pendingDisplayNodeLayout->layout;
  } else {
    // Create a pending display node layout for the layout pass
    layout = [self calculateLayoutThatFits:constrainedSize
                          restrictedToSize:self.style.size
                      relativeToParentSize:parentSize];
    _pendingDisplayNodeLayout = std::make_shared<A_SDisplayNodeLayout>(layout, constrainedSize, parentSize, version);
    A_SDisplayNodeAssertNotNil(layout, @"-[A_SDisplayNode layoutThatFits:parentSize:] newly calculated layout should not be nil! %@", self);
  }
  
  return layout ?: [A_SLayout layoutWithLayoutElement:self size:{0, 0}];
}

#pragma mark A_SLayoutElementStyleExtensibility

A_SLayoutElementStyleExtensibilityForwarding

#pragma mark A_SPrimitiveTraitCollection

- (A_SPrimitiveTraitCollection)primitiveTraitCollection
{
  return _primitiveTraitCollection.load();
}

- (void)setPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traitCollection
{
  if (A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(traitCollection, _primitiveTraitCollection.load()) == NO) {
    _primitiveTraitCollection = traitCollection;
    A_SDisplayNodeLogEvent(self, @"asyncTraitCollectionDidChange: %@", NSStringFromA_SPrimitiveTraitCollection(traitCollection));

    [self asyncTraitCollectionDidChange];
  }
}

- (A_STraitCollection *)asyncTraitCollection
{
  return [A_STraitCollection traitCollectionWithA_SPrimitiveTraitCollection:self.primitiveTraitCollection];
}

#pragma mark - A_SLayoutElementAsciiArtProtocol

- (NSString *)asciiArtString
{
  return [A_SLayoutSpec asciiArtStringForChildren:@[] parentName:[self asciiArtName]];
}

- (NSString *)asciiArtName
{
  NSMutableString *result = [NSMutableString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding];
  if (_debugName) {
    [result appendFormat:@" (%@)", _debugName];
  }
  return result;
}

@end

#pragma mark -
#pragma mark - A_SDisplayNode (A_SLayout)

@implementation A_SDisplayNode (A_SLayout)

- (void)setLayoutSpecBlock:(A_SLayoutSpecBlock)layoutSpecBlock
{
  // For now there should never be an override of layoutSpecThatFits: and a layoutSpecBlock together.
  A_SDisplayNodeAssert(!(_methodOverrides & A_SDisplayNodeMethodOverrideLayoutSpecThatFits),
                      @"Nodes with a .layoutSpecBlock must not also implement -layoutSpecThatFits:");
  A_SDN::MutexLocker l(__instanceLock__);
  _layoutSpecBlock = layoutSpecBlock;
}

- (A_SLayoutSpecBlock)layoutSpecBlock
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _layoutSpecBlock;
}

- (A_SLayout *)calculatedLayout
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _calculatedDisplayNodeLayout->layout;
}

- (CGSize)calculatedSize
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_pendingDisplayNodeLayout != nullptr) {
    return _pendingDisplayNodeLayout->layout.size;
  }
  return _calculatedDisplayNodeLayout->layout.size;
}

- (A_SSizeRange)constrainedSizeForCalculatedLayout
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [self _locked_constrainedSizeForCalculatedLayout];
}

- (A_SSizeRange)_locked_constrainedSizeForCalculatedLayout
{
  if (_pendingDisplayNodeLayout != nullptr) {
    return _pendingDisplayNodeLayout->constrainedSize;
  }
  return _calculatedDisplayNodeLayout->constrainedSize;
}

@end

#pragma mark -
#pragma mark - A_SDisplayNode (A_SLayoutElementStylability)

@implementation A_SDisplayNode (A_SLayoutElementStylability)

- (instancetype)styledWithBlock:(A_S_NOESCAPE void (^)(__kindof A_SLayoutElementStyle *style))styleBlock
{
  styleBlock(self.style);
  return self;
}

@end

#pragma mark -
#pragma mark - A_SDisplayNode (A_SLayoutInternal)

@implementation A_SDisplayNode (A_SLayoutInternal)

/**
 * @abstract Informs the root node that the intrinsic size of the receiver is no longer valid.
 *
 * @discussion The size of a root node is determined by each subnode. Calling invalidateSize will let the root node know
 * that the intrinsic size of the receiver node is no longer valid and a resizing of the root node needs to happen.
 */
- (void)_u_setNeedsLayoutFromAbove
{
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock);
  as_activity_create_for_scope("Set needs layout from above");
  A_SDisplayNodeAssertThreadAffinity(self);

  // Mark the node for layout in the next layout pass
  [self setNeedsLayout];
  
  __instanceLock__.lock();
  // Escalate to the root; entire tree must allow adjustments so the layout fits the new child.
  // Much of the layout will be re-used as cached (e.g. other items in an unconstrained stack)
  A_SDisplayNode *supernode = _supernode;
  __instanceLock__.unlock();
  
  if (supernode) {
    // Threading model requires that we unlock before calling a method on our parent.
    [supernode _u_setNeedsLayoutFromAbove];
  } else {
    // Let the root node method know that the size was invalidated
    [self _rootNodeDidInvalidateSize];
  }
}

- (void)_rootNodeDidInvalidateSize
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  __instanceLock__.lock();
  
  // We are the root node and need to re-flow the layout; at least one child needs a new size.
  CGSize boundsSizeForLayout = A_SCeilSizeValues(self.bounds.size);

  // Figure out constrainedSize to use
  A_SSizeRange constrainedSize = A_SSizeRangeMake(boundsSizeForLayout);
  if (_pendingDisplayNodeLayout != nullptr) {
    constrainedSize = _pendingDisplayNodeLayout->constrainedSize;
  } else if (_calculatedDisplayNodeLayout->layout != nil) {
    constrainedSize = _calculatedDisplayNodeLayout->constrainedSize;
  }

  __instanceLock__.unlock();

  // Perform a measurement pass to get the full tree layout, adapting to the child's new size.
  A_SLayout *layout = [self layoutThatFits:constrainedSize];
  
  // Check if the returned layout has a different size than our current bounds.
  if (CGSizeEqualToSize(boundsSizeForLayout, layout.size) == NO) {
    // If so, inform our container we need an update (e.g Table, Collection, ViewController, etc).
    [self displayNodeDidInvalidateSizeNewSize:layout.size];
  }
}

- (void)displayNodeDidInvalidateSizeNewSize:(CGSize)size
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  // The default implementation of display node changes the size of itself to the new size
  CGRect oldBounds = self.bounds;
  CGSize oldSize = oldBounds.size;
  CGSize newSize = size;
  
  if (! CGSizeEqualToSize(oldSize, newSize)) {
    self.bounds = (CGRect){ oldBounds.origin, newSize };
    
    // Frame's origin must be preserved. Since it is computed from bounds size, anchorPoint
    // and position (see frame setter in A_SDisplayNode+UIViewBridge), position needs to be adjusted.
    CGPoint anchorPoint = self.anchorPoint;
    CGPoint oldPosition = self.position;
    CGFloat xDelta = (newSize.width - oldSize.width) * anchorPoint.x;
    CGFloat yDelta = (newSize.height - oldSize.height) * anchorPoint.y;
    self.position = CGPointMake(oldPosition.x + xDelta, oldPosition.y + yDelta);
  }
}

- (void)_u_measureNodeWithBoundsIfNecessary:(CGRect)bounds
{
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock);
  A_SDN::MutexLocker l(__instanceLock__);
  // Check if we are a subnode in a layout transition.
  // In this case no measurement is needed as it's part of the layout transition
  if ([self _isLayoutTransitionInvalid]) {
    return;
  }
  
  CGSize boundsSizeForLayout = A_SCeilSizeValues(bounds.size);

  // Prefer _pendingDisplayNodeLayout over _calculatedDisplayNodeLayout (if exists, it's the newest)
  // If there is no _pending, check if _calculated is valid to reuse (avoiding recalculation below).
  if (_pendingDisplayNodeLayout == nullptr || _pendingDisplayNodeLayout->version < _layoutVersion) {
    if (_calculatedDisplayNodeLayout->version >= _layoutVersion
        && (_calculatedDisplayNodeLayout->requestedLayoutFromAbove == YES
            || CGSizeEqualToSize(_calculatedDisplayNodeLayout->layout.size, boundsSizeForLayout))) {
      return;
    }
  }
  
  as_activity_create_for_scope("Update node layout for current bounds");
  as_log_verbose(A_SLayoutLog(), "Node %@, bounds size %@, calculatedSize %@, calculatedIsDirty %d", self, NSStringFromCGSize(boundsSizeForLayout), NSStringFromCGSize(_calculatedDisplayNodeLayout->layout.size), _calculatedDisplayNodeLayout->version < _layoutVersion.load());
  // _calculatedDisplayNodeLayout is not reusable we need to transition to a new one
  [self cancelLayoutTransition];
  
  BOOL didCreateNewContext = NO;
  A_SLayoutElementContext *context = A_SLayoutElementGetCurrentContext();
  if (context == nil) {
    context = [[A_SLayoutElementContext alloc] init];
    A_SLayoutElementPushContext(context);
    didCreateNewContext = YES;
  }
  
  // Figure out previous and pending layouts for layout transition
  std::shared_ptr<A_SDisplayNodeLayout> nextLayout = _pendingDisplayNodeLayout;
  #define layoutSizeDifferentFromBounds !CGSizeEqualToSize(nextLayout->layout.size, boundsSizeForLayout)
  
  // nextLayout was likely created by a call to layoutThatFits:, check if it is valid and can be applied.
  // If our bounds size is different than it, or invalid, recalculate.  Use #define to avoid nullptr->
  BOOL pendingLayoutApplicable = NO;
  if (nextLayout == nullptr) {
    as_log_verbose(A_SLayoutLog(), "No pending layout.");
  } else if (nextLayout->version < _layoutVersion) {
    as_log_verbose(A_SLayoutLog(), "Pending layout is stale.");
  } else if (layoutSizeDifferentFromBounds) {
    as_log_verbose(A_SLayoutLog(), "Pending layout size %@ doesn't match bounds size.", NSStringFromCGSize(nextLayout->layout.size));
  } else {
    as_log_verbose(A_SLayoutLog(), "Using pending layout %@.", nextLayout->layout);
    pendingLayoutApplicable = YES;
  }

  if (!pendingLayoutApplicable) {
    as_log_verbose(A_SLayoutLog(), "Measuring with previous constrained size.");
    // Use the last known constrainedSize passed from a parent during layout (if never, use bounds).
    NSUInteger version = _layoutVersion;
    A_SSizeRange constrainedSize = [self _locked_constrainedSizeForLayoutPass];
    A_SLayout *layout = [self calculateLayoutThatFits:constrainedSize
                                    restrictedToSize:self.style.size
                                relativeToParentSize:boundsSizeForLayout];
    nextLayout = std::make_shared<A_SDisplayNodeLayout>(layout, constrainedSize, boundsSizeForLayout, version);
    // Now that the constrained size of pending layout might have been reused, the layout is useless
    // Release it and any orphaned subnodes it retains
    _pendingDisplayNodeLayout = nullptr;
  }
  
  if (didCreateNewContext) {
    A_SLayoutElementPopContext();
  }
  
  // If our new layout's desired size for self doesn't match current size, ask our parent to update it.
  // This can occur for either pre-calculated or newly-calculated layouts.
  if (nextLayout->requestedLayoutFromAbove == NO
      && CGSizeEqualToSize(boundsSizeForLayout, nextLayout->layout.size) == NO) {
    as_log_verbose(A_SLayoutLog(), "Layout size doesn't match bounds size. Requesting layout from above.");
    // The layout that we have specifies that this node (self) would like to be a different size
    // than it currently is.  Because that size has been computed within the constrainedSize, we
    // expect that calling setNeedsLayoutFromAbove will result in our parent resizing us to this.
    // However, in some cases apps may manually interfere with this (setting a different bounds).
    // In this case, we need to detect that we've already asked to be resized to match this
    // particular A_SLayout object, and shouldn't loop asking again unless we have a different A_SLayout.
    nextLayout->requestedLayoutFromAbove = YES;
    __instanceLock__.unlock();
    [self _u_setNeedsLayoutFromAbove];
    __instanceLock__.lock();
    // Update the layout's version here because _u_setNeedsLayoutFromAbove calls __setNeedsLayout which in turn increases _layoutVersion
    // Failing to do this will cause the layout to be invalid immediately 
    nextLayout->version = _layoutVersion;
  }

  // Prepare to transition to nextLayout
  A_SDisplayNodeAssertNotNil(nextLayout->layout, @"nextLayout->layout should not be nil! %@", self);
  _pendingLayoutTransition = [[A_SLayoutTransition alloc] initWithNode:self
                                                        pendingLayout:nextLayout
                                                       previousLayout:_calculatedDisplayNodeLayout];

  // If a parent is currently executing a layout transition, perform our layout application after it.
  if (A_SHierarchyStateIncludesLayoutPending(_hierarchyState) == NO) {
    // If no transition, apply our new layout immediately (common case).
    [self _completePendingLayoutTransition];
  }
}

- (A_SSizeRange)_locked_constrainedSizeForLayoutPass
{
  // TODO: The logic in -_u_setNeedsLayoutFromAbove seems correct and doesn't use this method.
  // logic seems correct.  For what case does -this method need to do the CGSizeEqual checks?
  // IF WE CAN REMOVE BOUNDS CHECKS HERE, THEN WE CAN ALSO REMOVE "REQUESTED FROM ABOVE" CHECK
  
  CGSize boundsSizeForLayout = A_SCeilSizeValues(self.threadSafeBounds.size);
  
  // Checkout if constrained size of pending or calculated display node layout can be used
  if (_pendingDisplayNodeLayout != nullptr
      && (_pendingDisplayNodeLayout->requestedLayoutFromAbove
           || CGSizeEqualToSize(_pendingDisplayNodeLayout->layout.size, boundsSizeForLayout))) {
    // We assume the size from the last returned layoutThatFits: layout was applied so use the pending display node
    // layout constrained size
    return _pendingDisplayNodeLayout->constrainedSize;
  } else if (_calculatedDisplayNodeLayout->layout != nil
             && (_calculatedDisplayNodeLayout->requestedLayoutFromAbove
                 || CGSizeEqualToSize(_calculatedDisplayNodeLayout->layout.size, boundsSizeForLayout))) {
    // We assume the  _calculatedDisplayNodeLayout is still valid and the frame is not different
    return _calculatedDisplayNodeLayout->constrainedSize;
  } else {
    // In this case neither the _pendingDisplayNodeLayout or the _calculatedDisplayNodeLayout constrained size can
    // be reused, so the current bounds is used. This is usual the case if a frame was set manually that differs to
    // the one returned from layoutThatFits: or layoutThatFits: was never called
    return A_SSizeRangeMake(boundsSizeForLayout);
  }
}

- (void)_layoutSublayouts
{
  A_SDisplayNodeAssertThreadAffinity(self);
  A_SDisplayNodeAssertLockUnownedByCurrentThread(__instanceLock__);
  
  A_SLayout *layout;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (_calculatedDisplayNodeLayout->version < _layoutVersion) {
      return;
    }
    layout = _calculatedDisplayNodeLayout->layout;
  }
  
  for (A_SDisplayNode *node in self.subnodes) {
    CGRect frame = [layout frameForElement:node];
    if (CGRectIsNull(frame)) {
      // There is no frame for this node in our layout.
      // This currently can happen if we get a CA layout pass
      // while waiting for the client to run animateLayoutTransition:
    } else {
      node.frame = frame;
    }
  }
}

@end

#pragma mark -
#pragma mark - A_SDisplayNode (A_SAutomatic Subnode Management)

@implementation A_SDisplayNode (A_SAutomaticSubnodeManagement)

#pragma mark Automatically Manages Subnodes

- (BOOL)automaticallyManagesSubnodes
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _automaticallyManagesSubnodes;
}

- (void)setAutomaticallyManagesSubnodes:(BOOL)automaticallyManagesSubnodes
{
  A_SDN::MutexLocker l(__instanceLock__);
  _automaticallyManagesSubnodes = automaticallyManagesSubnodes;
}

@end

#pragma mark -
#pragma mark - A_SDisplayNode (A_SLayoutTransition)

@implementation A_SDisplayNode (A_SLayoutTransition)

- (BOOL)_isLayoutTransitionInvalid
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [self _locked_isLayoutTransitionValid];
}

- (BOOL)_locked_isLayoutTransitionValid
{
  if (A_SHierarchyStateIncludesLayoutPending(_hierarchyState)) {
    A_SLayoutElementContext *context = A_SLayoutElementGetCurrentContext();
    if (context == nil || _pendingTransitionID != context.transitionID) {
      return YES;
    }
  }
  return NO;
}

/// Starts a new transition and returns the transition id
- (int32_t)_startNewTransition
{
  static std::atomic<int32_t> gNextTransitionID;
  int32_t newTransitionID = gNextTransitionID.fetch_add(1) + 1;
  _transitionID = newTransitionID;
  return newTransitionID;
}

/// Returns NO if there was no transition to cancel/finish.
- (BOOL)_finishOrCancelTransition
{
  int32_t oldValue = _transitionID.exchange(A_SLayoutElementContextInvalidTransitionID);
  return oldValue != A_SLayoutElementContextInvalidTransitionID;
}

#pragma mark Layout Transition

- (void)transitionLayoutWithAnimation:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(void(^)())completion
{
  A_SDisplayNodeAssertMainThread();

  A_SSizeRange sizeRange;
  {
    A_SDN::MutexLocker l(__instanceLock__);
    sizeRange = [self _locked_constrainedSizeForLayoutPass];
  }

  [self transitionLayoutWithSizeRange:sizeRange
                             animated:animated
                   shouldMeasureAsync:shouldMeasureAsync
                measurementCompletion:completion];
  
}

- (void)transitionLayoutWithSizeRange:(A_SSizeRange)constrainedSize
                             animated:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(void(^)())completion
{
  A_SDisplayNodeAssertMainThread();
  as_activity_create_for_scope("Transition node layout");
  as_log_debug(A_SLayoutLog(), "Transition layout for %@ sizeRange %@ anim %d asyncMeasure %d", self, NSStringFromA_SSizeRange(constrainedSize), animated, shouldMeasureAsync);
  
  if (constrainedSize.max.width <= 0.0 || constrainedSize.max.height <= 0.0) {
    // Using CGSizeZero for the sizeRange can cause negative values in client layout code.
    // Most likely called transitionLayout: without providing a size, before first layout pass.
    as_log_verbose(A_SLayoutLog(), "Ignoring transition due to bad size range.");
    return;
  }
    
  {
    A_SDN::MutexLocker l(__instanceLock__);

    // Check if we are a subnode in a layout transition.
    // In this case no measurement is needed as we're part of the layout transition.
    if ([self _locked_isLayoutTransitionValid]) {
      return;
    }

    if (A_SHierarchyStateIncludesLayoutPending(_hierarchyState)) {
      A_SDisplayNodeAssert(NO, @"Can't start a transition when one of the supernodes is performing one.");
      return;
    }
  }

  // Invalidate calculated layout because this method acts as an animated "setNeedsLayout" for nodes.
  // If the user has reconfigured the node and calls this, we should never return a stale layout
  // for subsequent calls to layoutThatFits: regardless of size range. We choose this method rather than
  // -setNeedsLayout because that method also triggers a CA layout invalidation, which isn't necessary at this time.
  // See https://github.com/Tex_tureGroup/Tex_ture/issues/463
  [self invalidateCalculatedLayout];

  // Every new layout transition has a transition id associated to check in subsequent transitions for cancelling
  int32_t transitionID = [self _startNewTransition];
  as_log_verbose(A_SLayoutLog(), "Transition ID is %d", transitionID);
  // NOTE: This block captures self. It's cheaper than hitting the weak table.
  asdisplaynode_iscancelled_block_t isCancelled = ^{
    BOOL result = (_transitionID != transitionID);
    if (result) {
      as_log_verbose(A_SLayoutLog(), "Transition %d canceled, superseded by %d", transitionID, _transitionID.load());
    }
    return result;
  };

  // Move all subnodes in layout pending state for this transition
  A_SDisplayNodePerformBlockOnEverySubnode(self, NO, ^(A_SDisplayNode * _Nonnull node) {
    A_SDisplayNodeAssert(node->_transitionID == A_SLayoutElementContextInvalidTransitionID, @"Can't start a transition when one of the subnodes is performing one.");
    node.hierarchyState |= A_SHierarchyStateLayoutPending;
    node->_pendingTransitionID = transitionID;
  });
  
  // Transition block that executes the layout transition
  void (^transitionBlock)(void) = ^{
    if (isCancelled()) {
      return;
    }
    
    // Perform a full layout creation pass with passed in constrained size to create the new layout for the transition
    NSUInteger newLayoutVersion = _layoutVersion;
    A_SLayout *newLayout;
    {
      A_SDN::MutexLocker l(__instanceLock__);

      A_SLayoutElementContext *ctx = [[A_SLayoutElementContext alloc] init];
      ctx.transitionID = transitionID;
      A_SLayoutElementPushContext(ctx);

      BOOL automaticallyManagesSubnodesDisabled = (self.automaticallyManagesSubnodes == NO);
      self.automaticallyManagesSubnodes = YES; // Temporary flag for 1.9.x
      newLayout = [self calculateLayoutThatFits:constrainedSize
                               restrictedToSize:self.style.size
                           relativeToParentSize:constrainedSize.max];
      if (automaticallyManagesSubnodesDisabled) {
        self.automaticallyManagesSubnodes = NO; // Temporary flag for 1.9.x
      }
      
      A_SLayoutElementPopContext();
    }
    
    if (isCancelled()) {
      return;
    }
    
    A_SPerformBlockOnMainThread(^{
      if (isCancelled()) {
        return;
      }
      as_activity_create_for_scope("Commit layout transition");
      A_SLayoutTransition *pendingLayoutTransition;
      _A_STransitionContext *pendingLayoutTransitionContext;
      {
        // Grab __instanceLock__ here to make sure this transition isn't invalidated
        // right after it passed the validation test and before it proceeds
        A_SDN::MutexLocker l(__instanceLock__);
        
        // Update calculated layout
        auto previousLayout = _calculatedDisplayNodeLayout;
        auto pendingLayout = std::make_shared<A_SDisplayNodeLayout>(newLayout,
                                                                   constrainedSize,
                                                                   constrainedSize.max,
                                                                   newLayoutVersion);
        [self _locked_setCalculatedDisplayNodeLayout:pendingLayout];
        
        // Setup pending layout transition for animation
        _pendingLayoutTransition = pendingLayoutTransition = [[A_SLayoutTransition alloc] initWithNode:self
                                                                                        pendingLayout:pendingLayout
                                                                                       previousLayout:previousLayout];
        // Setup context for pending layout transition. we need to hold a strong reference to the context
        _pendingLayoutTransitionContext = pendingLayoutTransitionContext = [[_A_STransitionContext alloc] initWithAnimation:animated
                                                                                                            layoutDelegate:_pendingLayoutTransition
                                                                                                        completionDelegate:self];
      }
      
      // Apply complete layout transitions for all subnodes
      {
        as_activity_create_for_scope("Complete pending layout transitions for subtree");
        A_SDisplayNodePerformBlockOnEverySubnode(self, NO, ^(A_SDisplayNode * _Nonnull node) {
          [node _completePendingLayoutTransition];
          node.hierarchyState &= (~A_SHierarchyStateLayoutPending);
        });
      }
      
      // Measurement pass completion
      // Give the subclass a change to hook into before calling the completion block
      [self _layoutTransitionMeasurementDidFinish];
      if (completion) {
        completion();
      }
      
      // Apply the subnode insertion immediately to be able to animate the nodes
      [pendingLayoutTransition applySubnodeInsertions];
      
      // Kick off animating the layout transition
      {
        as_activity_create_for_scope("Animate layout transition");
        [self animateLayoutTransition:pendingLayoutTransitionContext];
      }
      
      // Mark transaction as finished
      [self _finishOrCancelTransition];
    });
  };
  
  // Start transition based on flag on current or background thread
  if (shouldMeasureAsync) {
    A_SPerformBlockOnBackgroundThread(transitionBlock);
  } else {
    transitionBlock();
  }
}

- (void)cancelLayoutTransition
{
  if ([self _finishOrCancelTransition]) {
    // Tell subnodes to exit layout pending state and clear related properties
    A_SDisplayNodePerformBlockOnEverySubnode(self, NO, ^(A_SDisplayNode * _Nonnull node) {
      node.hierarchyState &= (~A_SHierarchyStateLayoutPending);
    });
  }
}

- (void)setDefaultLayoutTransitionDuration:(NSTimeInterval)defaultLayoutTransitionDuration
{
  A_SDN::MutexLocker l(__instanceLock__);
  _defaultLayoutTransitionDuration = defaultLayoutTransitionDuration;
}

- (NSTimeInterval)defaultLayoutTransitionDuration
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _defaultLayoutTransitionDuration;
}

- (void)setDefaultLayoutTransitionDelay:(NSTimeInterval)defaultLayoutTransitionDelay
{
  A_SDN::MutexLocker l(__instanceLock__);
  _defaultLayoutTransitionDelay = defaultLayoutTransitionDelay;
}

- (NSTimeInterval)defaultLayoutTransitionDelay
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _defaultLayoutTransitionDelay;
}

- (void)setDefaultLayoutTransitionOptions:(UIViewAnimationOptions)defaultLayoutTransitionOptions
{
  A_SDN::MutexLocker l(__instanceLock__);
  _defaultLayoutTransitionOptions = defaultLayoutTransitionOptions;
}

- (UIViewAnimationOptions)defaultLayoutTransitionOptions
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _defaultLayoutTransitionOptions;
}

#pragma mark <LayoutTransitioning>

/*
 * Hook for subclasses to perform an animation based on the given A_SContextTransitioning. By default a fade in and out
 * animation is provided.
 */
- (void)animateLayoutTransition:(id<A_SContextTransitioning>)context
{
  if ([context isAnimated] == NO) {
    [self _layoutSublayouts];
    [context completeTransition:YES];
    return;
  }
 
  A_SDisplayNode *node = self;
  
  NSAssert(node.isNodeLoaded == YES, @"Invalid node state");
  
  NSArray<A_SDisplayNode *> *removedSubnodes = [context removedSubnodes];
  NSMutableArray<A_SDisplayNode *> *insertedSubnodes = [[context insertedSubnodes] mutableCopy];
  NSMutableArray<A_SDisplayNode *> *movedSubnodes = [NSMutableArray array];
  
  NSMutableArray<_A_SAnimatedTransitionContext *> *insertedSubnodeContexts = [NSMutableArray array];
  NSMutableArray<_A_SAnimatedTransitionContext *> *removedSubnodeContexts = [NSMutableArray array];
  
  for (A_SDisplayNode *subnode in [context subnodesForKey:A_STransitionContextToLayoutKey]) {
    if ([insertedSubnodes containsObject:subnode] == NO) {
      // This is an existing subnode, check if it is resized, moved or both
      CGRect fromFrame = [context initialFrameForNode:subnode];
      CGRect toFrame = [context finalFrameForNode:subnode];
      if (CGSizeEqualToSize(fromFrame.size, toFrame.size) == NO) {
        [insertedSubnodes addObject:subnode];
      }
      if (CGPointEqualToPoint(fromFrame.origin, toFrame.origin) == NO) {
        [movedSubnodes addObject:subnode];
      }
    }
  }
  
  // Create contexts for inserted and removed subnodes
  for (A_SDisplayNode *insertedSubnode in insertedSubnodes) {
    [insertedSubnodeContexts addObject:[_A_SAnimatedTransitionContext contextForNode:insertedSubnode alpha:insertedSubnode.alpha]];
  }
  for (A_SDisplayNode *removedSubnode in removedSubnodes) {
    [removedSubnodeContexts addObject:[_A_SAnimatedTransitionContext contextForNode:removedSubnode alpha:removedSubnode.alpha]];
  }
  
  // Fade out inserted subnodes
  for (A_SDisplayNode *insertedSubnode in insertedSubnodes) {
    insertedSubnode.frame = [context finalFrameForNode:insertedSubnode];
    insertedSubnode.alpha = 0;
  }
  
  // Adjust groupOpacity for animation
  BOOL originAllowsGroupOpacity = node.allowsGroupOpacity;
  node.allowsGroupOpacity = YES;

  [UIView animateWithDuration:self.defaultLayoutTransitionDuration delay:self.defaultLayoutTransitionDelay options:self.defaultLayoutTransitionOptions animations:^{
    // Fade removed subnodes and views out
    for (A_SDisplayNode *removedSubnode in removedSubnodes) {
      removedSubnode.alpha = 0;
    }
    
    // Fade inserted subnodes in
    for (_A_SAnimatedTransitionContext *insertedSubnodeContext in insertedSubnodeContexts) {
      insertedSubnodeContext.node.alpha = insertedSubnodeContext.alpha;
    }
    
    // Update frame of self and moved subnodes
    CGSize fromSize = [context layoutForKey:A_STransitionContextFromLayoutKey].size;
    CGSize toSize = [context layoutForKey:A_STransitionContextToLayoutKey].size;
    BOOL isResized = (CGSizeEqualToSize(fromSize, toSize) == NO);
    if (isResized == YES) {
      CGPoint position = node.frame.origin;
      node.frame = CGRectMake(position.x, position.y, toSize.width, toSize.height);
    }
    for (A_SDisplayNode *movedSubnode in movedSubnodes) {
      movedSubnode.frame = [context finalFrameForNode:movedSubnode];
    }
  } completion:^(BOOL finished) {
    // Restore all removed subnode alpha values
    for (_A_SAnimatedTransitionContext *removedSubnodeContext in removedSubnodeContexts) {
      removedSubnodeContext.node.alpha = removedSubnodeContext.alpha;
    }
    
    // Restore group opacity
    node.allowsGroupOpacity = originAllowsGroupOpacity;
    
    // Subnode removals are automatically performed
    [context completeTransition:finished];
  }];
}

/**
 * Hook for subclasses to clean up nodes after the transition happened. Furthermore this can be used from subclasses
 * to manually perform deletions.
 */
- (void)didCompleteLayoutTransition:(id<A_SContextTransitioning>)context
{
  A_SDisplayNodeAssertMainThread();

  __instanceLock__.lock();
  A_SLayoutTransition *pendingLayoutTransition = _pendingLayoutTransition;
  __instanceLock__.unlock();

  [pendingLayoutTransition applySubnodeRemovals];
}

/**
 * Completes the pending layout transition immediately without going through the the Layout Transition Animation API
 */
- (void)_completePendingLayoutTransition
{
  __instanceLock__.lock();
  A_SLayoutTransition *pendingLayoutTransition = _pendingLayoutTransition;
  __instanceLock__.unlock();

  if (pendingLayoutTransition != nil) {
    [self _setCalculatedDisplayNodeLayout:pendingLayoutTransition.pendingLayout];
    [self _completeLayoutTransition:pendingLayoutTransition];
    [self _pendingLayoutTransitionDidComplete];
  }
}

/**
 * Can be directly called to commit the given layout transition immediately to complete without calling through to the
 * Layout Transition Animation API
 */
- (void)_completeLayoutTransition:(A_SLayoutTransition *)layoutTransition
{
  // Layout transition is not supported for nodes that do not have automatic subnode management enabled
  if (layoutTransition == nil || self.automaticallyManagesSubnodes == NO) {
    return;
  }

  // Trampoline to the main thread if necessary
  if (A_SDisplayNodeThreadIsMain() || layoutTransition.isSynchronous == NO) {
    [layoutTransition commitTransition];
  } else {
    // Subnode insertions and removals need to happen always on the main thread if at least one subnode is already loaded
    A_SPerformBlockOnMainThread(^{
      [layoutTransition commitTransition];
    });
  }
}

- (void)_assertSubnodeState
{
  // Verify that any orphaned nodes are removed.
  // This can occur in rare cases if main thread layout is flushed while a background layout is calculating.

  if (self.automaticallyManagesSubnodes == NO) {
    return;
  }

  NSArray *subnodes = [self subnodes];
  NSArray *sublayouts = _calculatedDisplayNodeLayout->layout.sublayouts;

  auto currentSubnodes = [[NSHashTable alloc] initWithOptions:NSHashTableObjectPointerPersonality
                                                     capacity:subnodes.count];
  auto layoutSubnodes  = [[NSHashTable alloc] initWithOptions:NSHashTableObjectPointerPersonality
                                                     capacity:sublayouts.count];;
  for (A_SDisplayNode *subnode in subnodes) {
    [currentSubnodes addObject:subnode];
  }

  for (A_SLayout *sublayout in sublayouts) {
    id <A_SLayoutElement> layoutElement = sublayout.layoutElement;
    A_SDisplayNodeAssert([layoutElement isKindOfClass:[A_SDisplayNode class]],
                        @"All calculatedLayouts should be flattened and only contain nodes!");
    [layoutSubnodes addObject:(A_SDisplayNode *)layoutElement];
  }

  // Verify that all subnodes that occur in the current A_SLayout tree are present in .subnodes array.
  if ([layoutSubnodes isSubsetOfHashTable:currentSubnodes] == NO) {
    // Note: This should be converted to an assertion after confirming it is rare.
    NSLog(@"Warning: node's layout includes subnodes that have not been added: node = %@, subnodes = %@, subnodes in layout = %@", self, currentSubnodes, layoutSubnodes);
  }

  // Verify that everything in the .subnodes array is present in the A_SLayout tree (and correct it if not).
  [currentSubnodes minusHashTable:layoutSubnodes];
  for (A_SDisplayNode *orphanedSubnode in currentSubnodes) {
    NSLog(@"Automatically removing orphaned subnode %@, from parent %@", orphanedSubnode, self);
    [orphanedSubnode removeFromSupernode];
  }
}

- (void)_pendingLayoutTransitionDidComplete
{
  // This assertion introduces a breaking behavior for nodes that has A_SM enabled but also manually manage some subnodes.
  // Let's gate it behind YOGA flag and remove it right after a branch cut.
#if YOGA
  [self _assertSubnodeState];
#endif

  // Subclass hook
  [self calculatedLayoutDidChange];

  // Grab lock after calling out to subclass
  A_SDN::MutexLocker l(__instanceLock__);

  // We generate placeholders at -layoutThatFits: time so that a node is guaranteed to have a placeholder ready to go.
  // This is also because measurement is usually asynchronous, but placeholders need to be set up synchronously.
  // First measurement is guaranteed to be before the node is onscreen, so we can create the image async. but still have it appear sync.
  if (_placeholderEnabled && !_placeholderImage && [self _locked_displaysAsynchronously]) {
    
    // Zero-sized nodes do not require a placeholder.
    A_SLayout *layout = _calculatedDisplayNodeLayout->layout;
    CGSize layoutSize = (layout ? layout.size : CGSizeZero);
    if (layoutSize.width * layoutSize.height <= 0.0) {
      return;
    }
    
    // If we've displayed our contents, we don't need a placeholder.
    // Contents is a thread-affined property and can't be read off main after loading.
    if (self.isNodeLoaded) {
      A_SPerformBlockOnMainThread(^{
        if (self.contents == nil) {
          _placeholderImage = [self placeholderImage];
        }
      });
    } else {
      if (self.contents == nil) {
        _placeholderImage = [self placeholderImage];
      }
    }
  }
  
  // Cleanup pending layout transition
  _pendingLayoutTransition = nil;
}

- (void)_setCalculatedDisplayNodeLayout:(std::shared_ptr<A_SDisplayNodeLayout>)displayNodeLayout
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setCalculatedDisplayNodeLayout:displayNodeLayout];
}

- (void)_locked_setCalculatedDisplayNodeLayout:(std::shared_ptr<A_SDisplayNodeLayout>)displayNodeLayout
{
  A_SDisplayNodeAssertTrue(displayNodeLayout->layout.layoutElement == self);
  A_SDisplayNodeAssertTrue(displayNodeLayout->layout.size.width >= 0.0);
  A_SDisplayNodeAssertTrue(displayNodeLayout->layout.size.height >= 0.0);
  
  // Flatten the layout if it wasn't done before (@see -calculateLayoutThatFits:).
  if ([A_SDisplayNode shouldStoreUnflattenedLayouts]) {
    _unflattenedLayout = displayNodeLayout->layout;
    displayNodeLayout->layout = [_unflattenedLayout filteredNodeLayoutTree];
  }

  _calculatedDisplayNodeLayout = displayNodeLayout;
}

@end
