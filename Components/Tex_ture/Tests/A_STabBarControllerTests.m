//
//  A_STabBarControllerTests.m
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
#import "A_STabBarController.h"
#import "A_SViewController.h"

@interface A_STabBarControllerTests: XCTestCase

@end

@implementation A_STabBarControllerTests

- (void)testTabBarControllerSelectIndex {
  A_SViewController *firstViewController = [A_SViewController new];
  A_SViewController *secondViewController = [A_SViewController new];
  NSArray *viewControllers = @[firstViewController, secondViewController];
  A_STabBarController *tabBarController = [A_STabBarController new];
  [tabBarController setViewControllers:viewControllers];
  [tabBarController setSelectedIndex:1];
  XCTAssertTrue([tabBarController.viewControllers isEqualToArray:viewControllers]);
  XCTAssertEqual(tabBarController.selectedViewController, secondViewController);
}

- (void)testTabBarControllerSelectViewController {
  A_SViewController *firstViewController = [A_SViewController new];
  A_SViewController *secondViewController = [A_SViewController new];
  NSArray *viewControllers = @[firstViewController, secondViewController];
  A_STabBarController *tabBarController = [A_STabBarController new];
  [tabBarController setViewControllers:viewControllers];
  [tabBarController setSelectedViewController:secondViewController];
  XCTAssertTrue([tabBarController.viewControllers isEqualToArray:viewControllers]);
  XCTAssertEqual(tabBarController.selectedViewController, secondViewController);
}

@end
