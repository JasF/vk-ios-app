//
//  A_SBatchContext.mm
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

#import <Async_DisplayKit/A_SBatchContext.h>

#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SThread.h>

typedef NS_ENUM(NSInteger, A_SBatchContextState) {
  A_SBatchContextStateFetching,
  A_SBatchContextStateCancelled,
  A_SBatchContextStateCompleted
};

@interface A_SBatchContext ()
{
  A_SBatchContextState _state;
  A_SDN::RecursiveMutex __instanceLock__;
}
@end

@implementation A_SBatchContext

- (instancetype)init
{
  if (self = [super init]) {
    _state = A_SBatchContextStateCompleted;
  }
  return self;
}

- (BOOL)isFetching
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _state == A_SBatchContextStateFetching;
}

- (BOOL)batchFetchingWasCancelled
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _state == A_SBatchContextStateCancelled;
}

- (void)beginBatchFetching
{
  A_SDN::MutexLocker l(__instanceLock__);
  _state = A_SBatchContextStateFetching;
}

- (void)completeBatchFetching:(BOOL)didComplete
{
  if (didComplete) {
    as_log_debug(A_SCollectionLog(), "Completed batch fetch with context %@", self);
    A_SDN::MutexLocker l(__instanceLock__);
    _state = A_SBatchContextStateCompleted;
  }
}

- (void)cancelBatchFetching
{
  A_SDN::MutexLocker l(__instanceLock__);
  _state = A_SBatchContextStateCancelled;
}

@end
