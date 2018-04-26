//
//  A_SSnapshotTestCase.m
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
#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>

NSOrderedSet *A_SSnapshotTestCaseDefaultSuffixes(void)
{
  NSMutableOrderedSet *suffixesSet = [[NSMutableOrderedSet alloc] init];
  // In some rare cases, slightly different rendering may occur on iOS 10 (text rasterization).
  // If the test folders find any image that exactly matches, they pass;
  // if an image is not present at all, or it fails, it moves on to check the others.
  // This means the order doesn't matter besides reducing logging / performance.
  if (A_S_AT_LEA_ST_IOS10) {
    [suffixesSet addObject:@"_iOS_10"];
  }
  [suffixesSet addObject:@"_64"];
  return [suffixesSet copy];
}

@implementation A_SSnapshotTestCase

+ (void)hackilySynchronouslyRecursivelyRenderNode:(A_SDisplayNode *)node
{
  A_SDisplayNodePerformBlockOnEveryNode(nil, node, YES, ^(A_SDisplayNode * _Nonnull node) {
    [node.layer setNeedsDisplay];
  });
  [node recursivelyEnsureDisplaySynchronously:YES];
}

@end
