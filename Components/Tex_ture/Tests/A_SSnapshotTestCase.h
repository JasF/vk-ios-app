//
//  A_SSnapshotTestCase.h
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

#import <FBSnapshotTestCase/FBSnapshotTestCase.h>
#import "A_SDisplayNodeTestsHelper.h"

@class A_SDisplayNode;

NSOrderedSet *A_SSnapshotTestCaseDefaultSuffixes(void);

#define A_SSnapshotVerifyNode(node__, identifier__) \
{ \
  [A_SSnapshotTestCase hackilySynchronouslyRecursivelyRenderNode:node__]; \
  FBSnapshotVerifyLayerWithOptions(node__.layer, identifier__, A_SSnapshotTestCaseDefaultSuffixes(), 0) \
}

#define A_SSnapshotVerifyLayer(layer__, identifier__) \
  FBSnapshotVerifyLayerWithOptions(layer__, identifier__, A_SSnapshotTestCaseDefaultSuffixes(), 0);

#define A_SSnapshotVerifyView(view__, identifier__) \
	FBSnapshotVerifyViewWithOptions(view__, identifier__, A_SSnapshotTestCaseDefaultSuffixes(), 0);

@interface A_SSnapshotTestCase : FBSnapshotTestCase

/**
 * Hack for testing.  A_SDisplayNode lacks an explicit -render method, so we manually hit its layout & display codepaths.
 */
+ (void)hackilySynchronouslyRecursivelyRenderNode:(A_SDisplayNode *)node;

@end
