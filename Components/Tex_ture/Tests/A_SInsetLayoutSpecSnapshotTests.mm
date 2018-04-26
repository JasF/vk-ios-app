//
//  A_SInsetLayoutSpecSnapshotTests.mm
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
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>

typedef NS_OPTIONS(NSUInteger, A_SInsetLayoutSpecTestEdge) {
  A_SInsetLayoutSpecTestEdgeTop    = 1 << 0,
  A_SInsetLayoutSpecTestEdgeLeft   = 1 << 1,
  A_SInsetLayoutSpecTestEdgeBottom = 1 << 2,
  A_SInsetLayoutSpecTestEdgeRight  = 1 << 3,
};

static CGFloat insetForEdge(NSUInteger combination, A_SInsetLayoutSpecTestEdge edge, CGFloat insetValue)
{
  return combination & edge ? INFINITY : insetValue;
}

static UIEdgeInsets insetsForCombination(NSUInteger combination, CGFloat insetValue)
{
  return {
    .top = insetForEdge(combination, A_SInsetLayoutSpecTestEdgeTop, insetValue),
    .left = insetForEdge(combination, A_SInsetLayoutSpecTestEdgeLeft, insetValue),
    .bottom = insetForEdge(combination, A_SInsetLayoutSpecTestEdgeBottom, insetValue),
    .right = insetForEdge(combination, A_SInsetLayoutSpecTestEdgeRight, insetValue),
  };
}

static NSString *nameForInsets(UIEdgeInsets insets)
{
  return [NSString stringWithFormat:@"%.f-%.f-%.f-%.f", insets.top, insets.left, insets.bottom, insets.right];
}

@interface A_SInsetLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SInsetLayoutSpecSnapshotTests

- (void)testInsetsWithVariableSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor grayColor]);
    A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});
    
    A_SLayoutSpec *layoutSpec =
    [A_SBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [A_SInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];
    
    static A_SSizeRange kVariableSize = {{0, 0}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kVariableSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

- (void)testInsetsWithFixedSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor grayColor]);
    A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});
    
    A_SLayoutSpec *layoutSpec =
    [A_SBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [A_SInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];

    static A_SSizeRange kFixedSize = {{300, 300}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kFixedSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

/** Regression test, there was a bug mixing insets with infinite and zero sizes */
- (void)testInsetsWithInfinityAndZeroInsetValue
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 0);
    A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor grayColor]);
    A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});

    A_SLayoutSpec *layoutSpec =
    [A_SBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [A_SInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];

    static A_SSizeRange kFixedSize = {{300, 300}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kFixedSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

@end
