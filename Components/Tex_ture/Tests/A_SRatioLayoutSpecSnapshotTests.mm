//
//  A_SRatioLayoutSpecSnapshotTests.mm
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

#import <Async_DisplayKit/A_SRatioLayoutSpec.h>

static const A_SSizeRange kFixedSize = {{0, 0}, {100, 100}};

@interface A_SRatioLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SRatioLayoutSpecSnapshotTests

- (void)testRatioLayoutSpecWithRatio:(CGFloat)ratio childSize:(CGSize)childSize identifier:(NSString *)identifier
{
  A_SDisplayNode *subnode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], childSize);
  
  A_SLayoutSpec *layoutSpec = [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:ratio child:subnode];
  
  [self testLayoutSpec:layoutSpec sizeRange:kFixedSize subnodes:@[subnode] identifier:identifier];
}

- (void)testRatioLayout
{
  [self testRatioLayoutSpecWithRatio:0.5 childSize:CGSizeMake(100, 100) identifier:@"HalfRatio"];
  [self testRatioLayoutSpecWithRatio:2.0 childSize:CGSizeMake(100, 100) identifier:@"DoubleRatio"];
  [self testRatioLayoutSpecWithRatio:7.0 childSize:CGSizeMake(100, 100) identifier:@"SevenTimesRatio"];
  [self testRatioLayoutSpecWithRatio:10.0 childSize:CGSizeMake(20, 200) identifier:@"TenTimesRatioWithItemTooBig"];
}

@end
