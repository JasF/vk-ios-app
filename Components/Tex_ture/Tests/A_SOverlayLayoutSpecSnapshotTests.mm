//
//  A_SOverlayLayoutSpecSnapshotTests.mm
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

#import <Async_DisplayKit/A_SOverlayLayoutSpec.h>
#import <Async_DisplayKit/A_SCenterLayoutSpec.h>

static const A_SSizeRange kSize = {{320, 320}, {320, 320}};

@interface A_SOverlayLayoutSpecSnapshotTests : A_SLayoutSpecSnapshotTestCase
@end

@implementation A_SOverlayLayoutSpecSnapshotTests

- (void)testOverlay
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor blueColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor blackColor], {20, 20});
  
  A_SLayoutSpec *layoutSpec =
  [A_SOverlayLayoutSpec
   overlayLayoutSpecWithChild:backgroundNode
   overlay:
   [A_SCenterLayoutSpec
    centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY
    sizingOptions:{}
    child:foregroundNode]];
  
  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:@[backgroundNode, foregroundNode] identifier: nil];
}

@end
