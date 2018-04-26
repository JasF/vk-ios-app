//
//  A_SWrapperSpecSnapshotTests.mm
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


#import "A_SLayoutSpecSnapshotTestsHelper.h"
#import <Async_DisplayKit/A_SBackgroundLayoutSpec.h>

@interface A_SWrapperSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SWrapperSpecSnapshotTests

- (void)testWrapperSpecWithOneElementShouldSizeToElement
{
  A_SDisplayNode *child = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  
  A_SSizeRange sizeRange = A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY));
  [self testWithChildren:@[child] sizeRange:sizeRange identifier:nil];
}

- (void)testWrapperSpecWithMultipleElementsShouldSizeToLargestElement
{
  A_SDisplayNode *firstChild = A_SDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  A_SDisplayNode *secondChild = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {100, 100});
  
  A_SSizeRange sizeRange = A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY));
  [self testWithChildren:@[secondChild, firstChild] sizeRange:sizeRange identifier:nil];
}

- (void)testWithChildren:(NSArray *)children sizeRange:(A_SSizeRange)sizeRange identifier:(NSString *)identifier
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor whiteColor]);

  NSMutableArray *subnodes = [NSMutableArray arrayWithArray:children];
  [subnodes insertObject:backgroundNode atIndex:0];

  A_SLayoutSpec *layoutSpec =
  [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:
   [A_SWrapperLayoutSpec
    wrapperWithLayoutElements:children]
   background:backgroundNode];
  
  [self testLayoutSpec:layoutSpec sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

@end
