//
//  A_SLayoutElementStylePrivate.h
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

#pragma once

#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

@interface A_SLayoutElementStyle () <A_SDescriptionProvider>

/**
 * @abstract The object that acts as the delegate of the style.
 *
 * @discussion The delegate must adopt the A_SLayoutElementStyleDelegate protocol. The delegate is not retained.
 */
@property (nullable, nonatomic, weak) id<A_SLayoutElementStyleDelegate> delegate;

/**
 * @abstract A size constraint that should apply to this A_SLayoutElement.
 */
@property (nonatomic, assign, readonly) A_SLayoutElementSize size;

@end
