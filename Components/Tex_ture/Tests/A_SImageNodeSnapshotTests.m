//
//  A_SImageNodeSnapshotTests.m
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

#import "A_SSnapshotTestCase.h"

#import <Async_DisplayKit/Async_DisplayKit.h>

@interface A_SImageNodeSnapshotTests : A_SSnapshotTestCase
@end

@implementation A_SImageNodeSnapshotTests

- (void)setUp
{
  [super setUp];
  
  self.recordMode = NO;
}

- (UIImage *)testImage
{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo-square"
                                                                    ofType:@"png"
                                                               inDirectory:@"TestResources"];
  return [UIImage imageWithContentsOfFile:path];
}

- (void)testRenderLogoSquare
{
  // trivial test case to ensure A_SSnapshotTestCase works
  A_SImageNode *imageNode = [[A_SImageNode alloc] init];
  imageNode.image = [self testImage];
  A_SDisplayNodeSizeToFitSize(imageNode, CGSizeMake(100, 100));

  A_SSnapshotVerifyNode(imageNode, nil);
}

- (void)testForcedScaling
{
  CGSize forcedImageSize = CGSizeMake(100, 100);
  
  A_SImageNode *imageNode = [[A_SImageNode alloc] init];
  imageNode.forcedSize = forcedImageSize;
  imageNode.image = [self testImage];
  
  // Snapshot testing requires that node is formally laid out.
  imageNode.style.width = A_SDimensionMake(forcedImageSize.width);
  imageNode.style.height = A_SDimensionMake(forcedImageSize.height);
  A_SDisplayNodeSizeToFitSize(imageNode, forcedImageSize);
  A_SSnapshotVerifyNode(imageNode, @"first");
  
  imageNode.style.width = A_SDimensionMake(200);
  imageNode.style.height = A_SDimensionMake(200);
  A_SDisplayNodeSizeToFitSize(imageNode, CGSizeMake(200, 200));
  A_SSnapshotVerifyNode(imageNode, @"second");
  
  XCTAssert(CGImageGetWidth((CGImageRef)imageNode.contents) == forcedImageSize.width * imageNode.contentsScale &&
            CGImageGetHeight((CGImageRef)imageNode.contents) == forcedImageSize.height * imageNode.contentsScale,
            @"Contents should be 100 x 100 by contents scale.");
}

- (void)testTintColorBlock
{
  UIImage *test = [self testImage];
  UIImage *tinted = A_SImageNodeTintColorModificationBlock([UIColor redColor])(test);
  A_SImageNode *node = [[A_SImageNode alloc] init];
  node.image = tinted;
  A_SDisplayNodeSizeToFitSize(node, test.size);
  
  A_SSnapshotVerifyNode(node, nil);
}

- (void)testRoundedCornerBlock
{
  UIGraphicsBeginImageContext(CGSizeMake(100, 100));
  [[UIColor blueColor] setFill];
  UIRectFill(CGRectMake(0, 0, 100, 100));
  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  UIImage *rounded = A_SImageNodeRoundBorderModificationBlock(2, [UIColor redColor])(result);
  A_SImageNode *node = [[A_SImageNode alloc] init];
  node.image = rounded;
  A_SDisplayNodeSizeToFitSize(node, rounded.size);
  
  A_SSnapshotVerifyNode(node, nil);
}

@end
