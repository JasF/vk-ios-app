//
//  A_STipProvider.m
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

#import "A_STipProvider.h"

#if A_S_ENABLE_TIPS

#import <Async_DisplayKit/A_SAssert.h>

// Concrete classes
#import <Async_DisplayKit/A_SLayerBackingTipProvider.h>

@implementation A_STipProvider

- (A_STip *)tipForNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeFailAssert(@"Subclasses must override %@", NSStringFromSelector(_cmd));
  return nil;
}

@end

@implementation A_STipProvider (Lookup)

+ (NSArray<A_STipProvider *> *)all
{
  static NSArray<A_STipProvider *> *providers;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    providers = @[ [A_SLayerBackingTipProvider new] ];
  });
  return providers;
}

@end

#endif // A_S_ENABLE_TIPS