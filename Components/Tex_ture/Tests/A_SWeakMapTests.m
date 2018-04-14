//
//  A_SWeakMapTests.m
//  Tex_ture
//
//  Created by Chris Danford on 7/23/16.
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
#import <Async_DisplayKit/A_SWeakMap.h>

NS_ASSUME_NONNULL_BEGIN

@interface A_SWeakMapTests : XCTestCase

@end

@implementation A_SWeakMapTests

- (void)testKeyAndValueAreReleasedWhenEntryIsReleased
{
  A_SWeakMap <NSObject *, NSObject *> *weakMap = [[A_SWeakMap alloc] init];

  __weak NSObject *weakKey;
  __weak NSObject *weakValue;
  @autoreleasepool {
    NSObject *key = [[NSObject alloc] init];
    NSObject *value = [[NSObject alloc] init];
    A_SWeakMapEntry *entry = [weakMap setObject:value forKey:key];
    XCTAssertEqual([weakMap entryForKey:key], entry);

    weakKey = key;
    weakValue = value;
}
  XCTAssertNil(weakKey);
  XCTAssertNil(weakValue);
}

- (void)testKeyEquality
{
  A_SWeakMap <NSString *, NSObject *> *weakMap = [[A_SWeakMap alloc] init];
  NSString *keyA = @"key";
  NSString *keyB = [keyA copy];  // `isEqual` but not pointer equal
  NSObject *value = [[NSObject alloc] init];
  
  A_SWeakMapEntry *entryA = [weakMap setObject:value forKey:keyA];
  A_SWeakMapEntry *entryB = [weakMap entryForKey:keyB];
  XCTAssertEqual(entryA, entryB);
}

@end

NS_ASSUME_NONNULL_END
