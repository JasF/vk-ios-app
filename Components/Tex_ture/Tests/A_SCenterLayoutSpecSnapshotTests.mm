//
//  A_SCenterLayoutSpecSnapshotTests.mm
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
#import <Async_DisplayKit/A_SCenterLayoutSpec.h>
#import <Async_DisplayKit/A_SStackLayoutSpec.h>

static const A_SSizeRange kSize = {{100, 120}, {320, 160}};

@interface A_SCenterLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SCenterLayoutSpecSnapshotTests

- (void)testWithOptions
{
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringNone sizingOptions:{}];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringXY sizingOptions:{}];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringX sizingOptions:{}];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringY sizingOptions:{}];
}

- (void)testWithSizingOptions
{
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringNone
                   sizingOptions:A_SCenterLayoutSpecSizingOptionDefault];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringNone
                   sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumX];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringNone
                   sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumY];
  [self testWithCenteringOptions:A_SCenterLayoutSpecCenteringNone
                   sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumXY];
}

- (void)testWithCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)options
                   sizingOptions:(A_SCenterLayoutSpecSizingOptions)sizingOptions
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], CGSizeMake(70, 100));

  A_SLayoutSpec *layoutSpec =
  [A_SBackgroundLayoutSpec
   backgroundLayoutSpecWithChild:
   [A_SCenterLayoutSpec
    centerLayoutSpecWithCenteringOptions:options
    sizingOptions:sizingOptions
    child:foregroundNode]
   background:backgroundNode];

  [self testLayoutSpec:layoutSpec
             sizeRange:kSize
              subnodes:@[backgroundNode, foregroundNode]
            identifier:suffixForCenteringOptions(options, sizingOptions)];
}

static NSString *suffixForCenteringOptions(A_SCenterLayoutSpecCenteringOptions centeringOptions,
                                           A_SCenterLayoutSpecSizingOptions sizingOptinos)
{
  NSMutableString *suffix = [NSMutableString string];

  if ((centeringOptions & A_SCenterLayoutSpecCenteringX) != 0) {
    [suffix appendString:@"CenteringX"];
  }

  if ((centeringOptions & A_SCenterLayoutSpecCenteringY) != 0) {
    [suffix appendString:@"CenteringY"];
  }

  if ((sizingOptinos & A_SCenterLayoutSpecSizingOptionMinimumX) != 0) {
    [suffix appendString:@"SizingMinimumX"];
  }

  if ((sizingOptinos & A_SCenterLayoutSpecSizingOptionMinimumY) != 0) {
    [suffix appendString:@"SizingMinimumY"];
  }

  return suffix;
}

- (void)testMinimumSizeRangeIsGivenToChildWhenNotCentering
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor], CGSizeMake(10, 10));
  foregroundNode.style.flexGrow = 1;
  
  A_SCenterLayoutSpec *layoutSpec =
  [A_SCenterLayoutSpec
   centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringNone
   sizingOptions:{}
   child:
   [A_SBackgroundLayoutSpec
    backgroundLayoutSpecWithChild:
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[foregroundNode]]
    background:backgroundNode]];

  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:@[backgroundNode, foregroundNode] identifier:nil];
}

@end
