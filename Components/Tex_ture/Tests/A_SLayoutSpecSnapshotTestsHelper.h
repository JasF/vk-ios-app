//
//  A_SLayoutSpecSnapshotTestsHelper.h
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
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>

@class A_SLayoutSpec;

@interface A_SLayoutSpecSnapshotTestCase: A_SSnapshotTestCase
/**
 Test the layout spec or records a snapshot if recordMode is YES.
 @param layoutSpec The layout spec under test or to snapshot
 @param sizeRange The size range used to calculate layout of the given layout spec.
 @param subnodes An array of A_SDisplayNodes used within the layout spec.
 @param identifier An optional identifier, used to identify this snapshot test.
 
 @discussion In order to make the layout spec visible, it is embeded to a A_SDisplayNode host.
 Any subnodes used within the layout spec must be provided.
 They will be added to the host in the same order as the array.
 */
- (void)testLayoutSpec:(A_SLayoutSpec *)layoutSpec
             sizeRange:(A_SSizeRange)sizeRange
              subnodes:(NSArray *)subnodes
            identifier:(NSString *)identifier;
@end

__attribute__((overloadable)) static inline A_SDisplayNode *A_SDisplayNodeWithBackgroundColor(UIColor *backgroundColor, CGSize size) {
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layerBacked = YES;
  node.backgroundColor = backgroundColor;
  node.style.width = A_SDimensionMakeWithPoints(size.width);
  node.style.height = A_SDimensionMakeWithPoints(size.height);
  return node;
}

__attribute__((overloadable)) static inline A_SDisplayNode *A_SDisplayNodeWithBackgroundColor(UIColor *backgroundColor)
{
  return A_SDisplayNodeWithBackgroundColor(backgroundColor, CGSizeZero);
}
