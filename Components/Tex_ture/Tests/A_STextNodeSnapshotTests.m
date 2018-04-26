//
//  A_STextNodeSnapshotTests.m
//  Tex_ture
//
//  Created by Garrett Moon on 8/12/16.
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

@interface A_STextNodeSnapshotTests : A_SSnapshotTestCase

@end

@implementation A_STextNodeSnapshotTests

- (void)setUp
{
  [super setUp];
  
  self.recordMode = NO;
}

- (void)testTextContainerInset
{
  // trivial test case to ensure A_SSnapshotTestCase works
  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"judar"
                                                            attributes:@{NSFontAttributeName : [UIFont italicSystemFontOfSize:24]}];
  textNode.textContainerInset = UIEdgeInsetsMake(0, 2, 0, 2);
  A_SDisplayNodeSizeToFitSizeRange(textNode, A_SSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)));
  
  A_SSnapshotVerifyNode(textNode, nil);
}

- (void)testTextContainerInsetIsIncludedWithSmallerConstrainedSize
{
  UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
  backgroundView.layer.as_allowsHighlightDrawing = YES;

  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"judar judar judar judar judar judar"
                                                            attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:30] }];
  
  textNode.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
  
  A_SLayout *layout = [textNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 80))];
  textNode.frame = CGRectMake(50, 50, layout.size.width, layout.size.height);

  [backgroundView addSubview:textNode.view];
  backgroundView.frame = UIEdgeInsetsInsetRect(textNode.bounds, UIEdgeInsetsMake(-50, -50, -50, -50));
  
  textNode.highlightRange = NSMakeRange(0, textNode.attributedText.length);

  [A_SSnapshotTestCase hackilySynchronouslyRecursivelyRenderNode:textNode];
  A_SSnapshotVerifyLayer(backgroundView.layer, nil);
}

- (void)testTextContainerInsetHighlight
{
  UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
  backgroundView.layer.as_allowsHighlightDrawing = YES;

  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"yolo"
                                                            attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:30] }];

  textNode.textContainerInset = UIEdgeInsetsMake(5, 10, 10, 5);
  A_SLayout *layout = [textNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY))];
  textNode.frame = CGRectMake(50, 50, layout.size.width, layout.size.height);

  [backgroundView addSubview:textNode.view];
  backgroundView.frame = UIEdgeInsetsInsetRect(textNode.bounds, UIEdgeInsetsMake(-50, -50, -50, -50));

  textNode.highlightRange = NSMakeRange(0, textNode.attributedText.length);

  [A_SSnapshotTestCase hackilySynchronouslyRecursivelyRenderNode:textNode];
  A_SSnapshotVerifyView(backgroundView, nil);
}

// This test is disabled because the fast-path is disabled.
- (void)DISABLED_testThatFastPathTruncationWorks
{
  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Quality is Important" attributes:@{ NSForegroundColorAttributeName: [UIColor blueColor], NSFontAttributeName: [UIFont italicSystemFontOfSize:24] }];
  [textNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 50))];
  A_SSnapshotVerifyNode(textNode, nil);
}

- (void)testThatSlowPathTruncationWorks
{
  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Quality is Important" attributes:@{ NSForegroundColorAttributeName: [UIColor blueColor], NSFontAttributeName: [UIFont italicSystemFontOfSize:24] }];
  // Set exclusion paths to trigger slow path
  textNode.exclusionPaths = @[ [UIBezierPath bezierPath] ];
  A_SDisplayNodeSizeToFitSizeRange(textNode, A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 50)));
  A_SSnapshotVerifyNode(textNode, nil);
}

- (void)testShadowing
{
  A_STextNode *textNode = [[A_STextNode alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Quality is Important"];
  textNode.shadowColor = [UIColor blackColor].CGColor;
  textNode.shadowOpacity = 0.3;
  textNode.shadowRadius = 3;
  textNode.shadowOffset = CGSizeMake(0, 1);
  A_SDisplayNodeSizeToFitSizeRange(textNode, A_SSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
  A_SSnapshotVerifyNode(textNode, nil);
}

@end
