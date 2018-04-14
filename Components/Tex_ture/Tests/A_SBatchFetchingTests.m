//
//  A_SBatchFetchingTests.m
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
#import <Async_DisplayKit/A_SBatchFetching.h>

@interface A_SBatchFetchingTests : XCTestCase

@end

@implementation A_SBatchFetchingTests

#define PA_SSING_RECT CGRectMake(0,0,1,1)
#define PA_SSING_SIZE CGSizeMake(1,1)
#define PA_SSING_POINT CGPointMake(1,1)
#define VERTICAL_RECT(h) CGRectMake(0,0,1,h)
#define VERTICAL_SIZE(h) CGSizeMake(0,h)
#define VERTICAL_OFFSET(y) CGPointMake(0,y)
#define HORIZONTAL_RECT(w) CGRectMake(0,0,w,1)
#define HORIZONTAL_SIZE(w) CGSizeMake(w,0)
#define HORIZONTAL_OFFSET(x) CGPointMake(x,0)

- (void)testBatchNullState {
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, CGRectZero, CGSizeZero, CGPointZero, 0.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == NO, @"Should not fetch in the null state");
}

- (void)testBatchAlreadyFetching {
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  [context beginBatchFetching];
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, PA_SSING_RECT, PA_SSING_SIZE, PA_SSING_POINT, 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == NO, @"Should not fetch when context is already fetching");
}

- (void)testUnsupportedScrollDirections {
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  BOOL fetchRight = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionRight, A_SScrollDirectionHorizontalDirections, PA_SSING_RECT, PA_SSING_SIZE, PA_SSING_POINT, 1.0, YES, CGPointZero, nil);
  XCTAssert(fetchRight == YES, @"Should fetch for scrolling right");
  BOOL fetchDown = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, PA_SSING_RECT, PA_SSING_SIZE, PA_SSING_POINT, 1.0, YES, CGPointZero, nil);
  XCTAssert(fetchDown == YES, @"Should fetch for scrolling down");
  BOOL fetchUp = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionUp, A_SScrollDirectionVerticalDirections, PA_SSING_RECT, PA_SSING_SIZE, PA_SSING_POINT, 1.0, YES, CGPointZero, nil);
  XCTAssert(fetchUp == NO, @"Should not fetch for scrolling up");
  BOOL fetchLeft = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionLeft, A_SScrollDirectionHorizontalDirections, PA_SSING_RECT, PA_SSING_SIZE, PA_SSING_POINT, 1.0, YES, CGPointZero, nil);
  XCTAssert(fetchLeft == NO, @"Should not fetch for scrolling left");
}

- (void)testVerticalScrollToExactLeading {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // scroll to 1-screen top offset, height is 1 screen, so bottom is 1 screen away from end of content
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 1.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when vertically scrolling to exactly 1 leading screen away");
}

- (void)testVerticalScrollToLessThanLeading {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // 3 screens of content, scroll only 1/2 of one screen
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 0.5), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == NO, @"Fetch should not begin when vertically scrolling less than the leading distance away");
}

- (void)testVerticalScrollingPastContentSize {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // 3 screens of content, top offset to 3-screens, height 1 screen, so its 1 screen past the leading
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 3.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when vertically scrolling past the content size");
}

- (void)testHorizontalScrollToExactLeading {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // scroll to 1-screen left offset, width is 1 screen, so right is 1 screen away from end of content
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionRight, A_SScrollDirectionVerticalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 1.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when horizontally scrolling to exactly 1 leading screen away");
}

- (void)testHorizontalScrollToLessThanLeading {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // 3 screens of content, scroll only 1/2 of one screen
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionLeft, A_SScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 0.5), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == NO, @"Fetch should not begin when horizontally scrolling less than the leading distance away");
}

- (void)testHorizontalScrollingPastContentSize {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // 3 screens of content, left offset to 3-screens, width 1 screen, so its 1 screen past the leading
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 3.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when vertically scrolling past the content size");
}

- (void)testVerticalScrollingSmallContentSize {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // when the content size is < screen size, the target offset will always be 0
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionDown, A_SScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 0.5), VERTICAL_OFFSET(0.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");
}

- (void)testHorizontalScrollingSmallContentSize {
  CGFloat screen = 1.0;
  A_SBatchContext *context = [[A_SBatchContext alloc] init];
  // when the content size is < screen size, the target offset will always be 0
  BOOL shouldFetch = A_SDisplayShouldFetchBatchForContext(context, A_SScrollDirectionRight, A_SScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 0.5), HORIZONTAL_OFFSET(0.0), 1.0, YES, CGPointZero, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");
}

@end
