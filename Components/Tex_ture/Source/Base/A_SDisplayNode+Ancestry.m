//
//  A_SDisplayNode+Ancestry.m
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

#import "A_SDisplayNode+Ancestry.h"
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>

A_S_SUBCLASSING_RESTRICTED
@interface A_SNodeAncestryEnumerator : NSEnumerator
@end

@implementation A_SNodeAncestryEnumerator {
  A_SDisplayNode *_lastNode; // This needs to be strong because enumeration will not retain the current batch of objects
  BOOL _initialState;
}

- (instancetype)initWithNode:(A_SDisplayNode *)node
{
  if (self = [super init]) {
    _initialState = YES;
    _lastNode = node;
  }
  return self;
}

- (id)nextObject
{
  if (_initialState) {
    _initialState = NO;
    return _lastNode;
  }

  A_SDisplayNode *nextNode = _lastNode.supernode;
  if (nextNode == nil && A_SDisplayNodeThreadIsMain()) {
    CALayer *layer = _lastNode.nodeLoaded ? _lastNode.layer.superlayer : nil;
    while (layer != nil) {
      nextNode = A_SLayerToDisplayNode(layer);
      if (nextNode != nil) {
        break;
      }
      layer = layer.superlayer;
    }
  }
  _lastNode = nextNode;
  return nextNode;
}

@end

@implementation A_SDisplayNode (Ancestry)

- (id<NSFastEnumeration>)supernodes
{
  NSEnumerator *result = [[A_SNodeAncestryEnumerator alloc] initWithNode:self];
  [result nextObject]; // discard first object (self)
  return result;
}

- (id<NSFastEnumeration>)supernodesIncludingSelf
{
  return [[A_SNodeAncestryEnumerator alloc] initWithNode:self];
}

- (nullable __kindof A_SDisplayNode *)supernodeOfClass:(Class)supernodeClass includingSelf:(BOOL)includeSelf
{
  id<NSFastEnumeration> chain = includeSelf ? self.supernodesIncludingSelf : self.supernodes;
  for (A_SDisplayNode *ancestor in chain) {
    if ([ancestor isKindOfClass:supernodeClass]) {
      return ancestor;
    }
  }
  return nil;
}

- (NSString *)ancestryDescription
{
  NSMutableArray *strings = [NSMutableArray array];
  for (A_SDisplayNode *node in self.supernodes) {
    [strings addObject:A_SObjectDescriptionMakeTiny(node)];
  }
  return strings.description;
}

@end
