//
//  A_SPagerNodeTests.m
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

@interface A_SPagerNodeTestDataSource : NSObject <A_SPagerDataSource>
@end

@implementation A_SPagerNodeTestDataSource

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  return self;
}

- (NSInteger)numberOfPagesInPagerNode:(A_SPagerNode *)pagerNode
{
  return 2;
}

- (A_SCellNode *)pagerNode:(A_SPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
  return [[A_SCellNode alloc] init];
}

@end

@interface A_SPagerNodeTestController: UIViewController
@property (nonatomic, strong) A_SPagerNodeTestDataSource *testDataSource;
@property (nonatomic, strong) A_SPagerNode *pagerNode;
@end

@implementation A_SPagerNodeTestController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Populate these immediately so that they're not unexpectedly nil during tests.
    self.testDataSource = [[A_SPagerNodeTestDataSource alloc] init];

    self.pagerNode = [[A_SPagerNode alloc] init];
    self.pagerNode.dataSource = self.testDataSource;
    
    [self.view addSubnode:self.pagerNode];
  }
  return self;
}

@end

@interface A_SPagerNodeTests : XCTestCase
@property (nonatomic, strong) A_SPagerNode *pagerNode;

@property (nonatomic, strong) A_SPagerNodeTestDataSource *testDataSource;
@end

@implementation A_SPagerNodeTests

- (void)testPagerReturnsIndexOfPages
{
  A_SPagerNodeTestController *testController = [self testController];
  
  A_SCellNode *cellNode = [testController.pagerNode nodeForPageAtIndex:0];
  
  XCTAssertEqual([testController.pagerNode indexOfPageWithNode:cellNode], 0);
}

- (void)testPagerReturnsNotFoundForCellThatDontExistInPager
{
  A_SPagerNodeTestController *testController = [self testController];

  A_SCellNode *badNode = [[A_SCellNode alloc] init];
  
  XCTAssertEqual([testController.pagerNode indexOfPageWithNode:badNode], NSNotFound);
}

- (void)testScrollPageToIndex
{
  A_SPagerNodeTestController *testController = [self testController];
  testController.pagerNode.frame = CGRectMake(0, 0, 500, 500);
  [testController.pagerNode scrollToPageAtIndex:1 animated:false];

  XCTAssertEqual(testController.pagerNode.currentPageIndex, 1);
}

- (A_SPagerNodeTestController *)testController
{
  A_SPagerNodeTestController *testController = [[A_SPagerNodeTestController alloc] initWithNibName:nil bundle:nil];
  UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window makeKeyAndVisible];
  window.rootViewController = testController;
    
  [testController.pagerNode reloadData];
  [testController.pagerNode setNeedsLayout];
  
  return testController;
}

// Disabled due to flakiness https://github.com/facebook/Async_DisplayKit/issues/2818
- (void)DISABLED_testThatRootPagerNodeDoesGetTheRightInsetWhilePoppingBack
{
  UICollectionViewCell *cell = nil;
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  A_SPagerNodeTestDataSource *dataSource = [[A_SPagerNodeTestDataSource alloc] init];
  A_SPagerNode *pagerNode = [[A_SPagerNode alloc] init];
  pagerNode.dataSource = dataSource;
  node.layoutSpecBlock = ^(A_SDisplayNode *node, A_SSizeRange constrainedSize){
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:pagerNode];
  };
  A_SViewController *vc = [[A_SViewController alloc] initWithNode:node];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
  window.rootViewController = nav;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];
  
  // Wait until view controller is visible
  XCTestExpectation *e = [self expectationWithDescription:@"Transition completed"];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [e fulfill];
  });
  [self waitForExpectationsWithTimeout:2 handler:nil];
  
  // Test initial values
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  cell = [pagerNode.view cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
#pragma clang diagnostic pop
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(node.frame));
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(cell.frame));
  XCTAssertEqual(pagerNode.contentOffset.y, 0);
  XCTAssertEqual(pagerNode.contentInset.top, 0);
  
  e = [self expectationWithDescription:@"Transition completed"];
  // Push another view controller
  UIViewController *vc2 = [[UIViewController alloc] init];
  vc2.view.frame = nav.view.bounds;
  vc2.view.backgroundColor = [UIColor blueColor];
  [nav pushViewController:vc2 animated:YES];
  
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.505 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [e fulfill];
  });
  [self waitForExpectationsWithTimeout:2 handler:nil];
  
  // Pop view controller
  e = [self expectationWithDescription:@"Transition completed"];
  [vc2.navigationController popViewControllerAnimated:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.505 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
    [e fulfill];
  });
  [self waitForExpectationsWithTimeout:2 handler:nil];
  
  // Test values again after popping the view controller
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  cell = [pagerNode.view cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
#pragma clang diagnostic pop
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(node.frame));
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(cell.frame));
  XCTAssertEqual(pagerNode.contentOffset.y, 0);
  XCTAssertEqual(pagerNode.contentInset.top, 0);
}

@end
