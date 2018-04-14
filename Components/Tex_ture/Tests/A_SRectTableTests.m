//
//  A_SRectTableTests.m
//  Tex_ture
//
//  Created by Adlai Holler on 2/24/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "A_SRectTable.h"
#import "A_SXCTExtensions.h"

@interface A_SRectTableTests : XCTestCase
@end

@implementation A_SRectTableTests

- (void)testThatItStoresRects
{
  A_SRectTable *table = [A_SRectTable rectTableForWeakObjectPointers];
  NSObject *key0 = [[NSObject alloc] init];
  NSObject *key1 = [[NSObject alloc] init];
  A_SXCTAssertEqualRects([table rectForKey:key0], CGRectNull);
  A_SXCTAssertEqualRects([table rectForKey:key1], CGRectNull);
  CGRect rect0 = CGRectMake(0, 0, 100, 100);
  CGRect rect1 = CGRectMake(0, 0, 50, 50);
  [table setRect:rect0 forKey:key0];
  [table setRect:rect1 forKey:key1];

  A_SXCTAssertEqualRects([table rectForKey:key0], rect0);
  A_SXCTAssertEqualRects([table rectForKey:key1], rect1);
}


- (void)testCopying
{
  A_SRectTable *table = [A_SRectTable rectTableForWeakObjectPointers];
  NSObject *key = [[NSObject alloc] init];
  A_SXCTAssertEqualRects([table rectForKey:key], CGRectNull);
  CGRect rect0 = CGRectMake(0, 0, 100, 100);
  CGRect rect1 = CGRectMake(0, 0, 50, 50);
  [table setRect:rect0 forKey:key];
  A_SRectTable *copy = [table copy];
  [copy setRect:rect1 forKey:key];

  A_SXCTAssertEqualRects([table rectForKey:key], rect0);
  A_SXCTAssertEqualRects([copy rectForKey:key], rect1);
}

@end
