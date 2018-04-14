//
//  A_SLayoutSpecSnapshotTestsHelper.m
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

#import "A_SLayoutSpecSnapshotTestsHelper.h"

#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>

@interface A_STestNode : A_SDisplayNode
@property (strong, nonatomic, nullable) A_SLayoutSpec *layoutSpecUnderTest;
@end

@implementation A_SLayoutSpecSnapshotTestCase

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testLayoutSpec:(A_SLayoutSpec *)layoutSpec
             sizeRange:(A_SSizeRange)sizeRange
              subnodes:(NSArray *)subnodes
            identifier:(NSString *)identifier
{
  A_STestNode *node = [[A_STestNode alloc] init];

  for (A_SDisplayNode *subnode in subnodes) {
    [node addSubnode:subnode];
  }
  
  node.layoutSpecUnderTest = layoutSpec;
  
  A_SDisplayNodeSizeToFitSizeRange(node, sizeRange);
  A_SSnapshotVerifyNode(node, identifier);
}

@end

@implementation A_STestNode
- (instancetype)init
{
  if (self = [super init]) {
    self.layerBacked = YES;
  }
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return _layoutSpecUnderTest;
}

@end
