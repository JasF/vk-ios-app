//
//  A_SAssert.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SAssert.h>
#import <Foundation/Foundation.h>

static pthread_key_t A_SMainThreadAssertionsDisabledKey()
{
  return A_SPthreadStaticKey(NULL);
}

BOOL A_SMainThreadAssertionsAreDisabled() {
  return (size_t)pthread_getspecific(A_SMainThreadAssertionsDisabledKey()) > 0;
}

void A_SPushMainThreadAssertionsDisabled() {
  pthread_key_t key = A_SMainThreadAssertionsDisabledKey();
  size_t oldValue = (size_t)pthread_getspecific(key);
  pthread_setspecific(key, (void *)(oldValue + 1));
}

void A_SPopMainThreadAssertionsDisabled() {
  pthread_key_t key = A_SMainThreadAssertionsDisabledKey();
  size_t oldValue = (size_t)pthread_getspecific(key);
  if (oldValue > 0) {
    pthread_setspecific(key, (void *)(oldValue - 1));
  } else {
    A_SDisplayNodeCFailAssert(@"Attempt to pop thread assertion-disabling without corresponding push.");
  }
}
