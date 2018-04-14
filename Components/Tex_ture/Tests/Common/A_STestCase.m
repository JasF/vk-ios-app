//
//  A_STestCase.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "A_STestCase.h"
#import <objc/runtime.h>
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <OCMock/OCMock.h>
#import "OCMockObject+A_SAdditions.h"

static __weak A_STestCase *currentTestCase;

@implementation A_STestCase {
  A_SWeakSet *registeredMockObjects;
}

- (void)setUp
{
  [super setUp];
  currentTestCase = self;
  registeredMockObjects = [A_SWeakSet new];
}

- (void)tearDown
{
  // Clear out all application windows. Note: the system will retain these sometimes on its
  // own but we'll do our best.
  for (UIWindow *window in [UIApplication sharedApplication].windows) {
    [window resignKeyWindow];
    window.hidden = YES;
    window.rootViewController = nil;
    for (UIView *view in window.subviews) {
      [view removeFromSuperview];
    }
  }
  
  // Set nil for all our subclasses' ivars. Use setValue:forKey: so memory is managed correctly.
  // This is important to do _inside_ the test-perform, so that we catch any issues caused by the
  // deallocation, and so that we're inside the @autoreleasepool for the test invocation.
  Class c = [self class];
  while (c != [A_STestCase class]) {
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList(c, &ivarCount);
    for (unsigned int i = 0; i < ivarCount; i++) {
      Ivar ivar = ivars[i];
      NSString *key = [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
      if (OCMIsObjectType(ivar_getTypeEncoding(ivar))) {
      	[self setValue:nil forKey:key];
      }
    }
    if (ivars) {
      free(ivars);
    }

    c = [c superclass];
  }

  for (OCMockObject *mockObject in registeredMockObjects) {
    OCMVerifyAll(mockObject);
    [mockObject stopMocking];

    // Invocations retain arguments, which may cause retain cycles.
    // Manually clear them all out.
    NSMutableArray *invocations = object_getIvar(mockObject, class_getInstanceVariable(OCMockObject.class, "invocations"));
    [invocations removeAllObjects];
  }

  // Go ahead and spin the run loop before finishing, so the system
  // unregisters/cleans up whatever possible.
  [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:NSDate.distantPast];
  
  [super tearDown];
}

- (void)invokeTest
{
  // This will call setup, run, then teardown.
  @autoreleasepool {
    [super invokeTest];
  }

  // Now that the autorelease pool is drained, drain the dealloc queue also.
  [[A_SDeallocQueue sharedDeallocationQueue] test_drain];
}

+ (A_STestCase *)currentTestCase
{
  return currentTestCase;
}

@end

@implementation A_STestCase (OCMockObjectRegistering)

- (void)registerMockObject:(id)mockObject
{
  @synchronized (registeredMockObjects) {
    [registeredMockObjects addObject:mockObject];
  }
}

@end
