//
//  A_SBridgedPropertiesTests.mm
//  Tex_ture
//
//  Created by Adlai Holler on 1/7/16.
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

#import <XCTest/XCTest.h>
#import <Async_DisplayKit/A_SPendingStateController.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import <Async_DisplayKit/_A_SPendingState.h>
#import <Async_DisplayKit/A_SCellNode.h>

@interface A_SPendingStateController (Testing)
- (BOOL)test_isFlushScheduled;
@end

@interface A_SBridgedPropertiesTestView : UIView
@property (nonatomic, readonly) BOOL receivedSetNeedsLayout;
@end

@implementation A_SBridgedPropertiesTestView

- (void)setNeedsLayout
{
  _receivedSetNeedsLayout = YES;
  [super setNeedsLayout];
}

@end

@interface A_SBridgedPropertiesTestNode : A_SDisplayNode
@property (nullable, nonatomic, copy) dispatch_block_t onDealloc;
@end

@implementation A_SBridgedPropertiesTestNode

- (void)dealloc {
  _onDealloc();
}

@end

@interface A_SBridgedPropertiesTests : XCTestCase
@end

/// Dispatches the given block synchronously onto a different thread.
/// This is useful for testing non-main-thread behavior because `dispatch_sync`
/// will often use the current thread.
static inline void A_SDispatchSyncOnOtherThread(dispatch_block_t block) {
  dispatch_group_t group = dispatch_group_create();
  dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  dispatch_group_enter(group);
  dispatch_async(q, ^{
    A_SDisplayNodeCAssertNotMainThread();
    block();
    dispatch_group_leave(group);
  });
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

@implementation A_SBridgedPropertiesTests

- (void)testTheresA_SharedInstance
{
  XCTAssertNotNil([A_SPendingStateController sharedInstance]);
}

/// FIXME: This test is unreliable for an as-yet unknown reason
/// but that being intermittent, and this test being so strict, it's
/// reasonable to assume for now the failures don't reflect a framework bug.
/// See https://github.com/facebook/Async_DisplayKit/pull/1048
- (void)DISABLED_testThatDirtyNodesAreNotRetained
{
  A_SPendingStateController *ctrl = [A_SPendingStateController sharedInstance];
  __block BOOL didDealloc = NO;
  @autoreleasepool {
    __attribute__((objc_precise_lifetime)) A_SBridgedPropertiesTestNode *node = [A_SBridgedPropertiesTestNode new];
    node.onDealloc = ^{
      didDealloc = YES;
    };
    [node view];
    XCTAssertEqual(node.alpha, 1);
    A_SDispatchSyncOnOtherThread(^{
      node.alpha = 0;
    });
    XCTAssertEqual(node.alpha, 1);
    XCTAssert(ctrl.test_isFlushScheduled);
  }
  XCTAssertTrue(didDealloc);
}

- (void)testThatSettingABridgedViewPropertyInBackgroundGetsFlushedOnNextRunLoop
{
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  XCTAssertEqual(node.alpha, 1);
  A_SDispatchSyncOnOtherThread(^{
    node.alpha = 0;
  });
  XCTAssertEqual(node.alpha, 1);
  [self waitForMainDispatchQueueToFlush];
  XCTAssertEqual(node.alpha, 0);
}

- (void)testThatSettingABridgedLayerPropertyInBackgroundGetsFlushedOnNextRunLoop
{
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  XCTAssertEqual(node.shadowOpacity, 0);
  A_SDispatchSyncOnOtherThread(^{
    node.shadowOpacity = 1;
  });
  XCTAssertEqual(node.shadowOpacity, 0);
  [self waitForMainDispatchQueueToFlush];
  XCTAssertEqual(node.shadowOpacity, 1);
}

- (void)testThatReadingABridgedViewPropertyInBackgroundThrowsAnException
{
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  A_SDispatchSyncOnOtherThread(^{
    XCTAssertThrows(node.alpha);
  });
}

- (void)testThatReadingABridgedLayerPropertyInBackgroundThrowsAnException
{
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  A_SDispatchSyncOnOtherThread(^{
    XCTAssertThrows(node.contentsScale);
  });
}

- (void)testThatManuallyFlushingTheSyncControllerImmediatelyAppliesChanges
{
  A_SPendingStateController *ctrl = [A_SPendingStateController sharedInstance];
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  XCTAssertEqual(node.alpha, 1);
  A_SDispatchSyncOnOtherThread(^{
    node.alpha = 0;
  });
  XCTAssertEqual(node.alpha, 1);
  [ctrl flush];
  XCTAssertEqual(node.alpha, 0);
  XCTAssertFalse(ctrl.test_isFlushScheduled);
}

- (void)testThatFlushingTheControllerInBackgroundThrows
{
  A_SPendingStateController *ctrl = [A_SPendingStateController sharedInstance];
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node view];
  XCTAssertEqual(node.alpha, 1);
  A_SDispatchSyncOnOtherThread(^{
    node.alpha = 0;
    XCTAssertThrows([ctrl flush]);
  });
}

- (void)testThatSettingABridgedPropertyOnMainThreadPassesDirectlyToView
{
  A_SPendingStateController *ctrl = [A_SPendingStateController sharedInstance];
  A_SDisplayNode *node = [A_SDisplayNode new];
  XCTAssertFalse(A_SDisplayNodeGetPendingState(node).hasChanges);
  [node view];
  XCTAssertEqual(node.alpha, 1);
  node.alpha = 0;
  XCTAssertEqual(node.view.alpha, 0);
  XCTAssertEqual(node.alpha, 0);
  XCTAssertFalse(A_SDisplayNodeGetPendingState(node).hasChanges);
  XCTAssertFalse(ctrl.test_isFlushScheduled);
}

- (void)testThatCallingSetNeedsLayoutFromBackgroundCausesItToHappenLater
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] initWithViewClass:A_SBridgedPropertiesTestView.class];
  A_SBridgedPropertiesTestView *view = (A_SBridgedPropertiesTestView *)node.view;
  XCTAssertFalse(view.receivedSetNeedsLayout);
  A_SDispatchSyncOnOtherThread(^{
    XCTAssertNoThrow([node setNeedsLayout]);
  });
  XCTAssertFalse(view.receivedSetNeedsLayout);
  [self waitForMainDispatchQueueToFlush];
  XCTAssertTrue(view.receivedSetNeedsLayout);
}

- (void)testThatCallingSetNeedsLayoutOnACellNodeFromBackgroundIsSafe
{
  A_SCellNode *node = [A_SCellNode new];
  [node view];
  A_SDispatchSyncOnOtherThread(^{
    XCTAssertNoThrow([node setNeedsLayout]);
  });
}

- (void)testThatCallingSetNeedsDisplayFromBackgroundCausesItToHappenLater
{
  A_SDisplayNode *node = [A_SDisplayNode new];
  [node.layer displayIfNeeded];
  XCTAssertFalse(node.layer.needsDisplay);
  A_SDispatchSyncOnOtherThread(^{
    XCTAssertNoThrow([node setNeedsDisplay]);
  });
  XCTAssertFalse(node.layer.needsDisplay);
  [self waitForMainDispatchQueueToFlush];
  XCTAssertTrue(node.layer.needsDisplay);
}

/// [XCTExpectation expectationWithPredicate:] should handle this
/// but under Xcode 7.2.1 its polling interval is 1 second
/// which makes the tests really slow and I'm impatient.
- (void)waitForMainDispatchQueueToFlush
{
  __block BOOL done = NO;
  dispatch_async(dispatch_get_main_queue(), ^{
    done = YES;
  });
  while (!done) {
    [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
  }
}

@end
