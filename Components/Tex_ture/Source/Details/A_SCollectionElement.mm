//
//  A_SCollectionElement.mm
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

#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <mutex>

@interface A_SCollectionElement ()

/// Required node block used to allocate a cell node. Nil after the first execution.
@property (nonatomic, strong) A_SCellNodeBlock nodeBlock;

@end

@implementation A_SCollectionElement {
  std::mutex _lock;
  A_SCellNode *_node;
}

- (instancetype)initWithNodeModel:(id)nodeModel
                        nodeBlock:(A_SCellNodeBlock)nodeBlock
         supplementaryElementKind:(NSString *)supplementaryElementKind
                  constrainedSize:(A_SSizeRange)constrainedSize
                       owningNode:(id<A_SRangeManagingNode>)owningNode
                  traitCollection:(A_SPrimitiveTraitCollection)traitCollection
{
  NSAssert(nodeBlock != nil, @"Node block must not be nil");
  self = [super init];
  if (self) {
    _nodeModel = nodeModel;
    _nodeBlock = nodeBlock;
    _supplementaryElementKind = [supplementaryElementKind copy];
    _constrainedSize = constrainedSize;
    _owningNode = owningNode;
    _traitCollection = traitCollection;
  }
  return self;
}

- (A_SCellNode *)node
{
  std::lock_guard<std::mutex> l(_lock);
  if (_nodeBlock != nil) {
    A_SCellNode *node = _nodeBlock();
    _nodeBlock = nil;
    if (node == nil) {
      A_SDisplayNodeFailAssert(@"Node block returned nil node!");
      node = [[A_SCellNode alloc] init];
    }
    node.owningNode = _owningNode;
    node.collectionElement = self;
    A_STraitCollectionPropagateDown(node, _traitCollection);
    node.nodeModel = _nodeModel;
    _node = node;
  }
  return _node;
}

- (A_SCellNode *)nodeIfAllocated
{
  std::lock_guard<std::mutex> l(_lock);
  return _node;
}

- (void)setTraitCollection:(A_SPrimitiveTraitCollection)traitCollection
{
  A_SCellNode *nodeIfNeedsPropagation;
  
  {
    std::lock_guard<std::mutex> l(_lock);
    if (! A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(_traitCollection, traitCollection)) {
      _traitCollection = traitCollection;
      nodeIfNeedsPropagation = _node;
    }
  }
  
  if (nodeIfNeedsPropagation != nil) {
    A_STraitCollectionPropagateDown(nodeIfNeedsPropagation, traitCollection);
  }
}

@end
