//
//  Async_DisplayKit+IGListKitMethods.m
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

#import <Async_DisplayKit/A_SAvailability.h>

#if A_S_IG_LIST_KIT

#import "Async_DisplayKit+IGListKitMethods.h"
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/_A_SCollectionViewCell.h>
#import <Async_DisplayKit/_A_SCollectionReusableView.h>


@implementation A_SIGListSectionControllerMethods

+ (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index sectionController:(IGListSectionController *)sectionController
{
  // Cast to id for backwards-compatibility until 3.0.0 is officially released – IGListSectionType was removed. This is safe.
  return [sectionController.collectionContext dequeueReusableCellOfClass:[_A_SCollectionViewCell class] forSectionController:(id)sectionController atIndex:index];
}

+ (CGSize)sizeForItemAtIndex:(NSInteger)index
{
  A_SDisplayNodeFailAssert(@"Did not expect %@ to be called.", NSStringFromSelector(_cmd));
  return CGSizeZero;
}

@end

@implementation A_SIGListSupplementaryViewSourceMethods

+ (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind
                                                                 atIndex:(NSInteger)index
                                                       sectionController:(IGListSectionController *)sectionController
{
  return [sectionController.collectionContext dequeueReusableSupplementaryViewOfKind:elementKind forSectionController:(id)sectionController class:[_A_SCollectionReusableView class] atIndex:index];
}

+ (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  A_SDisplayNodeFailAssert(@"Did not expect %@ to be called.", NSStringFromSelector(_cmd));
  return CGSizeZero;
}

@end

#endif // A_S_IG_LIST_KIT
