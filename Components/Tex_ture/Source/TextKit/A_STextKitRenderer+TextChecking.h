//
//  A_STextKitRenderer+TextChecking.h
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

#import <Async_DisplayKit/A_STextKitRenderer.h>

/**
 Application extensions to NSTextCheckingType. We're allowed to do this (see NSTextCheckingAllCustomTypes).
 */
static uint64_t const A_STextKitTextCheckingTypeEntity =               1ULL << 33;
static uint64_t const A_STextKitTextCheckingTypeTruncation =           1ULL << 34;

@class A_STextKitEntityAttribute;

@interface A_STextKitTextCheckingResult : NSTextCheckingResult
@property (nonatomic, strong, readonly) A_STextKitEntityAttribute *entityAttribute;
@end

@interface A_STextKitRenderer (TextChecking)

- (NSTextCheckingResult *)textCheckingResultAtPoint:(CGPoint)point;

@end
