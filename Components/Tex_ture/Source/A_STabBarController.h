//
//  A_STabBarController.h
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

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SVisibilityProtocols.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A_STabBarController
 *
 * @discussion A_STabBarController is a drop in replacement for UITabBarController
 * which implements the memory efficiency improving @c A_SManagesChildVisibilityDepth protocol.
 *
 * @see A_SManagesChildVisibilityDepth
 */
@interface A_STabBarController : UITabBarController <A_SManagesChildVisibilityDepth>

@end

NS_ASSUME_NONNULL_END
