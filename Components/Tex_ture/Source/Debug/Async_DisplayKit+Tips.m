//
//  Async_DisplayKit+Tips.m
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

#import "Async_DisplayKit+Tips.h"
#import <Async_DisplayKit/A_SDisplayNode+Ancestry.h>

@implementation A_SDisplayNode (Tips)

static char A_SDisplayNodeEnableTipsKey;
static A_STipDisplayBlock _Nullable __tipDisplayBlock;

/**
 * Use associated objects with NSNumbers. This is a debug property - simplicity is king.
 */
+ (void)setEnableTips:(BOOL)enableTips
{
  objc_setAssociatedObject(self, &A_SDisplayNodeEnableTipsKey, @(enableTips), OBJC_ASSOCIATION_COPY);
}

+ (BOOL)enableTips
{
  NSNumber *result = objc_getAssociatedObject(self, &A_SDisplayNodeEnableTipsKey);
  if (result == nil) {
    return YES;
  }
  return result.boolValue;
}


+ (void)setTipDisplayBlock:(A_STipDisplayBlock)tipDisplayBlock
{
  __tipDisplayBlock = tipDisplayBlock;
}

+ (A_STipDisplayBlock)tipDisplayBlock
{
  return __tipDisplayBlock ?: ^(A_SDisplayNode *node, NSString *string) {
    NSLog(@"%@. Node ancestry: %@", string, node.ancestryDescription);
  };
}

@end
