//
//  A_SNavigationControllerTests.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import "A_SNavigationController.h"

@interface A_SNavigationControllerTests : XCTestCase
@end

@implementation A_SNavigationControllerTests

- (void)testSetViewControllers {
  A_SViewController *firstController = [A_SViewController new];
  A_SViewController *secondController = [A_SViewController new];
  NSArray *expectedViewControllerStack = @[firstController, secondController];
  A_SNavigationController *navigationController = [A_SNavigationController new];
  [navigationController setViewControllers:@[firstController, secondController]];
  XCTAssertEqual(navigationController.topViewController, secondController);
  XCTAssertEqual(navigationController.visibleViewController, secondController);
  XCTAssertTrue([navigationController.viewControllers isEqualToArray:expectedViewControllerStack]);
}

- (void)testPopViewController {
  A_SViewController *firstController = [A_SViewController new];
  A_SViewController *secondController = [A_SViewController new];
  NSArray *expectedViewControllerStack = @[firstController];
  A_SNavigationController *navigationController = [A_SNavigationController new];
  [navigationController setViewControllers:@[firstController, secondController]];
  [navigationController popViewControllerAnimated:false];
  XCTAssertEqual(navigationController.topViewController, firstController);
  XCTAssertEqual(navigationController.visibleViewController, firstController);
  XCTAssertTrue([navigationController.viewControllers isEqualToArray:expectedViewControllerStack]);
}

- (void)testPushViewController {
  A_SViewController *firstController = [A_SViewController new];
  A_SViewController *secondController = [A_SViewController new];
  NSArray *expectedViewControllerStack = @[firstController, secondController];
  A_SNavigationController *navigationController = [[A_SNavigationController new] initWithRootViewController:firstController];
  [navigationController pushViewController:secondController animated:false];
  XCTAssertEqual(navigationController.topViewController, secondController);
  XCTAssertEqual(navigationController.visibleViewController, secondController);
  XCTAssertTrue([navigationController.viewControllers isEqualToArray:expectedViewControllerStack]);
}

@end
