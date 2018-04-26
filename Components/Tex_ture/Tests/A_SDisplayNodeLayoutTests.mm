//
//  A_SDisplayNodeLayoutTests.mm
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

#import "A_SXCTExtensions.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
#import "A_SLayoutSpecSnapshotTestsHelper.h"
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <stdatomic.h>

@interface A_SDisplayNodeLayoutTests : XCTestCase
@end

@implementation A_SDisplayNodeLayoutTests

- (void)testMeasureOnLayoutIfNotHappenedBefore
{
  CGSize nodeSize = CGSizeMake(100, 100);
  
  A_SDisplayNode *displayNode = [[A_SDisplayNode alloc] init];
  displayNode.style.width = A_SDimensionMake(100);
  displayNode.style.height = A_SDimensionMake(100);
  
  // Use a button node in here as A_SButtonNode uses layoutSpecThatFits:
  A_SButtonNode *buttonNode = [A_SButtonNode new];
  [displayNode addSubnode:buttonNode];
  
  displayNode.frame = {.size = nodeSize};
  buttonNode.frame = {.size = nodeSize};
  
  A_SXCTAssertEqualSizes(displayNode.calculatedSize, CGSizeZero, @"Calculated size before measurement and layout should be 0");
  A_SXCTAssertEqualSizes(buttonNode.calculatedSize, CGSizeZero, @"Calculated size before measurement and layout should be 0");
  
  // Trigger view creation and layout pass without a manual -layoutThatFits: call before so the automatic measurement
  // pass will trigger in the layout pass
  [displayNode.view layoutIfNeeded];
  
  A_SXCTAssertEqualSizes(displayNode.calculatedSize, nodeSize, @"Automatic measurement pass should have happened in layout pass");
  A_SXCTAssertEqualSizes(buttonNode.calculatedSize, nodeSize, @"Automatic measurement pass should have happened in layout pass");
}

#if DEBUG
- (void)testNotAllowAddingSubnodesInLayoutSpecThatFits
{
  A_SDisplayNode *displayNode = [A_SDisplayNode new];
  A_SDisplayNode *someOtherNode = [A_SDisplayNode new];
  
  displayNode.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    [node addSubnode:someOtherNode];
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:someOtherNode];
  };
  
  XCTAssertThrows([displayNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))], @"Should throw if subnode was added in layoutSpecThatFits:");
}

- (void)testNotAllowModifyingSubnodesInLayoutSpecThatFits
{
  A_SDisplayNode *displayNode = [A_SDisplayNode new];
  A_SDisplayNode *someOtherNode = [A_SDisplayNode new];
  
  [displayNode addSubnode:someOtherNode];
  
  displayNode.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    [someOtherNode removeFromSupernode];
    [node addSubnode:[A_SDisplayNode new]];
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:someOtherNode];
  };
  
  XCTAssertThrows([displayNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))], @"Should throw if subnodes where modified in layoutSpecThatFits:");
}
#endif

- (void)testMeasureOnLayoutIfNotHappenedBeforeNoRemeasureForSameBounds
{
  CGSize nodeSize = CGSizeMake(100, 100);
  
  A_SDisplayNode *displayNode = [A_SDisplayNode new];
  displayNode.style.width = A_SDimensionMake(nodeSize.width);
  displayNode.style.height = A_SDimensionMake(nodeSize.height);
  
  A_SButtonNode *buttonNode = [A_SButtonNode new];
  [displayNode addSubnode:buttonNode];
  
  __block atomic_int numberOfLayoutSpecThatFitsCalls = ATOMIC_VAR_INIT(0);
  displayNode.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    atomic_fetch_add(&numberOfLayoutSpecThatFitsCalls, 1);
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:buttonNode];
  };
  
  displayNode.frame = {.size = nodeSize};
  
  // Trigger initial layout pass without a measurement pass before
  [displayNode.view layoutIfNeeded];
  XCTAssertEqual(numberOfLayoutSpecThatFitsCalls, 1, @"Should measure during layout if not measured");
  
  [displayNode layoutThatFits:A_SSizeRangeMake(nodeSize, nodeSize)];
  XCTAssertEqual(numberOfLayoutSpecThatFitsCalls, 1, @"Should not remeasure with same bounds");
}

- (void)testThatLayoutWithInvalidSizeCausesException
{
  A_SDisplayNode *displayNode = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layoutSpecBlock = ^A_SLayoutSpec *(A_SDisplayNode *node, A_SSizeRange constrainedSize) {
    return [A_SWrapperLayoutSpec wrapperWithLayoutElement:displayNode];
  };
  
  XCTAssertThrows([node layoutThatFits:A_SSizeRangeMake(CGSizeMake(0, FLT_MAX))]);
}

- (void)testThatLayoutCreatedWithInvalidSizeCausesException
{
  A_SDisplayNode *displayNode = [[A_SDisplayNode alloc] init];
  XCTAssertThrows([A_SLayout layoutWithLayoutElement:displayNode size:CGSizeMake(FLT_MAX, FLT_MAX)]);
  XCTAssertThrows([A_SLayout layoutWithLayoutElement:displayNode size:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)]);
  XCTAssertThrows([A_SLayout layoutWithLayoutElement:displayNode size:CGSizeMake(INFINITY, INFINITY)]);
}

- (void)testThatLayoutElementCreatedInLayoutSpecThatFitsDoNotGetDeallocated
{
  const CGSize kSize = CGSizeMake(300, 300);
  
  A_SDisplayNode *subNode = [[A_SDisplayNode alloc] init];
  subNode.automaticallyManagesSubnodes = YES;
  subNode.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    A_STextNode *textNode = [A_STextNode new];
    textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Test Test Test Test Test Test Test Test"];
    A_SInsetLayoutSpec *insetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:textNode];
    return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:insetSpec];
  };
  
  A_SDisplayNode *rootNode = [[A_SDisplayNode alloc] init];
  rootNode.automaticallyManagesSubnodes = YES;
  rootNode.layoutSpecBlock = ^(A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {
    A_STextNode *textNode = [A_STextNode new];
    textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Test Test Test Test Test"];
    A_SInsetLayoutSpec *insetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:textNode];
    
    return [A_SStackLayoutSpec
            stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
            spacing:0.0
            justifyContent:A_SStackLayoutJustifyContentStart
            alignItems:A_SStackLayoutAlignItemsStretch
            children:@[insetSpec, subNode]];
  };

  rootNode.frame = CGRectMake(0, 0, kSize.width, kSize.height);
  [rootNode view];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"Execute measure and layout pass"];
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    [rootNode layoutThatFits:A_SSizeRangeMake(kSize)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      XCTAssertNoThrow([rootNode.view layoutIfNeeded]);
      [expectation fulfill];
    });
  });
  
  [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
    if (error) {
      XCTFail(@"Expectation failed: %@", error);
    }
  }];
}

@end
