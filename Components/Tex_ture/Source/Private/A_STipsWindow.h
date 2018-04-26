//
//  A_STipsWindow.h
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

#import <Async_DisplayKit/A_SViewController.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#if A_S_ENABLE_TIPS

@class A_SDisplayNode, A_SDisplayNodeTipState;

NS_ASSUME_NONNULL_BEGIN

/**
 * A window that shows tips. This was originally meant to be a view controller
 * but UIKit will not manage view controllers in non-key windows correctly AT ALL
 * as of the time of this writing.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_STipsWindow : UIWindow

/// The main application window that the tips are tracking.
@property (nonatomic, weak) UIWindow *mainWindow;

@property (nonatomic, copy, nullable) NSMapTable<A_SDisplayNode *, A_SDisplayNodeTipState *> *nodeToTipStates;

@end

NS_ASSUME_NONNULL_END

#endif
