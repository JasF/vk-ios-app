//
//  NSInvocation+A_STestHelpers.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "NSInvocation+A_STestHelpers.h"

@implementation NSInvocation (A_STestHelpers)

- (id)as_argumentAtIndexAsObject:(NSInteger)index
{
  void *buf;
  [self getArgument:&buf atIndex:index];
  return (__bridge id)buf;
}

- (void)as_setReturnValueWithObject:(id)object
{
  if (object == nil) {
    const void *fixedBuf = NULL;
    [self setReturnValue:&fixedBuf];
  } else {
    // Retain, then autorelease.
    const void *fixedBuf = CFAutorelease((__bridge_retained void *)object);
    [self setReturnValue:&fixedBuf];
  }
}

@end
