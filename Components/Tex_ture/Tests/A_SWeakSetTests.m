//
//  A_SWeakSetTests.m
//  Tex_ture
//
//  Created by Adlai Holler on 1/7/16.
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
#import <Async_DisplayKit/A_SWeakSet.h>

@interface A_SWeakSetTests : XCTestCase

@end

@implementation A_SWeakSetTests

- (void)testAddingACoupleRetainedObjects
{
  A_SWeakSet <NSString *> *weakSet = [A_SWeakSet new];
  NSString *hello = @"hello";
  NSString *world = @"hello";
  [weakSet addObject:hello];
  [weakSet addObject:world];
  XCTAssert([weakSet containsObject:hello]);
  XCTAssert([weakSet containsObject:world]);
  XCTAssert(![weakSet containsObject:@"apple"]);
}

- (void)testThatCountIncorporatesDeallocatedObjects
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  XCTAssertEqual(weakSet.count, 0);
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertEqual(weakSet.count, 2);

  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertEqual(weakSet.count, 3);
  }

  XCTAssertEqual(weakSet.count, 2);
}

- (void)testThatIsEmptyIncorporatesDeallocatedObjects
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  XCTAssertTrue(weakSet.isEmpty);
  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertFalse(weakSet.isEmpty);
  }
  XCTAssertTrue(weakSet.isEmpty);
}

- (void)testThatContainsObjectWorks
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertFalse([weakSet containsObject:b]);
}

- (void)testThatRemoveObjectWorks
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertTrue([weakSet containsObject:b]);
  XCTAssertEqual(weakSet.count, 2);

  [weakSet removeObject:b];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertFalse([weakSet containsObject:b]);
  XCTAssertEqual(weakSet.count, 1);
}

- (void)testThatFastEnumerationWorks
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];

  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertEqual(weakSet.count, 3);
  }

  NSInteger i = 0;
  NSMutableSet *awaitingObjects = [NSMutableSet setWithObjects:a, b, nil];
  for (NSObject *object in weakSet) {
    XCTAssertTrue([awaitingObjects containsObject:object]);
    [awaitingObjects removeObject:object];
    i += 1;
  }

  XCTAssertEqual(i, 2);
}

- (void)testThatRemoveAllObjectsWorks
{
  A_SWeakSet *weakSet = [A_SWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertEqual(weakSet.count, 2);

  [weakSet removeAllObjects];

  XCTAssertEqual(weakSet.count, 0);

  NSInteger i = 0;
  for (__unused NSObject *object in weakSet) {
    i += 1;
  }

  XCTAssertEqual(i, 0);
}

@end
