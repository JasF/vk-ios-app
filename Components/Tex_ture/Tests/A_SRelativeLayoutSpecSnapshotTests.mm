//
//  A_SRelativeLayoutSpecSnapshotTests.mm
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
#import <Async_DisplayKit/A_SRelativeLayoutSpec.h>
#import <Async_DisplayKit/A_SStackLayoutSpec.h>

static const A_SSizeRange kSize = {{100, 120}, {320, 160}};

@interface A_SRelativeLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SRelativeLayoutSpecSnapshotTests

#pragma mark - XCTestCase

- (void)testWithOptions
{
  [self testAllVerticalPositionsForHorizontalPosition:A_SRelativeLayoutSpecPositionStart];
  [self testAllVerticalPositionsForHorizontalPosition:A_SRelativeLayoutSpecPositionCenter];
  [self testAllVerticalPositionsForHorizontalPosition:A_SRelativeLayoutSpecPositionEnd];

}

- (void)testAllVerticalPositionsForHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition
{
  [self testWithHorizontalPosition:horizontalPosition verticalPosition:A_SRelativeLayoutSpecPositionStart sizingOptions:{}];
  [self testWithHorizontalPosition:horizontalPosition verticalPosition:A_SRelativeLayoutSpecPositionCenter sizingOptions:{}];
  [self testWithHorizontalPosition:horizontalPosition verticalPosition:A_SRelativeLayoutSpecPositionEnd sizingOptions:{}];
}

- (void)testWithSizingOptions
{
  [self testWithHorizontalPosition:A_SRelativeLayoutSpecPositionStart
                  verticalPosition:A_SRelativeLayoutSpecPositionStart
                     sizingOptions:A_SRelativeLayoutSpecSizingOptionDefault];
  [self testWithHorizontalPosition:A_SRelativeLayoutSpecPositionStart
                  verticalPosition:A_SRelativeLayoutSpecPositionStart
                     sizingOptions:A_SRelativeLayoutSpecSizingOptionMinimumWidth];
  [self testWithHorizontalPosition:A_SRelativeLayoutSpecPositionStart
                  verticalPosition:A_SRelativeLayoutSpecPositionStart
                     sizingOptions:A_SRelativeLayoutSpecSizingOptionMinimumHeight];
  [self testWithHorizontalPosition:A_SRelativeLayoutSpecPositionStart
                  verticalPosition:A_SRelativeLayoutSpecPositionStart
                     sizingOptions:A_SRelativeLayoutSpecSizingOptionMinimumSize];
}

- (void)testWithHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition
                  verticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition
                   sizingOptions:(A_SRelativeLayoutSpecSizingOption)sizingOptions
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], CGSizeMake(70, 100));

  A_SLayoutSpec *layoutSpec =
  [A_SBackgroundLayoutSpec
   backgroundLayoutSpecWithChild:
   [A_SRelativeLayoutSpec
    relativePositionLayoutSpecWithHorizontalPosition:horizontalPosition
    verticalPosition:verticalPosition
    sizingOption:sizingOptions
    child:foregroundNode]
   background:backgroundNode];

  [self testLayoutSpec:layoutSpec
             sizeRange:kSize
              subnodes:@[backgroundNode, foregroundNode]
            identifier:suffixForPositionOptions(horizontalPosition, verticalPosition, sizingOptions)];
}

static NSString *suffixForPositionOptions(A_SRelativeLayoutSpecPosition horizontalPosition,
                                          A_SRelativeLayoutSpecPosition verticalPosition,
                                          A_SRelativeLayoutSpecSizingOption sizingOptions)
{
  NSMutableString *suffix = [NSMutableString string];

  if (horizontalPosition == A_SRelativeLayoutSpecPositionCenter) {
    [suffix appendString:@"CenterX"];
  } else if (horizontalPosition == A_SRelativeLayoutSpecPositionEnd) {
    [suffix appendString:@"EndX"];
  }

  if (verticalPosition  == A_SRelativeLayoutSpecPositionCenter) {
    [suffix appendString:@"CenterY"];
  } else if (verticalPosition == A_SRelativeLayoutSpecPositionEnd) {
    [suffix appendString:@"EndY"];
  }

  if ((sizingOptions & A_SRelativeLayoutSpecSizingOptionMinimumWidth) != 0) {
    [suffix appendString:@"SizingMinimumWidth"];
  }

  if ((sizingOptions & A_SRelativeLayoutSpecSizingOptionMinimumHeight) != 0) {
    [suffix appendString:@"SizingMinimumHeight"];
  }

  return suffix;
}

- (void)testMinimumSizeRangeIsGivenToChildWhenNotPositioning
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor], CGSizeMake(10, 10));
  foregroundNode.style.flexGrow = 1;
  
  A_SLayoutSpec *childSpec =
  [A_SBackgroundLayoutSpec
   backgroundLayoutSpecWithChild:
   [A_SStackLayoutSpec
    stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
    spacing:0
    justifyContent:A_SStackLayoutJustifyContentStart
    alignItems:A_SStackLayoutAlignItemsStart
    children:@[foregroundNode]]
   background:backgroundNode];
  
  A_SRelativeLayoutSpec *layoutSpec =
  [A_SRelativeLayoutSpec
   relativePositionLayoutSpecWithHorizontalPosition:A_SRelativeLayoutSpecPositionNone
   verticalPosition:A_SRelativeLayoutSpecPositionNone
   sizingOption:{}
   child:childSpec];

  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:@[backgroundNode, foregroundNode] identifier:nil];
}

@end
