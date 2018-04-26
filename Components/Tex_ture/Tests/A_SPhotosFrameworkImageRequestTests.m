//
//  A_SPhotosFrameworkImageRequestTests.m
//  Tex_ture
//
//  Created by Adlai Holler on 9/25/15.
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
#import <Async_DisplayKit/A_SPhotosFrameworkImageRequest.h>

static NSString *const kTestAssetID = @"testAssetID";

@interface A_SPhotosFrameworkImageRequestTests : XCTestCase

@end

@implementation A_SPhotosFrameworkImageRequestTests

#pragma mark Example Data

+ (A_SPhotosFrameworkImageRequest *)exampleImageRequest
{
  A_SPhotosFrameworkImageRequest *req = [[A_SPhotosFrameworkImageRequest alloc] initWithAssetIdentifier:kTestAssetID];
  req.options.networkAccessAllowed = YES;
  req.options.normalizedCropRect = CGRectMake(0.2, 0.1, 0.6, 0.8);
  req.targetSize = CGSizeMake(1024, 1536);
  req.contentMode = PHImageContentModeAspectFill;
  req.options.version = PHImageRequestOptionsVersionOriginal;
  req.options.resizeMode = PHImageRequestOptionsResizeModeFast;
  return req;
}

+ (NSURL *)urlForExampleImageRequest
{
  NSString *str = [NSString stringWithFormat:@"ph://%@?width=1024&height=1536&version=2&contentmode=1&network=1&resizemode=1&deliverymode=0&crop_x=0.2&crop_y=0.1&crop_w=0.6&crop_h=0.8", kTestAssetID];
  return [NSURL URLWithString:str];
}

#pragma mark Test cases

- (void)testThatConvertingToURLWorks
{
  XCTAssertEqualObjects([self.class exampleImageRequest].url, [self.class urlForExampleImageRequest]);
}

- (void)testThatParsingFromURLWorks
{
  NSURL *url = [self.class urlForExampleImageRequest];
  XCTAssertEqualObjects([A_SPhotosFrameworkImageRequest requestWithURL:url], [self.class exampleImageRequest]);
}

- (void)testThatCopyingWorks
{
  A_SPhotosFrameworkImageRequest *example = [self.class exampleImageRequest];
  A_SPhotosFrameworkImageRequest *copy = [[self.class exampleImageRequest] copy];
  XCTAssertEqualObjects(example, copy);
}

@end
