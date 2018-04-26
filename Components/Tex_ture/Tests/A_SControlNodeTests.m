//
//  A_SControlNodeTests.m
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

#import <Async_DisplayKit/A_SControlNode.h>

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#define ACTION @selector(action)
#define ACTION_SENDER @selector(action:)
#define ACTION_SENDER_EVENT @selector(action:event:)
#define EVENT A_SControlNodeEventTouchUpInside

@interface ReceiverController : UIViewController
@property (nonatomic) NSInteger hits;
@end
@implementation ReceiverController
@end

@interface A_SActionController : ReceiverController
@end
@implementation A_SActionController
- (void)action { self.hits++; }
- (void)firstAction { }
- (void)secondAction { }
- (void)thirdAction { }
@end

@interface A_SActionSenderController : ReceiverController
@end
@implementation A_SActionSenderController
- (void)action:(id)sender { self.hits++; }
@end

@interface A_SActionSenderEventController : ReceiverController
@end
@implementation A_SActionSenderEventController
- (void)action:(id)sender event:(UIEvent *)event { self.hits++; }
@end

@interface A_SGestureController : ReceiverController
@end
@implementation A_SGestureController
- (void)onGesture:(UIGestureRecognizer *)recognizer { self.hits++; }
- (void)action:(id)sender { self.hits++; }
@end

@interface A_SControlNodeTests : XCTestCase

@end

@implementation A_SControlNodeTests

- (void)testActionWithoutParameters {
  A_SActionController *controller = [[A_SActionController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSender {
  A_SActionSenderController *controller = [[A_SActionSenderController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderAndEvent {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionWithoutTarget {
  A_SActionController *controller = [[A_SActionController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderWithoutTarget {
  A_SActionSenderController *controller = [[A_SActionSenderController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testActionAndSenderAndEventWithoutTarget {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testRemoveWithoutTargetRemovesTargetlessAction {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithTarget {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithTargetRemovesAction {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testRemoveWithoutTargetRemovesTargetedAction {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node removeTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 0, @"Controller did not receive exactly zero action events");
}

- (void)testDuplicateEntriesWithoutTarget {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 1, @"Controller did not receive exactly one action event");
}

- (void)testDuplicateEntriesWithTarget {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 1, @"Controller did not receive exactly one action event");
}

- (void)testDuplicateEntriesWithAndWithoutTarget {
  A_SActionSenderEventController *controller = [[A_SActionSenderEventController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [node addTarget:nil action:ACTION_SENDER_EVENT forControlEvents:EVENT];
  [controller.view addSubview:node.view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssertEqual(controller.hits, 2, @"Controller did not receive exactly two action events");
}

- (void)testDeeperHierarchyWithoutTarget {
  A_SActionController *controller = [[A_SActionController alloc] init];
  UIView *view = [[UIView alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:nil action:ACTION forControlEvents:EVENT];
  [view addSubview:node.view];
  [controller.view addSubview:view];
  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the action event");
}

- (void)testTouchesWorkWithGestures {
  A_SGestureController *controller = [[A_SGestureController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:@selector(action:) forControlEvents:A_SControlNodeEventTouchUpInside];
  [node.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:controller action:@selector(onGesture:)]];
  [controller.view addSubnode:node];

  [node sendActionsForControlEvents:EVENT withEvent:nil];
  XCTAssert(controller.hits == 1, @"Controller did not receive the tap event");
}

- (void)testActionsAreCalledInTheSameOrderAsTheyWereAdded {
  A_SActionController *controller = [[A_SActionController alloc] init];
  A_SControlNode *node = [[A_SControlNode alloc] init];
  [node addTarget:controller action:@selector(firstAction) forControlEvents:A_SControlNodeEventTouchUpInside];
  [node addTarget:controller action:@selector(secondAction) forControlEvents:A_SControlNodeEventTouchUpInside];
  [node addTarget:controller action:@selector(thirdAction) forControlEvents:A_SControlNodeEventTouchUpInside];
  [controller.view addSubnode:node];
  
  id controllerMock = [OCMockObject partialMockForObject:controller];
  [controllerMock setExpectationOrderMatters:YES];
  [[controllerMock expect] firstAction];
  [[controllerMock expect] secondAction];
  [[controllerMock expect] thirdAction];
  
  [node sendActionsForControlEvents:A_SControlNodeEventTouchUpInside withEvent:nil];
  
  [controllerMock verify];
}

@end
