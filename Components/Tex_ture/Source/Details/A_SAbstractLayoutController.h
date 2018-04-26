//
//  A_SAbstractLayoutController.h
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

#import <Async_DisplayKit/A_SLayoutController.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

FOUNDATION_EXPORT A_SDirectionalScreenfulBuffer A_SDirectionalScreenfulBufferHorizontal(A_SScrollDirection scrollDirection, A_SRangeTuningParameters rangeTuningParameters);

FOUNDATION_EXPORT A_SDirectionalScreenfulBuffer A_SDirectionalScreenfulBufferVertical(A_SScrollDirection scrollDirection, A_SRangeTuningParameters rangeTuningParameters);

FOUNDATION_EXPORT CGRect CGRectExpandToRangeWithScrollableDirections(CGRect rect, A_SRangeTuningParameters tuningParameters, A_SScrollDirection scrollableDirections, A_SScrollDirection scrollDirection);

A_SDISPLAYNODE_EXTERN_C_END

@interface A_SAbstractLayoutController : NSObject <A_SLayoutController>

@end

@interface A_SAbstractLayoutController (Unavailable)

- (NSHashTable *)indexPathsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType __unavailable;

- (void)allIndexPathsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode displaySet:(NSHashTable * _Nullable * _Nullable)displaySet preloadSet:(NSHashTable * _Nullable * _Nullable)preloadSet __unavailable;

@end

NS_ASSUME_NONNULL_END
