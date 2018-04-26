//
//  A_SDisplayNodeImplicitHierarchyTests.m
//  Tex_ture
//
//  Created by Levi McCallum on 2/1/16.
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
#import "A_SDisplayNodeTestsHelper.h"

@interface A_SSpecTestDisplayNode : A_SDisplayNode

/**
 Simple state identifier to allow control of current spec inside of the layoutSpecBlock
 */
@property (strong, nonatomic) NSNumber *layoutState;

@end

@implementation A_SSpecTestDisplayNode

- (instancetype)init
{
  self = [super init];
  if (self) {
    _layoutState = @1;
  }
  return self;
}

@end

@interface A_SDisplayNodeImplicitHierarchyTests : XCTestCase

@end

@implementation A_SDisplayNodeImplicitHierarchyTests

- (void)testFeatureFlag
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  XCTAssertFalse(node.automaticallyManagesSubnodes);
  
  node.automaticallyManagesSubnodes = YES;
  XCTAssertTrue(node.automaticallyManagesSubnodes);
}

- (void)testInitialNodeInsertionWithOrdering
{
  static CGSize kSize = {100, 100};
  
  A_SDisplayNode *node1 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node2 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node3 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node4 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node5 = [[A_SDisplayNode alloc] init];
  
  
  // As we will involve a stack spec we have to give the nodes an intrinsic content size
  node1.style.preferredSize = kSize;
  node2.style.preferredSize = kSize;
  node3.style.preferredSize = kSize;
  node4.style.preferredSize = kSize;
  node5.style.preferredSize = kSize;

  A_SSpecTestDisplayNode *node = [[A_SSpecTestDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(A_SDisplayNode *weakNode, A_SSizeRange constrainedSize) {
    A_SAbsoluteLayoutSpec *absoluteLayout = [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node4]];
    
    A_SStackLayoutSpec *stack1 = [[A_SStackLayoutSpec alloc] init];
    [stack1 setChildren:@[node1, node2]];

    A_SStackLayoutSpec *stack2 = [[A_SStackLayoutSpec alloc] init];
    [stack2 setChildren:@[node3, absoluteLayout]];
    
    return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[stack1, stack2, node5]];
  };
  
  A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)));
  [node.view layoutIfNeeded];

  XCTAssertEqual(node.subnodes[0], node1);
  XCTAssertEqual(node.subnodes[1], node2);
  XCTAssertEqual(node.subnodes[2], node3);
  XCTAssertEqual(node.subnodes[3], node4);
  XCTAssertEqual(node.subnodes[4], node5);
}

- (void)testCalculatedLayoutHierarchyTransitions
{
  static CGSize kSize = {100, 100};
  
  A_SDisplayNode *node1 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node2 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node3 = [[A_SDisplayNode alloc] init];
  
  // As we will involve a stack spec we have to give the nodes an intrinsic content size
  node1.style.preferredSize = kSize;
  node2.style.preferredSize = kSize;
  node3.style.preferredSize = kSize;
  
  A_SSpecTestDisplayNode *node = [[A_SSpecTestDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(A_SDisplayNode *weakNode, A_SSizeRange constrainedSize){
    A_SSpecTestDisplayNode *strongNode = (A_SSpecTestDisplayNode *)weakNode;
    if ([strongNode.layoutState isEqualToNumber:@1]) {
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node1, node2]];
    } else {
      A_SStackLayoutSpec *stackLayout = [[A_SStackLayoutSpec alloc] init];
      [stackLayout setChildren:@[node3, node2]];
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node1, stackLayout]];
    }
  };
  
  A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)));
  [node.view layoutIfNeeded];
  XCTAssertEqual(node.subnodes[0], node1);
  XCTAssertEqual(node.subnodes[1], node2);
  
  node.layoutState = @2;
  [node setNeedsLayout]; // After a state change the layout needs to be invalidated
  [node.view layoutIfNeeded]; // A new layout pass will trigger the hiearchy transition

  XCTAssertEqual(node.subnodes[0], node1);
  XCTAssertEqual(node.subnodes[1], node3);
  XCTAssertEqual(node.subnodes[2], node2);
}

// Disable test for now as we disabled the assertion
//- (void)testLayoutTransitionWillThrowForManualSubnodeManagement
//{
//  A_SDisplayNode *node1 = [[A_SDisplayNode alloc] init];
//  node1.name = @"node1";
//  
//  A_SSpecTestDisplayNode *node = [[A_SSpecTestDisplayNode alloc] init];
//  node.automaticallyManagesSubnodes = YES;
//  node.layoutSpecBlock = ^A_SLayoutSpec *(A_SDisplayNode *weakNode, A_SSizeRange constrainedSize){
//    return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node1]];
//  };
//  
//  XCTAssertNoThrow([node layoutThatFits:A_SSizeRangeMake(CGSizeZero)]);
//  XCTAssertThrows([node1 removeFromSupernode]);
//}

- (void)testLayoutTransitionMeasurementCompletionBlockIsCalledOnMainThread
{
  const CGSize kSize = CGSizeMake(100, 100);

  A_SDisplayNode *displayNode = [[A_SDisplayNode alloc] init];
  displayNode.style.preferredSize = kSize;
  
  // Trigger explicit view creation to be able to use the Transition API
  [displayNode view];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Call measurement completion block on main"];
  
  [displayNode transitionLayoutWithSizeRange:A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)) animated:YES shouldMeasureAsync:YES measurementCompletion:^{
    XCTAssertTrue(A_SDisplayNodeThreadIsMain(), @"Measurement completion block should be called on main thread");
    [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testMeasurementInBackgroundThreadWithLoadedNode
{
  const CGSize kNodeSize = CGSizeMake(100, 100);
  A_SDisplayNode *node1 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node2 = [[A_SDisplayNode alloc] init];
  
  A_SSpecTestDisplayNode *node = [[A_SSpecTestDisplayNode alloc] init];
  node.style.preferredSize = kNodeSize;
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(A_SDisplayNode *weakNode, A_SSizeRange constrainedSize) {
    A_SSpecTestDisplayNode *strongNode = (A_SSpecTestDisplayNode *)weakNode;
    if ([strongNode.layoutState isEqualToNumber:@1]) {
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node1]];
    } else {
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node2]];
    }
  };
  
  // Intentionally trigger view creation
  [node view];
  [node2 view];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Fix IHM layout also if one node is already loaded"];
  
  dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    // Measurement happens in the background
    A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
    
    // Dispatch back to the main thread to let the insertion / deletion of subnodes happening
    dispatch_async(dispatch_get_main_queue(), ^{
      
      // Layout on main
      [node setNeedsLayout];
      [node.view layoutIfNeeded];
      XCTAssertEqual(node.subnodes[0], node1);
      
      dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Change state and measure in the background
        node.layoutState = @2;
        [node setNeedsLayout];
    
        A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
        
        // Dispatch back to the main thread to let the insertion / deletion of subnodes happening
        dispatch_async(dispatch_get_main_queue(), ^{
          
          // Layout on main again
          [node.view layoutIfNeeded];
          XCTAssertEqual(node.subnodes[0], node2);
          
          [expectation fulfill];
        });
      });
    });
  });
  
  [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    if (error) {
      NSLog(@"Timeout Error: %@", error);
    }
  }];
}

- (void)testTransitionLayoutWithAnimationWithLoadedNodes
{
  const CGSize kNodeSize = CGSizeMake(100, 100);
  A_SDisplayNode *node1 = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node2 = [[A_SDisplayNode alloc] init];
  
  A_SSpecTestDisplayNode *node = [[A_SSpecTestDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  node.style.preferredSize = kNodeSize;
  node.layoutSpecBlock = ^(A_SDisplayNode *weakNode, A_SSizeRange constrainedSize) {
    A_SSpecTestDisplayNode *strongNode = (A_SSpecTestDisplayNode *)weakNode;
    if ([strongNode.layoutState isEqualToNumber:@1]) {
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node1]];
    } else {
      return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[node2]];
    }
  };
 
  // Intentionally trigger view creation
  [node1 view];
  [node2 view];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Fix IHM layout transition also if one node is already loaded"];
  
  A_SDisplayNodeSizeToFitSizeRange(node, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
  [node.view layoutIfNeeded];
  XCTAssertEqual(node.subnodes[0], node1);
  
  node.layoutState = @2;
  [node invalidateCalculatedLayout];
  [node transitionLayoutWithAnimation:YES shouldMeasureAsync:YES measurementCompletion:^{
    // Push this to the next runloop to let async insertion / removing of nodes finished before checking
    dispatch_async(dispatch_get_main_queue(), ^{
      XCTAssertEqual(node.subnodes[0], node2);
      [expectation fulfill];
    });
  }];
  
  [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    if (error) {
      NSLog(@"Timeout Error: %@", error);
    }
  }];
}

@end
