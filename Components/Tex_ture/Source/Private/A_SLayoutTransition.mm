//
//  A_SLayoutTransition.mm
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

#import <Async_DisplayKit/A_SLayoutTransition.h>

#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/NSArray+Diffing.h>

#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h> // Required for _insertSubnode... / _removeFromSupernode.
#import <Async_DisplayKit/A_SLog.h>

#import <queue>
#import <memory>

#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>

/**
 * Search the whole layout stack if at least one layout has a layoutElement object that can not be layed out asynchronous.
 * This can be the case for example if a node was already loaded
 */
static inline BOOL A_SLayoutCanTransitionAsynchronous(A_SLayout *layout) {
  // Queue used to keep track of sublayouts while traversing this layout in a BFS fashion.
  std::queue<A_SLayout *> queue;
  queue.push(layout);
  
  while (!queue.empty()) {
    layout = queue.front();
    queue.pop();
    
#if DEBUG
    A_SDisplayNodeCAssert([layout.layoutElement conformsToProtocol:@protocol(A_SLayoutElementTransition)], @"A_SLayoutElement in a layout transition needs to conforms to the A_SLayoutElementTransition protocol.");
#endif
    if (((id<A_SLayoutElementTransition>)layout.layoutElement).canLayoutAsynchronous == NO) {
      return NO;
    }
    
    // Add all sublayouts to process in next step
    for (A_SLayout *sublayout in layout.sublayouts) {
      queue.push(sublayout);
    }
  }
  
  return YES;
}

@implementation A_SLayoutTransition {
  std::shared_ptr<A_SDN::RecursiveMutex> __instanceLock__;
  
  BOOL _calculatedSubnodeOperations;
  NSArray<A_SDisplayNode *> *_insertedSubnodes;
  NSArray<A_SDisplayNode *> *_removedSubnodes;
  std::vector<NSUInteger> _insertedSubnodePositions;
  std::vector<NSUInteger> _removedSubnodePositions;
}

- (instancetype)initWithNode:(A_SDisplayNode *)node
               pendingLayout:(std::shared_ptr<A_SDisplayNodeLayout>)pendingLayout
              previousLayout:(std::shared_ptr<A_SDisplayNodeLayout>)previousLayout
{
  self = [super init];
  if (self) {
    __instanceLock__ = std::make_shared<A_SDN::RecursiveMutex>();
      
    _node = node;
    _pendingLayout = pendingLayout;
    _previousLayout = previousLayout;
  }
  return self;
}

- (instancetype)init
{
  A_SDisplayNodeAssert(NO, @"Use the designated initializer");
  return [self init];
}

- (BOOL)isSynchronous
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  return !A_SLayoutCanTransitionAsynchronous(_pendingLayout->layout);
}

- (void)commitTransition
{
  [self applySubnodeInsertions];
  [self applySubnodeRemovals];
}

- (void)applySubnodeInsertions
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  [self calculateSubnodeOperationsIfNeeded];
  
  // Create an activity even if no subnodes affected.
  as_activity_create_for_scope("Apply subnode insertions");
  if (_insertedSubnodes.count == 0) {
    return;
  }

  A_SDisplayNodeLogEvent(_node, @"insertSubnodes: %@", _insertedSubnodes);
  NSUInteger i = 0;
  for (A_SDisplayNode *node in _insertedSubnodes) {
    NSUInteger p = _insertedSubnodePositions[i];
    [_node _insertSubnode:node atIndex:p];
    i += 1;
  }
}

- (void)applySubnodeRemovals
{
  as_activity_scope(as_activity_create("Apply subnode removals", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
  A_SDN::MutexSharedLocker l(__instanceLock__);
  [self calculateSubnodeOperationsIfNeeded];

  if (_removedSubnodes.count == 0) {
    return;
  }

  A_SDisplayNodeLogEvent(_node, @"removeSubnodes: %@", _removedSubnodes);
  for (A_SDisplayNode *subnode in _removedSubnodes) {
    // In this case we should only remove the subnode if it's still a subnode of the _node that executes a layout transition.
    // It can happen that a node already did a layout transition and added this subnode, in this case the subnode
    // would be removed from the new node instead of _node
    [subnode _removeFromSupernodeIfEqualTo:_node];
  }
}

- (void)calculateSubnodeOperationsIfNeeded
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  if (_calculatedSubnodeOperations) {
    return;
  }
  
  // Create an activity even if no subnodes affected.
  as_activity_create_for_scope("Calculate subnode operations");
  A_SLayout *previousLayout = _previousLayout->layout;
  A_SLayout *pendingLayout = _pendingLayout->layout;

  if (previousLayout) {
    NSIndexSet *insertions, *deletions;
    [previousLayout.sublayouts asdk_diffWithArray:pendingLayout.sublayouts
                                       insertions:&insertions
                                        deletions:&deletions
                                     compareBlock:^BOOL(A_SLayout *lhs, A_SLayout *rhs) {
                                       return A_SObjectIsEqual(lhs.layoutElement, rhs.layoutElement);
                                     }];
    _insertedSubnodePositions = findNodesInLayoutAtIndexes(pendingLayout, insertions, &_insertedSubnodes);
    _removedSubnodePositions = findNodesInLayoutAtIndexesWithFilteredNodes(previousLayout,
                                                                           deletions,
                                                                           _insertedSubnodes,
                                                                           &_removedSubnodes);
  } else {
    NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [pendingLayout.sublayouts count])];
    _insertedSubnodePositions = findNodesInLayoutAtIndexes(pendingLayout, indexes, &_insertedSubnodes);
    _removedSubnodes = nil;
    _removedSubnodePositions.clear();
  }
  _calculatedSubnodeOperations = YES;
}

#pragma mark - _A_STransitionContextDelegate

- (NSArray<A_SDisplayNode *> *)currentSubnodesWithTransitionContext:(_A_STransitionContext *)context
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  return _node.subnodes;
}

- (NSArray<A_SDisplayNode *> *)insertedSubnodesWithTransitionContext:(_A_STransitionContext *)context
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  [self calculateSubnodeOperationsIfNeeded];
  return _insertedSubnodes;
}

- (NSArray<A_SDisplayNode *> *)removedSubnodesWithTransitionContext:(_A_STransitionContext *)context
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  [self calculateSubnodeOperationsIfNeeded];
  return _removedSubnodes;
}

- (A_SLayout *)transitionContext:(_A_STransitionContext *)context layoutForKey:(NSString *)key
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  if ([key isEqualToString:A_STransitionContextFromLayoutKey]) {
    return _previousLayout->layout;
  } else if ([key isEqualToString:A_STransitionContextToLayoutKey]) {
    return _pendingLayout->layout;
  } else {
    return nil;
  }
}

- (A_SSizeRange)transitionContext:(_A_STransitionContext *)context constrainedSizeForKey:(NSString *)key
{
  A_SDN::MutexSharedLocker l(__instanceLock__);
  if ([key isEqualToString:A_STransitionContextFromLayoutKey]) {
    return _previousLayout->constrainedSize;
  } else if ([key isEqualToString:A_STransitionContextToLayoutKey]) {
    return _pendingLayout->constrainedSize;
  } else {
    return A_SSizeRangeMake(CGSizeZero, CGSizeZero);
  }
}

#pragma mark - Filter helpers

/**
 * @abstract Stores the nodes at the given indexes in the `storedNodes` array, storing indexes in a `storedPositions` c++ vector.
 */
static inline std::vector<NSUInteger> findNodesInLayoutAtIndexes(A_SLayout *layout,
                                                                 NSIndexSet *indexes,
                                                                 NSArray<A_SDisplayNode *> * __strong *storedNodes)
{
  return findNodesInLayoutAtIndexesWithFilteredNodes(layout, indexes, nil, storedNodes);
}

/**
 * @abstract Stores the nodes at the given indexes in the `storedNodes` array, storing indexes in a `storedPositions` c++ vector.
 * @discussion If the node exists in the `filteredNodes` array, the node is not added to `storedNodes`.
 */
static inline std::vector<NSUInteger> findNodesInLayoutAtIndexesWithFilteredNodes(A_SLayout *layout,
                                                                                  NSIndexSet *indexes,
                                                                                  NSArray<A_SDisplayNode *> *filteredNodes,
                                                                                  NSArray<A_SDisplayNode *> * __strong *storedNodes)
{
  NSMutableArray<A_SDisplayNode *> *nodes = [NSMutableArray arrayWithCapacity:indexes.count];
  std::vector<NSUInteger> positions = std::vector<NSUInteger>();
  
  // From inspection, this is how enumerateObjectsAtIndexes: works under the hood
  NSUInteger firstIndex = indexes.firstIndex;
  NSUInteger lastIndex = indexes.lastIndex;
  NSUInteger idx = 0;
  for (A_SLayout *sublayout in layout.sublayouts) {
    if (idx > lastIndex) { break; }
    if (idx >= firstIndex && [indexes containsIndex:idx]) {
      A_SDisplayNode *node = (A_SDisplayNode *)sublayout.layoutElement;
      A_SDisplayNodeCAssert(node, @"A_SDisplayNode was deallocated before it was added to a subnode. It's likely the case that you use automatically manages subnodes and allocate a A_SDisplayNode in layoutSpecThatFits: and don't have any strong reference to it.");
      // Ignore the odd case in which a non-node sublayout is accessed and the type cast fails
      if (node != nil) {
        BOOL notFiltered = (filteredNodes == nil || [filteredNodes indexOfObjectIdenticalTo:node] == NSNotFound);
        if (notFiltered) {
          [nodes addObject:node];
          positions.push_back(idx);
        }
      }
    }
    idx += 1;
  }
  *storedNodes = nodes;
  
  return positions;
}

@end
