//
//  A_SDisplayNodeExtras.mm
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

#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+Ancestry.h>

#import <queue>
#import <Async_DisplayKit/A_SRunLoopQueue.h>

extern void A_SPerformMainThreadDeallocation(id _Nullable __strong * _Nonnull objectPtr) {
  /**
   * UIKit components must be deallocated on the main thread. We use this shared
   * run loop queue to gradually deallocate them across many turns of the main run loop.
   */
  static A_SRunLoopQueue *queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = [[A_SRunLoopQueue alloc] initWithRunLoop:CFRunLoopGetMain() retainObjects:YES handler:nil];
    queue.batchSize = 10;
  });

  if (objectPtr != NULL && *objectPtr != nil) {
    // Lock queue while enqueuing and releasing, so that there's no risk
    // that the queue will release before we get a chance to release.
    [queue lock];
    [queue enqueue:*objectPtr];   // Retain, +1
    *objectPtr = nil;             // Release, +0
    [queue unlock];               // (After queue drains), release, -1
  }
}

extern void _A_SSetDebugNames(Class _Nonnull owningClass, NSString * _Nonnull names, A_SDisplayNode * _Nullable object, ...)
{
  NSString *owningClassName = NSStringFromClass(owningClass);
  NSArray *nameArray = [names componentsSeparatedByString:@", "];
  va_list args;
  va_start(args, object);
  NSInteger i = 0;
  for (A_SDisplayNode *node = object; node != nil; node = va_arg(args, id), i++) {
    NSMutableString *symbolName = [nameArray[i] mutableCopy];
    // Remove any `self.` or `_` prefix
    [symbolName replaceOccurrencesOfString:@"self." withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, symbolName.length)];
    [symbolName replaceOccurrencesOfString:@"_" withString:@"" options:NSAnchoredSearch range:NSMakeRange(0, symbolName.length)];
    node.debugName = [NSString stringWithFormat:@"%@.%@", owningClassName, symbolName];
  }
  A_SDisplayNodeCAssert(nameArray.count == i, @"Malformed call to A_SSetDebugNames: %@", names);
  va_end(args);
}

extern A_SInterfaceState A_SInterfaceStateForDisplayNode(A_SDisplayNode *displayNode, UIWindow *window)
{
    A_SDisplayNodeCAssert(![displayNode isLayerBacked], @"displayNode must not be layer backed as it may have a nil window");
    if (displayNode && [displayNode supportsRangeManagedInterfaceState]) {
        // Directly clear the visible bit if we are not in a window. This means that the interface state is,
        // if not already, about to be set to invisible as it is not possible for an element to be visible
        // while outside of a window.
        A_SInterfaceState interfaceState = displayNode.interfaceState;
        return (window == nil ? (interfaceState &= (~A_SInterfaceStateVisible)) : interfaceState);
    } else {
        // For not range managed nodes we might be on our own to try to guess if we're visible.
        return (window == nil ? A_SInterfaceStateNone : (A_SInterfaceStateVisible | A_SInterfaceStateDisplay));
    }
}

extern A_SDisplayNode *A_SLayerToDisplayNode(CALayer *layer)
{
  return layer.asyncdisplaykit_node;
}

extern A_SDisplayNode *A_SViewToDisplayNode(UIView *view)
{
  return view.asyncdisplaykit_node;
}

extern void A_SDisplayNodePerformBlockOnEveryNode(CALayer * _Nullable layer, A_SDisplayNode * _Nullable node, BOOL traverseSublayers, void(^block)(A_SDisplayNode *node))
{
  if (!node) {
    A_SDisplayNodeCAssertNotNil(layer, @"Cannot recursively perform with nil node and nil layer");
    A_SDisplayNodeCAssertMainThread();
    node = A_SLayerToDisplayNode(layer);
  }
  
  if (node) {
    block(node);
  }
  if (traverseSublayers && !layer && [node isNodeLoaded] && A_SDisplayNodeThreadIsMain()) {
    layer = node.layer;
  }
  
  if (traverseSublayers && layer && node.rasterizesSubtree == NO) {
    /// NOTE: The docs say `sublayers` returns a copy, but it does not.
    /// See: http://stackoverflow.com/questions/14854480/collection-calayerarray-0x1ed8faa0-was-mutated-while-being-enumerated
    for (CALayer *sublayer in [[layer sublayers] copy]) {
      A_SDisplayNodePerformBlockOnEveryNode(sublayer, nil, traverseSublayers, block);
    }
  } else if (node) {
    for (A_SDisplayNode *subnode in [node subnodes]) {
      A_SDisplayNodePerformBlockOnEveryNode(nil, subnode, traverseSublayers, block);
    }
  }
}

extern void A_SDisplayNodePerformBlockOnEveryNodeBFS(A_SDisplayNode *node, void(^block)(A_SDisplayNode *node))
{
  // Queue used to keep track of subnodes while traversing this layout in a BFS fashion.
  std::queue<A_SDisplayNode *> queue;
  queue.push(node);
  
  while (!queue.empty()) {
    node = queue.front();
    queue.pop();
    
    block(node);

    // Add all subnodes to process in next step
    for (A_SDisplayNode *subnode in node.subnodes) {
      queue.push(subnode);
    }
  }
}

extern void A_SDisplayNodePerformBlockOnEverySubnode(A_SDisplayNode *node, BOOL traverseSublayers, void(^block)(A_SDisplayNode *node))
{
  for (A_SDisplayNode *subnode in node.subnodes) {
    A_SDisplayNodePerformBlockOnEveryNode(nil, subnode, YES, block);
  }
}

A_SDisplayNode *A_SDisplayNodeFindFirstSupernode(A_SDisplayNode *node, BOOL (^block)(A_SDisplayNode *node))
{
  // This function has historically started with `self` but the name suggests
  // that it wouldn't. Perhaps we should change the behavior.
  for (A_SDisplayNode *ancestor in node.supernodesIncludingSelf) {
    if (block(ancestor)) {
      return ancestor;
    }
  }
  return nil;
}

__kindof A_SDisplayNode *A_SDisplayNodeFindFirstSupernodeOfClass(A_SDisplayNode *start, Class c)
{
  // This function has historically started with `self` but the name suggests
  // that it wouldn't. Perhaps we should change the behavior.
  return [start supernodeOfClass:c includingSelf:YES];
}

static void _A_SCollectDisplayNodes(NSMutableArray *array, CALayer *layer)
{
  A_SDisplayNode *node = A_SLayerToDisplayNode(layer);

  if (nil != node) {
    [array addObject:node];
  }

  for (CALayer *sublayer in layer.sublayers)
    _A_SCollectDisplayNodes(array, sublayer);
}

extern NSArray<A_SDisplayNode *> *A_SCollectDisplayNodes(A_SDisplayNode *node)
{
  NSMutableArray *list = [NSMutableArray array];
  for (CALayer *sublayer in node.layer.sublayers) {
    _A_SCollectDisplayNodes(list, sublayer);
  }
  return list;
}

#pragma mark - Find all subnodes

static void _A_SDisplayNodeFindAllSubnodes(NSMutableArray *array, A_SDisplayNode *node, BOOL (^block)(A_SDisplayNode *node))
{
  if (!node)
    return;

  for (A_SDisplayNode *subnode in node.subnodes) {
    if (block(subnode)) {
      [array addObject:subnode];
    }

    _A_SDisplayNodeFindAllSubnodes(array, subnode, block);
  }
}

extern NSArray<A_SDisplayNode *> *A_SDisplayNodeFindAllSubnodes(A_SDisplayNode *start, BOOL (^block)(A_SDisplayNode *node))
{
  NSMutableArray *list = [NSMutableArray array];
  _A_SDisplayNodeFindAllSubnodes(list, start, block);
  return list;
}

extern NSArray<__kindof A_SDisplayNode *> *A_SDisplayNodeFindAllSubnodesOfClass(A_SDisplayNode *start, Class c)
{
  return A_SDisplayNodeFindAllSubnodes(start, ^(A_SDisplayNode *n) {
    return [n isKindOfClass:c];
  });
}

#pragma mark - Find first subnode

static A_SDisplayNode *_A_SDisplayNodeFindFirstNode(A_SDisplayNode *startNode, BOOL includeStartNode, BOOL (^block)(A_SDisplayNode *node))
{
  for (A_SDisplayNode *subnode in startNode.subnodes) {
    A_SDisplayNode *foundNode = _A_SDisplayNodeFindFirstNode(subnode, YES, block);
    if (foundNode) {
      return foundNode;
    }
  }

  if (includeStartNode && block(startNode))
    return startNode;

  return nil;
}

extern __kindof A_SDisplayNode *A_SDisplayNodeFindFirstNode(A_SDisplayNode *startNode, BOOL (^block)(A_SDisplayNode *node))
{
  return _A_SDisplayNodeFindFirstNode(startNode, YES, block);
}

extern __kindof A_SDisplayNode *A_SDisplayNodeFindFirstSubnode(A_SDisplayNode *startNode, BOOL (^block)(A_SDisplayNode *node))
{
  return _A_SDisplayNodeFindFirstNode(startNode, NO, block);
}

extern __kindof A_SDisplayNode *A_SDisplayNodeFindFirstSubnodeOfClass(A_SDisplayNode *start, Class c)
{
  return A_SDisplayNodeFindFirstSubnode(start, ^(A_SDisplayNode *n) {
    return [n isKindOfClass:c];
  });
}

static inline BOOL _A_SDisplayNodeIsAncestorOfDisplayNode(A_SDisplayNode *possibleAncestor, A_SDisplayNode *possibleDescendant)
{
  A_SDisplayNode *supernode = possibleDescendant;
  while (supernode) {
    if (supernode == possibleAncestor) {
      return YES;
    }
    supernode = supernode.supernode;
  }
  
  return NO;
}

extern UIWindow * _Nullable A_SFindWindowOfLayer(CALayer *layer)
{
  UIView *view = A_SFindClosestViewOfLayer(layer);
  if (UIWindow *window = A_SDynamicCast(view, UIWindow)) {
    return window;
  } else {
    return view.window;
  }
}

extern UIView * _Nullable A_SFindClosestViewOfLayer(CALayer *layer)
{
  while (layer != nil) {
    if (UIView *view = A_SDynamicCast(layer.delegate, UIView)) {
      return view;
    }
    layer = layer.superlayer;
  }
  return nil;
}

extern A_SDisplayNode *A_SDisplayNodeFindClosestCommonAncestor(A_SDisplayNode *node1, A_SDisplayNode *node2)
{
  A_SDisplayNode *possibleAncestor = node1;
  while (possibleAncestor) {
    if (_A_SDisplayNodeIsAncestorOfDisplayNode(possibleAncestor, node2)) {
      break;
    }
    possibleAncestor = possibleAncestor.supernode;
  }
  
  A_SDisplayNodeCAssertNotNil(possibleAncestor, @"Could not find a common ancestor between node1: %@ and node2: %@", node1, node2);
  return possibleAncestor;
}

extern A_SDisplayNode *A_SDisplayNodeUltimateParentOfNode(A_SDisplayNode *node)
{
  // node <- supernode on each loop
  // previous <- node on each loop where node is not nil
  // previous is the final non-nil value of supernode, i.e. the root node
  A_SDisplayNode *previousNode = node;
  while ((node = [node supernode])) {
    previousNode = node;
  }
  return previousNode;
}

#pragma mark - Placeholders

UIColor *A_SDisplayNodeDefaultPlaceholderColor()
{
  static UIColor *defaultPlaceholderColor;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultPlaceholderColor = [UIColor colorWithWhite:0.95 alpha:1.0];
  });
  return defaultPlaceholderColor;
}

UIColor *A_SDisplayNodeDefaultTintColor()
{
  static UIColor *defaultTintColor;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    defaultTintColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
  });
  return defaultTintColor;
}

#pragma mark - Hierarchy Notifications

void A_SDisplayNodeDisableHierarchyNotifications(A_SDisplayNode *node)
{
  [node __incrementVisibilityNotificationsDisabled];
}

void A_SDisplayNodeEnableHierarchyNotifications(A_SDisplayNode *node)
{
  [node __decrementVisibilityNotificationsDisabled];
}
