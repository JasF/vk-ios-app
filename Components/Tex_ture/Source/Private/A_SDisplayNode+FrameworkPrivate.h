//
//  A_SDisplayNode+FrameworkPrivate.h
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

//
// The following methods are ONLY for use by _A_SDisplayLayer, _A_SDisplayView, and A_SDisplayNode.
// These methods must never be called or overridden by other classes.
//

#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

NS_ASSUME_NONNULL_BEGIN

@protocol A_SInterfaceStateDelegate;

/**
 Hierarchy state is propagated from nodes to all of their children when certain behaviors are required from the subtree.
 Examples include rasterization and external driving of the .interfaceState property.
 By passing this information explicitly, performance is optimized by avoiding iteration up the supernode chain.
 Lastly, this avoidance of supernode traversal protects against the possibility of deadlocks when a supernode is
 simultaneously attempting to materialize views / layers for its subtree (as many related methods require property locking)
 
 Note: as the hierarchy deepens, more state properties may be enabled.  However, state properties may never be disabled /
 cancelled below the point they are enabled.  They continue to the leaves of the hierarchy.
 */

typedef NS_OPTIONS(NSUInteger, A_SHierarchyState)
{
  /** The node may or may not have a supernode, but no supernode has a special hierarchy-influencing option enabled. */
  A_SHierarchyStateNormal                  = 0,
  /** The node has a supernode with .rasterizesSubtree = YES.
      Note: the root node of the rasterized subtree (the one with the property set on it) will NOT have this state set. */
  A_SHierarchyStateRasterized              = 1 << 0,
  /** The node or one of its supernodes is managed by a class like A_SRangeController.  Most commonly, these nodes are
      A_SCellNode objects or a subnode of one, and are used in A_STableView or A_SCollectionView.
      These nodes also receive regular updates to the .interfaceState property with more detailed status information. */
  A_SHierarchyStateRangeManaged            = 1 << 1,
  /** Down-propagated version of _flags.visibilityNotificationsDisabled.  This flag is very rarely set, but by having it
      locally available to nodes, they do not have to walk up supernodes at the critical points it is checked. */
  A_SHierarchyStateTransitioningSupernodes = 1 << 2,
  /** One of the supernodes of this node is performing a transition.
      Any layout calculated during this state should not be applied immediately, but pending until later. */
  A_SHierarchyStateLayoutPending           = 1 << 3,
};

A_SDISPLAYNODE_INLINE BOOL A_SHierarchyStateIncludesLayoutPending(A_SHierarchyState hierarchyState)
{
  return ((hierarchyState & A_SHierarchyStateLayoutPending) == A_SHierarchyStateLayoutPending);
}

A_SDISPLAYNODE_INLINE BOOL A_SHierarchyStateIncludesRangeManaged(A_SHierarchyState hierarchyState)
{
  return ((hierarchyState & A_SHierarchyStateRangeManaged) == A_SHierarchyStateRangeManaged);
}

A_SDISPLAYNODE_INLINE BOOL A_SHierarchyStateIncludesRasterized(A_SHierarchyState hierarchyState)
{
	return ((hierarchyState & A_SHierarchyStateRasterized) == A_SHierarchyStateRasterized);
}

A_SDISPLAYNODE_INLINE BOOL A_SHierarchyStateIncludesTransitioningSupernodes(A_SHierarchyState hierarchyState)
{
	return ((hierarchyState & A_SHierarchyStateTransitioningSupernodes) == A_SHierarchyStateTransitioningSupernodes);
}

__unused static NSString * _Nonnull NSStringFromA_SHierarchyState(A_SHierarchyState hierarchyState)
{
	NSMutableArray *states = [NSMutableArray array];
	if (hierarchyState == A_SHierarchyStateNormal) {
		[states addObject:@"Normal"];
	}
	if (A_SHierarchyStateIncludesRangeManaged(hierarchyState)) {
		[states addObject:@"RangeManaged"];
	}
	if (A_SHierarchyStateIncludesLayoutPending(hierarchyState)) {
		[states addObject:@"LayoutPending"];
	}
	if (A_SHierarchyStateIncludesRasterized(hierarchyState)) {
		[states addObject:@"Rasterized"];
	}
	if (A_SHierarchyStateIncludesTransitioningSupernodes(hierarchyState)) {
		[states addObject:@"TransitioningSupernodes"];
	}
	return [NSString stringWithFormat:@"{ %@ }", [states componentsJoinedByString:@" | "]];
}

@interface A_SDisplayNode () <A_SDescriptionProvider, A_SDebugDescriptionProvider>
{
@protected
  A_SInterfaceState _interfaceState;
  A_SHierarchyState _hierarchyState;
}

// The view class to use when creating a new display node instance. Defaults to _A_SDisplayView.
+ (Class)viewClass;

// Thread safe way to access the bounds of the node
@property (nonatomic, assign) CGRect threadSafeBounds;

// Returns the bounds of the node without reaching the view or layer
- (CGRect)_locked_threadSafeBounds;

// delegate to inform of A_SInterfaceState changes (used by A_SNodeController)
@property (nonatomic, weak) id<A_SInterfaceStateDelegate> interfaceStateDelegate;

// These methods are recursive, and either union or remove the provided interfaceState to all sub-elements.
- (void)enterInterfaceState:(A_SInterfaceState)interfaceState;
- (void)exitInterfaceState:(A_SInterfaceState)interfaceState;
- (void)recursivelySetInterfaceState:(A_SInterfaceState)interfaceState;

// These methods are recursive, and either union or remove the provided hierarchyState to all sub-elements.
- (void)enterHierarchyState:(A_SHierarchyState)hierarchyState;
- (void)exitHierarchyState:(A_SHierarchyState)hierarchyState;

// Changed before calling willEnterHierarchy / didExitHierarchy.
@property (readonly, assign, getter = isInHierarchy) BOOL inHierarchy;
// Call willEnterHierarchy if necessary and set inHierarchy = YES if visibility notifications are enabled on all of its parents
- (void)__enterHierarchy;
// Call didExitHierarchy if necessary and set inHierarchy = NO if visibility notifications are enabled on all of its parents
- (void)__exitHierarchy;

/**
 * @abstract Returns the Hierarchy State of the node.
 *
 * @return The current A_SHierarchyState of the node, indicating whether it is rasterized or managed by a range controller.
 *
 * @see A_SInterfaceState
 */
@property (nonatomic, readwrite) A_SHierarchyState hierarchyState;

/**
 * @abstract Return if the node is range managed or not
 *
 * @discussion Currently only set interface state on nodes in table and collection views. For other nodes, if they are
 * in the hierarchy we enable all A_SInterfaceState types with `A_SInterfaceStateInHierarchy`, otherwise `None`.
 */
- (BOOL)supportsRangeManagedInterfaceState;

- (BOOL)_locked_displaysAsynchronously;

// The two methods below will eventually be exposed, but their names are subject to change.
/**
 * @abstract Ensure that all rendering is complete for this node and its descendants.
 *
 * @discussion Calling this method on the main thread after a node is added to the view hierarchy will ensure that
 * placeholder states are never visible to the user.  It is used by A_STableView, A_SCollectionView, and A_SViewController
 * to implement their respective ".neverShowPlaceholders" option.
 *
 * If all nodes have layer.contents set and/or their layer does not have -needsDisplay set, the method will return immediately.
 *
 * This method is capable of handling a mixed set of nodes, with some not having started display, some in progress on an
 * asynchronous display operation, and some already finished.
 *
 * In order to guarantee against deadlocks, this method should only be called on the main thread.
 * It may block on the private queue, [_A_SDisplayLayer displayQueue]
 */
- (void)recursivelyEnsureDisplaySynchronously:(BOOL)synchronously;

/**
 * @abstract Calls -didExitPreloadState on the receiver and its subnode hierarchy.
 *
 * @discussion Clears any memory-intensive preloaded content.
 * This method is used to notify the node that it should purge any content that is both expensive to fetch and to
 * retain in memory.
 *
 * @see [A_SDisplayNode(Subclassing) didExitPreloadState] and [A_SDisplayNode(Subclassing) didEnterPreloadState]
 */
- (void)recursivelyClearPreloadedData;

/**
 * @abstract Calls -didEnterPreloadState on the receiver and its subnode hierarchy.
 *
 * @discussion Fetches content from remote sources for the current node and all subnodes.
 *
 * @see [A_SDisplayNode(Subclassing) didEnterPreloadState] and [A_SDisplayNode(Subclassing) didExitPreloadState]
 */
- (void)recursivelyPreload;

/**
 * @abstract Triggers a recursive call to -didEnterPreloadState when the node has an interfaceState of A_SInterfaceStatePreload
 */
- (void)setNeedsPreload;

/**
 * @abstract Allows a node to bypass all ensureDisplay passes.  Defaults to NO.
 *
 * @discussion Nodes that are expensive to draw and expected to have placeholder even with
 * .neverShowPlaceholders enabled should set this to YES.
 *
 * A_SImageNode uses the default of NO, as it is often used for UI images that are expected to synchronize with ensureDisplay.
 *
 * A_SNetworkImageNode and A_SMultiplexImageNode set this to YES, because they load data from a database or server,
 * and are expected to support a placeholder state given that display is often blocked on slow data fetching.
 */
@property (nonatomic, assign) BOOL shouldBypassEnsureDisplay;

/**
 * @abstract Checks whether a node should be scheduled for display, considering its current and new interface states.
 */
- (BOOL)shouldScheduleDisplayWithNewInterfaceState:(A_SInterfaceState)newInterfaceState;

@end


@interface A_SDisplayNode (A_SLayoutInternal)

/**
 * @abstract Informs the root node that the intrinsic size of the receiver is no longer valid.
 *
 * @discussion The size of a root node is determined by each subnode. Calling invalidateSize will let the root node know
 * that the intrinsic size of the receiver node is no longer valid and a resizing of the root node needs to happen.
 */
- (void)_u_setNeedsLayoutFromAbove;

/**
 * @abstract Subclass hook for nodes that are acting as root nodes. This method is called if one of the subnodes
 * size is invalidated and may need to result in a different size as the current calculated size.
 */
- (void)_rootNodeDidInvalidateSize;

/**
 * This method will confirm that the layout is up to date (and update if needed).
 * Importantly, it will also APPLY the layout to all of our subnodes if (unless parent is transitioning).
 */
- (void)_u_measureNodeWithBoundsIfNecessary:(CGRect)bounds;

/**
 * Layout all of the subnodes based on the sublayouts
 */
- (void)_layoutSublayouts;

@end

@interface A_SDisplayNode (A_SLayoutTransitionInternal)

/**
 * If one or multiple layout transitions are in flight this methods returns if the current layout transition that
 * happens in in this particular thread was invalidated through another thread is starting a transition for this node
 */
- (BOOL)_isLayoutTransitionInvalid;

/**
 * Internal method that can be overriden by subclasses to add specific behavior after the measurement of a layout
 * transition did finish.
 */
- (void)_layoutTransitionMeasurementDidFinish;

/**
 * Informs the node that hte pending layout transition did complete
 */
- (void)_completePendingLayoutTransition;

/**
 * Called if the pending layout transition did complete
 */
- (void)_pendingLayoutTransitionDidComplete;

@end

@interface UIView (A_SDisplayNodeInternal)
@property (nullable, atomic, weak, readwrite) A_SDisplayNode *asyncdisplaykit_node;
@end

@interface CALayer (A_SDisplayNodeInternal)
@property (nullable, atomic, weak, readwrite) A_SDisplayNode *asyncdisplaykit_node;
@end

NS_ASSUME_NONNULL_END
