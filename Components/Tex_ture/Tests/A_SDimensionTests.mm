//
//  A_SDimensionTests.mm
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
#import "A_SXCTExtensions.h"
#import <Async_DisplayKit/A_SDimension.h>


@interface A_SDimensionTests : XCTestCase
@end

@implementation A_SDimensionTests

- (void)testCreatingDimensionUnitAutos
{
  XCTAssertNoThrow(A_SDimensionMake(A_SDimensionUnitAuto, 0));
  XCTAssertThrows(A_SDimensionMake(A_SDimensionUnitAuto, 100));
  A_SXCTAssertEqualDimensions(A_SDimensionAuto, A_SDimensionMake(@""));
  A_SXCTAssertEqualDimensions(A_SDimensionAuto, A_SDimensionMake(@"auto"));
}

- (void)testCreatingDimensionUnitFraction
{
  XCTAssertNoThrow(A_SDimensionMake(A_SDimensionUnitFraction, 0.5));
  A_SXCTAssertEqualDimensions(A_SDimensionMake(A_SDimensionUnitFraction, 0.5), A_SDimensionMake(@"50%"));
}

- (void)testCreatingDimensionUnitPoints
{
  XCTAssertNoThrow(A_SDimensionMake(A_SDimensionUnitPoints, 100));
  A_SXCTAssertEqualDimensions(A_SDimensionMake(A_SDimensionUnitPoints, 100), A_SDimensionMake(@"100pt"));
}

- (void)testIntersectingOverlappingSizeRangesReturnsTheirIntersection
{
  //  range: |---------|
  //  other:      |----------|
  // result:      |----|

  A_SSizeRange range = {{0,0}, {10,10}};
  A_SSizeRange other = {{7,7}, {15,15}};
  A_SSizeRange result = A_SSizeRangeIntersect(range, other);
  A_SSizeRange expected = {{7,7}, {10,10}};
  XCTAssertTrue(A_SSizeRangeEqualToSizeRange(result, expected), @"Expected %@ but got %@", NSStringFromA_SSizeRange(expected), NSStringFromA_SSizeRange(result));
}

- (void)testIntersectingSizeRangeWithRangeThatContainsItReturnsSameRange
{
  //  range:    |-----|
  //  other:  |---------|
  // result:    |-----|

  A_SSizeRange range = {{2,2}, {8,8}};
  A_SSizeRange other = {{0,0}, {10,10}};
  A_SSizeRange result = A_SSizeRangeIntersect(range, other);
  A_SSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(A_SSizeRangeEqualToSizeRange(result, expected), @"Expected %@ but got %@", NSStringFromA_SSizeRange(expected), NSStringFromA_SSizeRange(result));
}

- (void)testIntersectingSizeRangeWithRangeContainedWithinItReturnsContainedRange
{
  //  range:  |---------|
  //  other:    |-----|
  // result:    |-----|

  A_SSizeRange range = {{0,0}, {10,10}};
  A_SSizeRange other = {{2,2}, {8,8}};
  A_SSizeRange result = A_SSizeRangeIntersect(range, other);
  A_SSizeRange expected = {{2,2}, {8,8}};
  XCTAssertTrue(A_SSizeRangeEqualToSizeRange(result, expected), @"Expected %@ but got %@", NSStringFromA_SSizeRange(expected), NSStringFromA_SSizeRange(result));
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToRightReturnsSinglePointNearestOtherRange
{
  //  range: |-----|
  //  other:          |---|
  // result:       *

  A_SSizeRange range = {{0,0}, {5,5}};
  A_SSizeRange other = {{10,10}, {15,15}};
  A_SSizeRange result = A_SSizeRangeIntersect(range, other);
  A_SSizeRange expected = {{5,5}, {5,5}};
  XCTAssertTrue(A_SSizeRangeEqualToSizeRange(result, expected), @"Expected %@ but got %@", NSStringFromA_SSizeRange(expected), NSStringFromA_SSizeRange(result));
}

- (void)testIntersectingSizeRangeWithNonOverlappingRangeToLeftReturnsSinglePointNearestOtherRange
{
  //  range:          |---|
  //  other: |-----|
  // result:          *

  A_SSizeRange range = {{10,10}, {15,15}};
  A_SSizeRange other = {{0,0}, {5,5}};
  A_SSizeRange result = A_SSizeRangeIntersect(range, other);
  A_SSizeRange expected = {{10,10}, {10,10}};
  XCTAssertTrue(A_SSizeRangeEqualToSizeRange(result, expected), @"Expected %@ but got %@", NSStringFromA_SSizeRange(expected), NSStringFromA_SSizeRange(result));
}

@end
