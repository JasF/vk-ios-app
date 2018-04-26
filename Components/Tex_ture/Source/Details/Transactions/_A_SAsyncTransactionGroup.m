//
//  _A_SAsyncTransactionGroup.m
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

#import <Async_DisplayKit/A_SAssert.h>

#import <Async_DisplayKit/_A_SAsyncTransaction.h>
#import <Async_DisplayKit/_A_SAsyncTransactionGroup.h>
#import <Async_DisplayKit/_A_SAsyncTransactionContainer.h>
#import <Async_DisplayKit/_A_SAsyncTransactionContainer+Private.h>

@interface _A_SAsyncTransactionGroup ()
+ (void)registerTransactionGroupAsMainRunloopObserver:(_A_SAsyncTransactionGroup *)transactionGroup;
- (void)commit;
@end

@implementation _A_SAsyncTransactionGroup {
  NSHashTable<id<A_SAsyncTransactionContainer>> *_containers;
}

+ (_A_SAsyncTransactionGroup *)mainTransactionGroup
{
  A_SDisplayNodeAssertMainThread();
  static _A_SAsyncTransactionGroup *mainTransactionGroup;

  if (mainTransactionGroup == nil) {
    mainTransactionGroup = [[_A_SAsyncTransactionGroup alloc] init];
    [self registerTransactionGroupAsMainRunloopObserver:mainTransactionGroup];
  }
  return mainTransactionGroup;
}

+ (void)registerTransactionGroupAsMainRunloopObserver:(_A_SAsyncTransactionGroup *)transactionGroup
{
  A_SDisplayNodeAssertMainThread();
  static CFRunLoopObserverRef observer;
  A_SDisplayNodeAssert(observer == NULL, @"A _A_SAsyncTransactionGroup should not be registered on the main runloop twice");
  // defer the commit of the transaction so we can add more during the current runloop iteration
  CFRunLoopRef runLoop = CFRunLoopGetCurrent();
  CFOptionFlags activities = (kCFRunLoopBeforeWaiting | // before the run loop starts sleeping
                              kCFRunLoopExit);          // before exiting a runloop run

  observer = CFRunLoopObserverCreateWithHandler(NULL,        // allocator
                                                activities,  // activities
                                                YES,         // repeats
                                                INT_MAX,     // order after CA transaction commits
                                                ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
                                                  A_SDisplayNodeCAssertMainThread();
                                                  [transactionGroup commit];
                                                });
  CFRunLoopAddObserver(runLoop, observer, kCFRunLoopCommonModes);
  CFRelease(observer);
}

- (instancetype)init
{
  if ((self = [super init])) {
    _containers = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  }
  return self;
}

- (void)addTransactionContainer:(id<A_SAsyncTransactionContainer>)container
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeAssert(container != nil, @"No container");
  [_containers addObject:container];
}

- (void)commit
{
  A_SDisplayNodeAssertMainThread();

  if ([_containers count]) {
    NSHashTable *containersToCommit = _containers;
    _containers = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];

    for (id<A_SAsyncTransactionContainer> container in containersToCommit) {
      // Note that the act of committing a transaction may open a new transaction,
      // so we must nil out the transaction we're committing first.
      _A_SAsyncTransaction *transaction = container.asyncdisplaykit_currentAsyncTransaction;
      container.asyncdisplaykit_currentAsyncTransaction = nil;
      [transaction commit];
    }
  }
}

+ (void)commit
{
  [[_A_SAsyncTransactionGroup mainTransactionGroup] commit];
}

@end
