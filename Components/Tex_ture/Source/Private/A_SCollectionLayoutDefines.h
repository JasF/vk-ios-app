//
//  A_SCollectionLayoutDefines.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SScrollDirection.h>

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

FOUNDATION_EXPORT A_SSizeRange A_SSizeRangeForCollectionLayoutThatFitsViewportSize(CGSize viewportSize, A_SScrollDirection scrollableDirections) A_S_WARN_UNUSED_RESULT;

A_SDISPLAYNODE_EXTERN_C_END

NS_ASSUME_NONNULL_END
