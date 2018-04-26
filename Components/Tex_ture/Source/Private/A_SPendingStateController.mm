//
//  A_SPendingStateController.mm
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

#import <Async_DisplayKit/A_SPendingStateController.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SWeakSet.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h> // Required for -applyPendingViewState; consider moving this to +FrameworkPrivate

@interface A_SPendingStateController()
{
  A_SDN::Mutex _lock;

  struct A_SPendingStateControllerFlags {
    unsigned pendingFlush:1;
  } _flags;
}

@property (nonatomic, strong, readonly) A_SWeakSet<A_SDisplayNode *> *dirtyNodes;
@end

@implementation A_SPendingStateController

#pragma mark Lifecycle & Singleton

- (instancetype)init
{
  self = [super init];
  if (self) {
    _dirtyNodes = [[A_SWeakSet alloc] init];
  }
  return self;
}

+ (A_SPendingStateController *)sharedInstance
{
  static dispatch_once_t onceToken;
  static A_SPendingStateController *controller = nil;
  dispatch_once(&onceToken, ^{
    controller = [[A_SPendingStateController alloc] init];
  });
  return controller;
}

#pragma mark External API

- (void)registerNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssert(node.nodeLoaded, @"Expected display node to be loaded before it was registered with A_SPendingStateController. Node: %@", node);
  A_SDN::MutexLocker l(_lock);
  [_dirtyNodes addObject:node];

  [self scheduleFlushIfNeeded];
}

- (void)flush
{
  A_SDisplayNodeAssertMainThread();
  _lock.lock();
    A_SWeakSet *dirtyNodes = _dirtyNodes;
    _dirtyNodes = [[A_SWeakSet alloc] init];
    _flags.pendingFlush = NO;
  _lock.unlock();

  for (A_SDisplayNode *node in dirtyNodes) {
    [node applyPendingViewState];
  }
}


#pragma mark Private Methods

/**
 This method is assumed to be called with the lock held.
 */
- (void)scheduleFlushIfNeeded
{
  if (_flags.pendingFlush) {
    return;
  }

  _flags.pendingFlush = YES;
  dispatch_async(dispatch_get_main_queue(), ^{
    [self flush];
  });
}

@end

@implementation A_SPendingStateController (Testing)

- (BOOL)test_isFlushScheduled
{
  return _flags.pendingFlush;
}

@end
