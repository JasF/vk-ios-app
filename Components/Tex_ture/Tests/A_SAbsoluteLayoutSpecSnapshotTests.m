//
//  A_SAbsoluteLayoutSpecSnapshotTests.m
//  Tex_ture
//
//  Created by Huy Nguyen on 18/10/15.
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

#import "A_SLayoutSpecSnapshotTestsHelper.h"

#import <Async_DisplayKit/A_SAbsoluteLayoutSpec.h>
#import <Async_DisplayKit/A_SBackgroundLayoutSpec.h>

@interface A_SAbsoluteLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SAbsoluteLayoutSpecSnapshotTests

- (void)testSizingBehaviour
{
  [self testWithSizeRange:A_SSizeRangeMake(CGSizeMake(150, 200), CGSizeMake(INFINITY, INFINITY))
               identifier:@"underflowChildren"];
  [self testWithSizeRange:A_SSizeRangeMake(CGSizeZero, CGSizeMake(50, 100))
               identifier:@"overflowChildren"];
  // Expect the spec to wrap its content because children sizes are between constrained size
  [self testWithSizeRange:A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY / 2, INFINITY / 2))
               identifier:@"wrappedChildren"];
}

- (void)testChildrenMeasuredWithAutoMaxSize
{
  A_SDisplayNode *firstChild = A_SDisplayNodeWithBackgroundColor([UIColor redColor], (CGSize){50, 50});
  firstChild.style.layoutPosition = CGPointMake(0, 0);
  
  A_SDisplayNode *secondChild = A_SDisplayNodeWithBackgroundColor([UIColor blueColor], (CGSize){100, 100});
  secondChild.style.layoutPosition = CGPointMake(10, 60);

  A_SSizeRange sizeRange = A_SSizeRangeMake(CGSizeMake(10, 10), CGSizeMake(110, 160));
  [self testWithChildren:@[firstChild, secondChild] sizeRange:sizeRange identifier:nil];
}

- (void)testWithSizeRange:(A_SSizeRange)sizeRange identifier:(NSString *)identifier
{
  A_SDisplayNode *firstChild = A_SDisplayNodeWithBackgroundColor([UIColor redColor], (CGSize){50, 50});
  firstChild.style.layoutPosition = CGPointMake(0, 0);
  
  A_SDisplayNode *secondChild = A_SDisplayNodeWithBackgroundColor([UIColor blueColor], (CGSize){100, 100});
  secondChild.style.layoutPosition = CGPointMake(0, 50);
  
  [self testWithChildren:@[firstChild, secondChild] sizeRange:sizeRange identifier:identifier];
}

- (void)testWithChildren:(NSArray *)children sizeRange:(A_SSizeRange)sizeRange identifier:(NSString *)identifier
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor whiteColor]);

  NSMutableArray *subnodes = [NSMutableArray arrayWithArray:children];
  [subnodes insertObject:backgroundNode atIndex:0];

  A_SLayoutSpec *layoutSpec =
  [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:
   [A_SAbsoluteLayoutSpec
    absoluteLayoutSpecWithChildren:children]
   background:backgroundNode];
  
  [self testLayoutSpec:layoutSpec sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

@end
