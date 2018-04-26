//
//  A_SDisplayNodeExtras.h
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

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SDisplayNode.h>

/**
 * Sets the debugName field for these nodes to the given symbol names, within the domain of "self.class"
 * For instance, in `MYButtonNode` if you call `A_SSetDebugNames(self.titleNode, _countNode)` the debug names
 * for the nodes will be set to `MYButtonNode.titleNode` and `MYButtonNode.countNode`.
 */
#if DEBUG
  #define A_SSetDebugName(node, format, ...) node.debugName = [NSString stringWithFormat:format, __VA_ARGS__]
  #define A_SSetDebugNames(...) _A_SSetDebugNames(self.class, @"" # __VA_ARGS__, __VA_ARGS__, nil)
#else
  #define A_SSetDebugName(node, name)
  #define A_SSetDebugNames(...)
#endif

/// For deallocation of objects on the main thread across multiple run loops.
extern void A_SPerformMainThreadDeallocation(id _Nullable __strong * _Nonnull objectPtr);

// Because inline methods can't be extern'd and need to be part of the translation unit of code
// that compiles with them to actually inline, we both declare and define these in the header.
A_SDISPLAYNODE_INLINE BOOL A_SInterfaceStateIncludesVisible(A_SInterfaceState interfaceState)
{
  return ((interfaceState & A_SInterfaceStateVisible) == A_SInterfaceStateVisible);
}

A_SDISPLAYNODE_INLINE BOOL A_SInterfaceStateIncludesDisplay(A_SInterfaceState interfaceState)
{
  return ((interfaceState & A_SInterfaceStateDisplay) == A_SInterfaceStateDisplay);
}

A_SDISPLAYNODE_INLINE BOOL A_SInterfaceStateIncludesPreload(A_SInterfaceState interfaceState)
{
  return ((interfaceState & A_SInterfaceStatePreload) == A_SInterfaceStatePreload);
}

A_SDISPLAYNODE_INLINE BOOL A_SInterfaceStateIncludesMeasureLayout(A_SInterfaceState interfaceState)
{
  return ((interfaceState & A_SInterfaceStateMeasureLayout) == A_SInterfaceStateMeasureLayout);
}

__unused static NSString * _Nonnull NSStringFromA_SInterfaceState(A_SInterfaceState interfaceState)
{
  NSMutableArray *states = [NSMutableArray array];
  if (interfaceState == A_SInterfaceStateNone) {
    [states addObject:@"No state"];
  }
  if (A_SInterfaceStateIncludesMeasureLayout(interfaceState)) {
    [states addObject:@"MeasureLayout"];
  }
  if (A_SInterfaceStateIncludesPreload(interfaceState)) {
    [states addObject:@"Preload"];
  }
  if (A_SInterfaceStateIncludesDisplay(interfaceState)) {
    [states addObject:@"Display"];
  }
  if (A_SInterfaceStateIncludesVisible(interfaceState)) {
    [states addObject:@"Visible"];
  }
  return [NSString stringWithFormat:@"{ %@ }", [states componentsJoinedByString:@" | "]];
}

#define INTERFACE_STATE_DELTA(Name) ({ \
  if ((oldState & A_SInterfaceState##Name) != (newState & A_SInterfaceState##Name)) { \
    [changes appendFormat:@"%c%s ", (newState & A_SInterfaceState##Name ? '+' : '-'), #Name]; \
  } \
})

/// e.g. { +Visible, -Preload } (although that should never actually happen.)
/// NOTE: Changes to MeasureLayout state don't really mean anything so we omit them for now.
__unused static NSString * _Nonnull NSStringFromA_SInterfaceStateChange(A_SInterfaceState oldState, A_SInterfaceState newState)
{
  if (oldState == newState) {
    return @"{ }";
  }

  NSMutableString *changes = [NSMutableString stringWithString:@"{ "];
  INTERFACE_STATE_DELTA(Preload);
  INTERFACE_STATE_DELTA(Display);
  INTERFACE_STATE_DELTA(Visible);
  [changes appendString:@"}"];
  return changes;
}

#undef INTERFACE_STATE_DELTA

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

/**
 Returns the appropriate interface state for a given A_SDisplayNode and window
 */
extern A_SInterfaceState A_SInterfaceStateForDisplayNode(A_SDisplayNode *displayNode, UIWindow *window) A_S_WARN_UNUSED_RESULT;

/**
 Given a layer, returns the associated display node, if any.
 */
extern A_SDisplayNode * _Nullable A_SLayerToDisplayNode(CALayer * _Nullable layer) A_S_WARN_UNUSED_RESULT;

/**
 Given a view, returns the associated display node, if any.
 */
extern A_SDisplayNode * _Nullable A_SViewToDisplayNode(UIView * _Nullable view) A_S_WARN_UNUSED_RESULT;

/**
 Given a node, returns the root of the node hierarchy (where supernode == nil)
 */
extern A_SDisplayNode *A_SDisplayNodeUltimateParentOfNode(A_SDisplayNode *node) A_S_WARN_UNUSED_RESULT;

/**
 If traverseSublayers == YES, this function will walk the layer hierarchy, spanning discontinuous sections of the node hierarchy\
 (e.g. the layers of UIKit intermediate views in UIViewControllers, UITableView, UICollectionView).
 In the event that a node's backing layer is not created yet, the function will only walk the direct subnodes instead
 of forcing the layer hierarchy to be created.
 */
extern void A_SDisplayNodePerformBlockOnEveryNode(CALayer * _Nullable layer, A_SDisplayNode * _Nullable node, BOOL traverseSublayers, void(^block)(A_SDisplayNode *node));

/**
 This function will walk the node hierarchy in a breadth first fashion. It does run the block on the node provided
 directly to the function call.  It does NOT traverse sublayers.
 */
extern void A_SDisplayNodePerformBlockOnEveryNodeBFS(A_SDisplayNode *node, void(^block)(A_SDisplayNode *node));

/**
 Identical to A_SDisplayNodePerformBlockOnEveryNode, except it does not run the block on the
 node provided directly to the function call - only on all descendants.
 */
extern void A_SDisplayNodePerformBlockOnEverySubnode(A_SDisplayNode *node, BOOL traverseSublayers, void(^block)(A_SDisplayNode *node));

/**
 Given a display node, traverses up the layer tree hierarchy, returning the first display node that passes block.
 */
extern A_SDisplayNode * _Nullable A_SDisplayNodeFindFirstSupernode(A_SDisplayNode * _Nullable node, BOOL (^block)(A_SDisplayNode *node)) A_S_WARN_UNUSED_RESULT A_SDISPLAYNODE_DEPRECATED_MSG("Use the `supernodes` property instead.");

/**
 Given a display node, traverses up the layer tree hierarchy, returning the first display node of kind class.
 */
extern __kindof A_SDisplayNode * _Nullable A_SDisplayNodeFindFirstSupernodeOfClass(A_SDisplayNode *start, Class c) A_S_WARN_UNUSED_RESULT  A_SDISPLAYNODE_DEPRECATED_MSG("Use the `supernodeOfClass:includingSelf:` method instead.");

/**
 * Given a layer, find the window it lives in, if any.
 */
extern UIWindow * _Nullable A_SFindWindowOfLayer(CALayer *layer) A_S_WARN_UNUSED_RESULT;

/**
 * Given a layer, find the closest view it lives in, if any.
 */
extern UIView * _Nullable A_SFindClosestViewOfLayer(CALayer *layer) A_S_WARN_UNUSED_RESULT;

/**
 * Given two nodes, finds their most immediate common parent.  Used for geometry conversion methods.
 * NOTE: It is an error to try to convert between nodes which do not share a common ancestor. This behavior is
 * disallowed in UIKit documentation and the behavior is left undefined. The output does not have a rigorously defined
 * failure mode (i.e. returning CGPointZero or returning the point exactly as passed in). Rather than track the internal
 * undefined and undocumented behavior of UIKit in A_SDisplayNode, this operation is defined to be incorrect in all
 * circumstances and must be fixed wherever encountered.
 */
extern A_SDisplayNode * _Nullable A_SDisplayNodeFindClosestCommonAncestor(A_SDisplayNode *node1, A_SDisplayNode *node2) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, collects all descendants. This is a specialization of A_SCollectContainer() that walks the Core Animation layer tree as opposed to the display node tree, thus supporting non-continues display node hierarchies.
 */
extern NSArray<A_SDisplayNode *> *A_SCollectDisplayNodes(A_SDisplayNode *node) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, traverses down the node hierarchy, returning all the display nodes that pass the block.
 */
extern NSArray<A_SDisplayNode *> *A_SDisplayNodeFindAllSubnodes(A_SDisplayNode *start, BOOL (^block)(A_SDisplayNode *node)) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, traverses down the node hierarchy, returning all the display nodes of kind class.
 */
extern NSArray<__kindof A_SDisplayNode *> *A_SDisplayNodeFindAllSubnodesOfClass(A_SDisplayNode *start, Class c) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, traverses down the node hierarchy, returning the depth-first display node, including the start node that pass the block.
 */
extern __kindof A_SDisplayNode * _Nullable A_SDisplayNodeFindFirstNode(A_SDisplayNode *start, BOOL (^block)(A_SDisplayNode *node)) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, traverses down the node hierarchy, returning the depth-first display node, excluding the start node, that pass the block
 */
extern __kindof A_SDisplayNode * _Nullable A_SDisplayNodeFindFirstSubnode(A_SDisplayNode *start, BOOL (^block)(A_SDisplayNode *node)) A_S_WARN_UNUSED_RESULT;

/**
 Given a display node, traverses down the node hierarchy, returning the depth-first display node of kind class.
 */
extern __kindof A_SDisplayNode * _Nullable A_SDisplayNodeFindFirstSubnodeOfClass(A_SDisplayNode *start, Class c) A_S_WARN_UNUSED_RESULT;

extern UIColor *A_SDisplayNodeDefaultPlaceholderColor(void) A_S_WARN_UNUSED_RESULT;
extern UIColor *A_SDisplayNodeDefaultTintColor(void) A_S_WARN_UNUSED_RESULT;

/**
 Disable willAppear / didAppear / didDisappear notifications for a sub-hierarchy, then re-enable when done. Nested calls are supported.
 */
extern void A_SDisplayNodeDisableHierarchyNotifications(A_SDisplayNode *node);
extern void A_SDisplayNodeEnableHierarchyNotifications(A_SDisplayNode *node);

// Not to be called directly.
extern void _A_SSetDebugNames(Class _Nonnull owningClass, NSString * _Nonnull names, A_SDisplayNode * _Nullable object, ...);

A_SDISPLAYNODE_EXTERN_C_END

NS_ASSUME_NONNULL_END
