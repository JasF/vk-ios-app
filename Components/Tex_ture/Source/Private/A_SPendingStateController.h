//
//  A_SPendingStateController.h
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

#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

@class A_SDisplayNode;

NS_ASSUME_NONNULL_BEGIN

/**
 A singleton that is responsible for applying changes to
 UIView/CALayer properties of display nodes when they
 have been set on background threads.
 
 This controller will enqueue run-loop events to flush changes
 but if you need them flushed now you can call `flush` from the main thread.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SPendingStateController : NSObject

+ (A_SPendingStateController *)sharedInstance;

@property (nonatomic, readonly) BOOL hasChanges;

/**
 Flush all pending states for nodes now. Any UIView/CALayer properties
 that have been set in the background will be applied to their
 corresponding views/layers before this method returns.
 
 You must call this method on the main thread.
 */
- (void)flush;

/**
 Register this node as having pending state that needs to be copied
 over to the view/layer. This is called automatically by display nodes
 when their view/layer properties are set post-load on background threads.
 */
- (void)registerNode:(A_SDisplayNode *)node;

@end

NS_ASSUME_NONNULL_END
