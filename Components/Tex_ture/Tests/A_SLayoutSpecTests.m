//
//  A_SLayoutSpecTests.m
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
#import <Async_DisplayKit/A_SLayoutElementExtensibility.h>

#pragma mark - A_SDKExtendedLayoutSpec

/*
 * Extend the A_SDKExtendedLayoutElement
 * It adds a
 *  - primitive / CGFloat (extendedWidth)
 *  - struct / A_SDimension (extendedDimension)
 *  - primitive / A_SStackLayoutDirection (extendedDirection)
 */
@protocol A_SDKExtendedLayoutElement <NSObject>
@property (assign, nonatomic) CGFloat extendedWidth;
@property (assign, nonatomic) A_SDimension extendedDimension;
@property (copy, nonatomic) NSString *extendedName;
@end

/*
 * Let the A_SLayoutElementStyle conform to the A_SDKExtendedLayoutElement protocol and add properties implementation
 */
@interface A_SLayoutElementStyle (A_SDKExtendedLayoutElement) <A_SDKExtendedLayoutElement>
@end

@implementation A_SLayoutElementStyle (A_SDKExtendedLayoutElement)
A_SDK_STYLE_PROP_PRIM(CGFloat, extendedWidth, setExtendedWidth, 0);
A_SDK_STYLE_PROP_STR(A_SDimension, extendedDimension, setExtendedDimension, A_SDimensionMake(A_SDimensionUnitAuto, 0));
A_SDK_STYLE_PROP_OBJ(NSString *, extendedName, setExtendedName);
@end

/*
 * As the A_SLayoutElementStyle conforms to the A_SDKExtendedLayoutElement protocol now, A_SDKExtendedLayoutElement properties
 * can be accessed in A_SDKExtendedLayoutSpec
 */
@interface A_SDKExtendedLayoutSpec : A_SLayoutSpec
@end

@implementation A_SDKExtendedLayoutSpec

- (void)doSetSomeStyleValuesToChildren
{
  for (id<A_SLayoutElement> child in self.children) {
    child.style.extendedWidth = 100;
    child.style.extendedDimension = A_SDimensionMake(100);
    child.style.extendedName = @"A_SDK";
  }
}

- (void)doUseSomeStyleValuesFromChildren
{
  for (id<A_SLayoutElement> child in self.children) {
    __unused CGFloat extendedWidth = child.style.extendedWidth;
    __unused A_SDimension extendedDimension = child.style.extendedDimension;
    __unused NSString *extendedName = child.style.extendedName;
  }
}

@end


#pragma mark - A_SLayoutSpecTests

@interface A_SLayoutSpecTests : XCTestCase

@end

@implementation A_SLayoutSpecTests

- (void)testSetPrimitiveToExtendedStyle
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.style.extendedWidth = 100;
  XCTAssert(node.style.extendedWidth == 100, @"Primitive value should be set on extended style");
}

- (void)testSetStructToExtendedStyle
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.style.extendedDimension = A_SDimensionMake(100);
  XCTAssertTrue(A_SDimensionEqualToDimension(node.style.extendedDimension, A_SDimensionMake(100)), @"Struct should be set on extended style");
}

- (void)testSetObjectToExtendedStyle
{
  NSString *extendedName = @"A_SDK";
  
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.style.extendedName = extendedName;
  XCTAssertEqualObjects(node.style.extendedName, extendedName, @"Object should be set on extended style");
}


- (void)testUseOfExtendedStyleProperties
{
  A_SDKExtendedLayoutSpec *extendedLayoutSpec = [A_SDKExtendedLayoutSpec new];
  extendedLayoutSpec.children = @[[[A_SDisplayNode alloc] init], [[A_SDisplayNode alloc] init]];
  XCTAssertNoThrow([extendedLayoutSpec doSetSomeStyleValuesToChildren]);
  XCTAssertNoThrow([extendedLayoutSpec doUseSomeStyleValuesFromChildren]);
}

@end
