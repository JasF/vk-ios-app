//
//  A_SLayoutController.h
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

#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_SScrollDirection.h>

NS_ASSUME_NONNULL_BEGIN

@class A_SCollectionElement, A_SElementMap;

A_SDISPLAYNODE_EXTERN_C_BEGIN

struct A_SDirectionalScreenfulBuffer {
  CGFloat positiveDirection; // Positive relative to iOS Core Animation layer coordinate space.
  CGFloat negativeDirection;
};
typedef struct A_SDirectionalScreenfulBuffer A_SDirectionalScreenfulBuffer;

A_SDISPLAYNODE_EXTERN_C_END

@protocol A_SLayoutController <NSObject>

- (void)setTuningParameters:(A_SRangeTuningParameters)tuningParameters forRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType;

- (A_SRangeTuningParameters)tuningParametersForRangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType;

- (NSHashTable<A_SCollectionElement *> *)elementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType map:(A_SElementMap *)map;

- (void)allElementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode displaySet:(NSHashTable<A_SCollectionElement *> * _Nullable * _Nullable)displaySet preloadSet:(NSHashTable<A_SCollectionElement *> * _Nullable * _Nullable)preloadSet map:(A_SElementMap *)map;

@optional

@end

NS_ASSUME_NONNULL_END
