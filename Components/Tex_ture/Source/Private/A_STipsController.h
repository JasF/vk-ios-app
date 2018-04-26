//
//  A_STipsController.h
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

#if A_S_ENABLE_TIPS

@class A_SDisplayNode;

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED
@interface A_STipsController : NSObject

/**
 * The shared tip controller instance.
 */
@property (class, strong, readonly) A_STipsController *shared;

#pragma mark - Node Event Hooks

/**
 * Informs the controller that the sender did enter the visible range.
 *
 * The controller will run a pass with its tip providers, adding tips as needed.
 */
- (void)nodeDidAppear:(A_SDisplayNode *)node;

@end

NS_ASSUME_NONNULL_END

#endif // A_S_ENABLE_TIPS
