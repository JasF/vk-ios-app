//
//  A_SEventLog.mm
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

#import <Async_DisplayKit/A_SEventLog.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_STraceEvent.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

@implementation A_SEventLog {
  A_SDN::RecursiveMutex __instanceLock__;

  // The index of the most recent log entry. -1 until first entry.
  NSInteger _eventLogHead;

  // A description of the object we're logging for. This is immutable.
  NSString *_objectDescription;
}

/**
 * Even just when debugging, all these events can take up considerable memory.
 * Store them in a shared NSCache to limit the total consumption.
 */
+ (NSCache<A_SEventLog *, NSMutableArray<A_STraceEvent *> *> *)contentsCache
{
  static NSCache *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  return cache;
}

- (instancetype)initWithObject:(id)anObject
{
  if ((self = [super init])) {
    _objectDescription = A_SObjectDescriptionMakeTiny(anObject);
    _eventLogHead = -1;
  }
  return self;
}

- (instancetype)init
{
  // This method is marked unavailable so the compiler won't let them call it.
  A_SDisplayNodeFailAssert(@"Failed to call initWithObject:");
  return nil;
}

- (void)logEventWithBacktrace:(NSArray<NSString *> *)backtrace format:(NSString *)format, ...
{
  va_list args;
  va_start(args, format);
  A_STraceEvent *event = [[A_STraceEvent alloc] initWithBacktrace:backtrace
                                                         format:format
                                                      arguments:args];
  va_end(args);

  A_SDN::MutexLocker l(__instanceLock__);
  NSCache *cache = [A_SEventLog contentsCache];
  NSMutableArray<A_STraceEvent *> *events = [cache objectForKey:self];
  if (events == nil) {
    events = [NSMutableArray arrayWithObject:event];
    [cache setObject:events forKey:self];
    _eventLogHead = 0;
    return;
  }

  // Increment the head index.
  _eventLogHead = (_eventLogHead + 1) % A_SEVENTLOG_CAPACITY;
  if (_eventLogHead < events.count) {
    [events replaceObjectAtIndex:_eventLogHead withObject:event];
  } else {
    [events insertObject:event atIndex:_eventLogHead];
  }
}

- (NSArray<A_STraceEvent *> *)events
{
  NSMutableArray<A_STraceEvent *> *events = [[A_SEventLog contentsCache] objectForKey:self];
  if (events == nil) {
    return nil;
  }

  A_SDN::MutexLocker l(__instanceLock__);
  NSUInteger tail = (_eventLogHead + 1);
  NSUInteger count = events.count;
  
  NSMutableArray<A_STraceEvent *> *result = [NSMutableArray array];
  
  // Start from `tail` and go through array, wrapping around when we exceed end index.
  for (NSUInteger actualIndex = 0; actualIndex < A_SEVENTLOG_CAPACITY; actualIndex++) {
    NSInteger ringIndex = (tail + actualIndex) % A_SEVENTLOG_CAPACITY;
    if (ringIndex < count) {
      [result addObject:events[ringIndex]];
    }
  }
  return result;
}

- (NSString *)description
{
  /**
   * This description intentionally doesn't follow the standard description format.
   * Since this is a log, it's important for the description to look a certain way, and
   * the formal description style doesn't allow for newlines and has a ton of punctuation.
   */
  NSArray *events = [self events];
  if (events == nil) {
    return [NSString stringWithFormat:@"Event log for %@ was purged to conserve memory.", _objectDescription];
  } else {
    return [NSString stringWithFormat:@"Event log for %@. Events: %@", _objectDescription, events];
  }
}

@end
