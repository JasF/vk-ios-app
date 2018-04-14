//
//  A_SBasicImageDownloaderContextTests.m
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

#import <Async_DisplayKit/A_SBasicImageDownloader.h>
#import <Async_DisplayKit/A_SBasicImageDownloaderInternal.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>


@interface A_SBasicImageDownloaderContextTests : XCTestCase

@end

@implementation A_SBasicImageDownloaderContextTests

- (NSURL *)randomURL
{
  // random URL for each test, doesn't matter that this is not really a URL
  return [NSURL URLWithString:[NSUUID UUID].UUIDString];
}

- (void)testContextCreation
{
  NSURL *url = [self randomURL];
  A_SBasicImageDownloaderContext *c1 = [A_SBasicImageDownloaderContext contextForURL:url];
  A_SBasicImageDownloaderContext *c2 = [A_SBasicImageDownloaderContext contextForURL:url];
  XCTAssert(c1 == c2, @"Context objects are not the same");
}

- (void)testContextInvalidation
{
  NSURL *url = [self randomURL];
  A_SBasicImageDownloaderContext *context = [A_SBasicImageDownloaderContext contextForURL:url];
  [context cancel];
  XCTAssert([context isCancelled], @"Context should be cancelled");
}

/* This test is currently unreliable.  See https://github.com/facebook/Async_DisplayKit/issues/459
- (void)testAsyncContextInvalidation
{
  NSURL *url = [self randomURL];
  A_SBasicImageDownloaderContext *context = [A_SBasicImageDownloaderContext contextForURL:url];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Context invalidation"];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [expectation fulfill];
    XCTAssert([context isCancelled], @"Context should be cancelled");
  });

  [context cancel];
  [self waitForExpectationsWithTimeout:30.0 handler:nil];
}
*/

- (void)testContextSessionCanceled
{
  NSURL *url = [self randomURL];
  id task = [OCMockObject mockForClass:[NSURLSessionTask class]];
  A_SBasicImageDownloaderContext *context = [A_SBasicImageDownloaderContext contextForURL:url];
  context.sessionTask = task;

  [[task expect] cancel];

  [context cancel];
}

@end