//
//  A_SScrollDirection.h
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
#import <CoreGraphics/CGAffineTransform.h>

#import <Async_DisplayKit/A_SBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSInteger, A_SScrollDirection) {
  A_SScrollDirectionNone  = 0,
  A_SScrollDirectionRight = 1 << 0,
  A_SScrollDirectionLeft  = 1 << 1,
  A_SScrollDirectionUp    = 1 << 2,
  A_SScrollDirectionDown  = 1 << 3
};

extern const A_SScrollDirection A_SScrollDirectionHorizontalDirections;
extern const A_SScrollDirection A_SScrollDirectionVerticalDirections;

A_SDISPLAYNODE_EXTERN_C_BEGIN

BOOL A_SScrollDirectionContainsVerticalDirection(A_SScrollDirection scrollDirection);
BOOL A_SScrollDirectionContainsHorizontalDirection(A_SScrollDirection scrollDirection);

BOOL A_SScrollDirectionContainsRight(A_SScrollDirection scrollDirection);
BOOL A_SScrollDirectionContainsLeft(A_SScrollDirection scrollDirection);
BOOL A_SScrollDirectionContainsUp(A_SScrollDirection scrollDirection);
BOOL A_SScrollDirectionContainsDown(A_SScrollDirection scrollDirection);
A_SScrollDirection A_SScrollDirectionApplyTransform(A_SScrollDirection scrollDirection, CGAffineTransform transform);

A_SDISPLAYNODE_EXTERN_C_END

NS_ASSUME_NONNULL_END
