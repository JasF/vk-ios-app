//
//  A_SDisplayNode+FrameworkSubclasses.h
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

//
// The following methods are ONLY for use by _A_SDisplayLayer, _A_SDisplayView, and A_SDisplayNode.
// These methods must never be called or overridden by other classes.
//

#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SThread.h>

// These are included because most internal subclasses need it.
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>

NS_ASSUME_NONNULL_BEGIN

@interface A_SDisplayNode ()
{
  // Protects access to _view, _layer, _pendingViewState, _subnodes, _supernode, and other properties which are accessed from multiple threads.
  @package
  A_SDN::RecursiveMutex __instanceLock__;
}
@end

NS_ASSUME_NONNULL_END
