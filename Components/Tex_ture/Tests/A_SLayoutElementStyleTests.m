//
//  A_SLayoutElementStyleTests.mm
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
#import <Async_DisplayKit/A_SLayoutElement.h>

#pragma mark - A_SLayoutElementStyleTestsDelegate

@interface A_SLayoutElementStyleTestsDelegate : NSObject<A_SLayoutElementStyleDelegate>
@property (copy, nonatomic) NSString *propertyNameChanged;
@end

@implementation A_SLayoutElementStyleTestsDelegate

- (void)style:(id)style propertyDidChange:(NSString *)propertyName
{
  self.propertyNameChanged = propertyName;
}

@end

#pragma mark - A_SLayoutElementStyleTests

@interface A_SLayoutElementStyleTests : XCTestCase

@end

@implementation A_SLayoutElementStyleTests

- (void)testSettingSize
{
  A_SLayoutElementStyle *style = [A_SLayoutElementStyle new];
  
  style.width = A_SDimensionMake(100);
  style.height = A_SDimensionMake(100);
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionMake(100)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.height, A_SDimensionMake(100)));
  
  style.minWidth = A_SDimensionMake(100);
  style.minHeight = A_SDimensionMake(100);
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionMake(100)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.height, A_SDimensionMake(100)));
  
  style.maxWidth = A_SDimensionMake(100);
  style.maxHeight = A_SDimensionMake(100);
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionMake(100)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.height, A_SDimensionMake(100)));
}

- (void)testSettingSizeViaCGSize
{
  A_SLayoutElementStyle *style = [A_SLayoutElementStyle new];
  
  A_SXCTAssertEqualSizes(style.preferredSize, CGSizeZero);
  
  CGSize size = CGSizeMake(100, 100);
  
  style.preferredSize = size;
  A_SXCTAssertEqualSizes(style.preferredSize, size);
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.height, A_SDimensionMakeWithPoints(size.height)));
  
  style.minSize = size;
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minWidth, A_SDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minHeight, A_SDimensionMakeWithPoints(size.height)));
  
  style.maxSize = size;
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxWidth, A_SDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxHeight, A_SDimensionMakeWithPoints(size.height)));
}

- (void)testReadingInvalidSizeForPreferredSize
{
  A_SLayoutElementStyle *style = [A_SLayoutElementStyle new];
  
  XCTAssertNoThrow(style.preferredSize);
  
  style.width = A_SDimensionMake(A_SDimensionUnitFraction, 0.5);
  XCTAssertThrows(style.preferredSize);
  
  style.preferredSize = CGSizeMake(100, 100);
  XCTAssertNoThrow(style.preferredSize);
}

- (void)testSettingSizeViaLayoutSize
{
  A_SLayoutElementStyle *style = [A_SLayoutElementStyle new];
  
  A_SLayoutSize layoutSize = A_SLayoutSizeMake(A_SDimensionMake(100), A_SDimensionMake(100));
  
  style.preferredLayoutSize = layoutSize;
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.height, layoutSize.height));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.preferredLayoutSize.width, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.preferredLayoutSize.height, layoutSize.height));
  
  style.minLayoutSize = layoutSize;
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minWidth, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minHeight, layoutSize.height));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minLayoutSize.width, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.minLayoutSize.height, layoutSize.height));
  
  style.maxLayoutSize = layoutSize;
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxWidth, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxHeight, layoutSize.height));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxLayoutSize.width, layoutSize.width));
  XCTAssertTrue(A_SDimensionEqualToDimension(style.maxLayoutSize.height, layoutSize.height));
}
  
- (void)testSettingPropertiesWillCallDelegate
{
  A_SLayoutElementStyleTestsDelegate *delegate = [A_SLayoutElementStyleTestsDelegate new];
  A_SLayoutElementStyle *style = [[A_SLayoutElementStyle alloc] initWithDelegate:delegate];
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionAuto));
  style.width = A_SDimensionMake(100);
  XCTAssertTrue(A_SDimensionEqualToDimension(style.width, A_SDimensionMake(100)));
  XCTAssertTrue([delegate.propertyNameChanged isEqualToString:A_SLayoutElementStyleWidthProperty]);
}

@end
