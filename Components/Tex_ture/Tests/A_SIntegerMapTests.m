//
//  A_SIntegerMapTests.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "A_STestCase.h"
#import "A_SIntegerMap.h"

@interface A_SIntegerMapTests : A_STestCase

@end

@implementation A_SIntegerMapTests

- (void)testIsEqual
{
  A_SIntegerMap *map = [[A_SIntegerMap alloc] init];
  [map setInteger:1 forKey:0];
  A_SIntegerMap *alsoMap = [[A_SIntegerMap alloc] init];
  [alsoMap setInteger:1 forKey:0];
  A_SIntegerMap *notMap = [[A_SIntegerMap alloc] init];
  [notMap setInteger:2 forKey:0];
  XCTAssertEqualObjects(map, alsoMap);
  XCTAssertNotEqualObjects(map, notMap);
}

#pragma mark - Changeset mapping

/// 1 item, no changes -> identity map
- (void)testEmptyChange
{
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:1 deleted:nil inserted:nil];
  XCTAssertEqual(map, A_SIntegerMap.identityMap);
}

/// 0 items -> empty map
- (void)testChangeOnNoData
{
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:0 deleted:nil inserted:nil];
  XCTAssertEqual(map, A_SIntegerMap.emptyMap);
}

/// 2 items, delete 0
- (void)testBasicChange1
{
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:2 deleted:[NSIndexSet indexSetWithIndex:0] inserted:nil];
  XCTAssertEqual([map integerForKey:0], NSNotFound);
  XCTAssertEqual([map integerForKey:1], 0);
  XCTAssertEqual([map integerForKey:2], NSNotFound);
}

/// 2 items, insert 0
- (void)testBasicChange2
{
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:2 deleted:nil inserted:[NSIndexSet indexSetWithIndex:0]];
  XCTAssertEqual([map integerForKey:0], 1);
  XCTAssertEqual([map integerForKey:1], 2);
  XCTAssertEqual([map integerForKey:2], NSNotFound);
}

/// 2 items, insert 0, delete 0
- (void)testChange1
{
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:2 deleted:[NSIndexSet indexSetWithIndex:0] inserted:[NSIndexSet indexSetWithIndex:0]];
  XCTAssertEqual([map integerForKey:0], NSNotFound);
  XCTAssertEqual([map integerForKey:1], 1);
  XCTAssertEqual([map integerForKey:2], NSNotFound);
}

/// 4 items, insert {0-1, 3}
- (void)testChange2
{
  NSMutableIndexSet *inserts = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
  [inserts addIndex:3];
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:4 deleted:nil inserted:inserts];
  XCTAssertEqual([map integerForKey:0], 2);
  XCTAssertEqual([map integerForKey:1], 4);
  XCTAssertEqual([map integerForKey:2], 5);
  XCTAssertEqual([map integerForKey:3], 6);
}

/// 4 items, delete {0-1, 3}
- (void)testChange3
{
  NSMutableIndexSet *deletes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
  [deletes addIndex:3];
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:4 deleted:deletes inserted:nil];
  XCTAssertEqual([map integerForKey:0], NSNotFound);
  XCTAssertEqual([map integerForKey:1], NSNotFound);
  XCTAssertEqual([map integerForKey:2], 0);
  XCTAssertEqual([map integerForKey:3], NSNotFound);
}

/// 5 items, delete {0-1, 3} insert {1-2, 4}
- (void)testChange4
{
  NSMutableIndexSet *deletes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
  [deletes addIndex:3];
  NSMutableIndexSet *inserts = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)];
  [inserts addIndex:4];
  A_SIntegerMap *map = [A_SIntegerMap mapForUpdateWithOldCount:5 deleted:deletes inserted:inserts];
  XCTAssertEqual([map integerForKey:0], NSNotFound);
  XCTAssertEqual([map integerForKey:1], NSNotFound);
  XCTAssertEqual([map integerForKey:2], 0);
  XCTAssertEqual([map integerForKey:3], NSNotFound);
  XCTAssertEqual([map integerForKey:4], 3);
  XCTAssertEqual([map integerForKey:5], NSNotFound);
}

@end
