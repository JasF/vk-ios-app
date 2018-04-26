//
//  Async_DisplayKit+IGListKitMethods.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * If you are using Async_DisplayKit with IGListKit, you should use
 * these methods to provide implementations for methods like
 * -cellForItemAtIndex: that don't apply when used with Async_DisplayKit.
 *
 * Your section controllers should also conform to @c A_SSectionController and your
 * supplementary view sources should conform to @c A_SSupplementaryNodeSource.
 */

A_S_SUBCLASSING_RESTRICTED
@interface A_SIGListSectionControllerMethods : NSObject

/**
 * Call this for your section controller's @c cellForItemAtIndex: method.
 */
+ (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index sectionController:(IGListSectionController *)sectionController;

/**
 * Call this for your section controller's @c sizeForItemAtIndex: method.
 */
+ (CGSize)sizeForItemAtIndex:(NSInteger)index;

@end

A_S_SUBCLASSING_RESTRICTED
@interface A_SIGListSupplementaryViewSourceMethods : NSObject

/**
 * Call this for your supplementary source's @c viewForSupplementaryElementOfKind:atIndex: method.
 */
+ (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind
                                                                 atIndex:(NSInteger)index
                                                       sectionController:(IGListSectionController *)sectionController;

/**
 * Call this for your supplementary source's @c sizeForSupplementaryViewOfKind:atIndex: method.
 */
+ (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END

#endif
