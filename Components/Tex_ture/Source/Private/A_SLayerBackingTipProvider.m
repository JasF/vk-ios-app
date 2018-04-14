//
//  A_SLayerBackingTipProvider.m
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

#import "A_SLayerBackingTipProvider.h"

#if A_S_ENABLE_TIPS

#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SControlNode.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_STip.h>

@implementation A_SLayerBackingTipProvider

- (A_STip *)tipForNode:(A_SDisplayNode *)node
{
  // Already layer-backed.
  if (node.layerBacked) {
    return nil;
  }

  // TODO: Avoid revisiting nodes we already visited
  A_SDisplayNode *failNode = A_SDisplayNodeFindFirstNode(node, ^BOOL(A_SDisplayNode * _Nonnull node) {
    return !node.supportsLayerBacking;
  });
  if (failNode != nil) {
    return nil;
  }

  A_STip *result = [[A_STip alloc] initWithNode:node
                                         kind:A_STipKindEnableLayerBacking
                                       format:@"Enable layer backing to improve performance"];
  return result;
}

@end

#endif // A_S_ENABLE_TIPS
