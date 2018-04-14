//
//  A_SViewControllerTests.m
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

#import <XCTest/XCTest.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <OCMock/OCMock.h>
#import "NSInvocation+A_STestHelpers.h"

@interface A_SViewControllerTests : XCTestCase

@end

@implementation A_SViewControllerTests

- (void)testThatAutomaticSubnodeManagementScrollViewInsetsAreApplied
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  A_SScrollNode *scrollNode = [[A_SScrollNode alloc] init];
  node.layoutSpecBlock = ^(A_SDisplayNode *node, A_SSizeRange constrainedSize){
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:scrollNode];
  };
  A_SViewController *vc = [[A_SViewController alloc] initWithNode:node];
  window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
  [window makeKeyAndVisible];
  [window layoutIfNeeded];
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(node.frame));
  XCTAssertNotEqual(scrollNode.view.contentInset.top, 0);
}

- (void)testThatViewControllerFrameIsRightAfterCustomTransitionWithNonextendedEdges
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];

  A_SViewController *vc = [[A_SViewController alloc] initWithNode:node];
  vc.node.backgroundColor = [UIColor greenColor];
  vc.edgesForExtendedLayout = UIRectEdgeNone;

  UIViewController * oldVC = [[UIViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:oldVC];
  id navDelegate = [OCMockObject niceMockForProtocol:@protocol(UINavigationControllerDelegate)];
  id animator = [OCMockObject niceMockForProtocol:@protocol(UIViewControllerAnimatedTransitioning)];
  [[[[navDelegate expect] ignoringNonObjectArgs] andReturn:animator] navigationController:[OCMArg any] animationControllerForOperation:UINavigationControllerOperationPush fromViewController:[OCMArg any] toViewController:[OCMArg any]];
  [[[animator expect] andReturnValue:@0.3] transitionDuration:[OCMArg any]];
  XCTestExpectation *e = [self expectationWithDescription:@"Transition completed"];
  [[[animator expect] andDo:^(NSInvocation *invocation) {
    id<UIViewControllerContextTransitioning> ctx = [invocation as_argumentAtIndexAsObject:2];
    UIView *container = [ctx containerView];
    [container addSubview:vc.view];
    vc.view.alpha = 0;
    vc.view.frame = [ctx finalFrameForViewController:vc];
    [UIView animateWithDuration:0.3 animations:^{
      vc.view.alpha = 1;
      oldVC.view.alpha = 0;
    } completion:^(BOOL finished) {
      [oldVC.view removeFromSuperview];
      [ctx completeTransition:finished];
      [e fulfill];
    }];
  }] animateTransition:[OCMArg any]];
  nav.delegate = navDelegate;
  window.rootViewController = nav;
  [window makeKeyAndVisible];
  [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
  [nav pushViewController:vc animated:YES];

  [self waitForExpectationsWithTimeout:2 handler:nil];
 
  CGFloat navHeight = CGRectGetMaxY([nav.navigationBar convertRect:nav.navigationBar.bounds toView:window]);
  CGRect expectedRect, slice;
  CGRectDivide(window.bounds, &slice, &expectedRect, navHeight, CGRectMinYEdge);
  XCTAssertEqualObjects(NSStringFromCGRect(expectedRect), NSStringFromCGRect(node.frame));
  [navDelegate verify];
  [animator verify];
}

@end
