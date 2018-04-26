//
//  A_SResponderChainEnumerator.m
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

#import "A_SResponderChainEnumerator.h"
#import <Async_DisplayKit/A_SAssert.h>

@implementation A_SResponderChainEnumerator {
  UIResponder *_currentResponder;
}

- (instancetype)initWithResponder:(UIResponder *)responder
{
  A_SDisplayNodeAssertMainThread();
  if (self = [super init]) {
    _currentResponder = responder;
  }
  return self;
}

#pragma mark - NSEnumerator

- (id)nextObject
{
  A_SDisplayNodeAssertMainThread();
  id result = [_currentResponder nextResponder];
  _currentResponder = result;
  return result;
}

@end

@implementation UIResponder (A_SResponderChainEnumerator)

- (NSEnumerator *)asdk_responderChainEnumerator
{
  return [[A_SResponderChainEnumerator alloc] initWithResponder:self];
}

@end
