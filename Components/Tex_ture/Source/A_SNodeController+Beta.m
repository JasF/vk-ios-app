//
//  A_SNodeController+Beta.m
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

#import <Async_DisplayKit/A_SWeakProxy.h>
#import <Async_DisplayKit/A_SNodeController+Beta.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>

#define _node (_shouldInvertStrongReference ? _weakNode : _strongNode)

@interface A_SDisplayNode (A_SNodeControllerOwnership)

// This property exists for debugging purposes. Don't use __nodeController in production code.
@property (nonatomic, readonly) A_SNodeController *__nodeController;

// These setters are mutually exclusive. Setting one will clear the relationship of the other.
- (void)__setNodeControllerStrong:(A_SNodeController *)nodeController;
- (void)__setNodeControllerWeak:(A_SNodeController *)nodeController;

@end

@implementation A_SNodeController
{
  A_SDisplayNode *_strongNode;
  __weak A_SDisplayNode *_weakNode;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    
  }
  return self;
}

- (void)loadNode
{
  self.node = [[A_SDisplayNode alloc] init];
}

- (A_SDisplayNode *)node
{
  if (_node == nil) {
    [self loadNode];
  }
  return _node;
}

- (void)setupReferencesWithNode:(A_SDisplayNode *)node
{
  if (_shouldInvertStrongReference) {
    // The node should own the controller; weak reference from controller to node.
    _weakNode = node;
    [node __setNodeControllerStrong:self];
    _strongNode = nil;
  } else {
    // The controller should own the node; weak reference from node to controller.
    _strongNode = node;
    [node __setNodeControllerWeak:self];
    _weakNode = nil;
  }

  node.interfaceStateDelegate = self;
}

- (void)setNode:(A_SDisplayNode *)node
{
  [self setupReferencesWithNode:node];
}

- (void)setShouldInvertStrongReference:(BOOL)shouldInvertStrongReference
{
  if (_shouldInvertStrongReference != shouldInvertStrongReference) {
    // Because the BOOL controls which ivar we access, get the node before toggling.
    A_SDisplayNode *node = _node;
    _shouldInvertStrongReference = shouldInvertStrongReference;
    [self setupReferencesWithNode:node];
  }
}

// subclass overrides
- (void)nodeDidLayout {}

- (void)didEnterVisibleState {}
- (void)didExitVisibleState  {}

- (void)didEnterDisplayState {}
- (void)didExitDisplayState  {}

- (void)didEnterPreloadState {}
- (void)didExitPreloadState  {}

- (void)interfaceStateDidChange:(A_SInterfaceState)newState
                      fromState:(A_SInterfaceState)oldState {}

@end

@implementation A_SDisplayNode (A_SNodeControllerOwnership)

- (A_SNodeController *)__nodeController
{
  A_SNodeController *nodeController = nil;
  id object = objc_getAssociatedObject(self, @selector(__nodeController));

  if ([object isKindOfClass:[A_SWeakProxy class]]) {
    nodeController = (A_SNodeController *)[(A_SWeakProxy *)object target];
  } else {
    nodeController = (A_SNodeController *)object;
  }

  return nodeController;
}

- (void)__setNodeControllerStrong:(A_SNodeController *)nodeController
{
  objc_setAssociatedObject(self, @selector(__nodeController), nodeController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)__setNodeControllerWeak:(A_SNodeController *)nodeController
{
  // Associated objects don't support weak references. Since assign can become a dangling pointer, use A_SWeakProxy.
  A_SWeakProxy *nodeControllerProxy = [A_SWeakProxy weakProxyWithTarget:nodeController];
  objc_setAssociatedObject(self, @selector(__nodeController), nodeControllerProxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation A_SDisplayNode (A_SNodeController)

- (A_SNodeController *)nodeController {
  return self.__nodeController;
}

@end
