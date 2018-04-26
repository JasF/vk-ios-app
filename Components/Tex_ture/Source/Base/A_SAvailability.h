//
//  A_SAvailability.h
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

#import <CoreFoundation/CFBase.h>

#pragma once

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
  #define kCFCoreFoundationVersionNumber_iOS_9_0 1240.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_10_0
  #define kCFCoreFoundationVersionNumber_iOS_10_0 1348.00
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
  #define kCFCoreFoundationVersionNumber_iOS_11_0 1438.10
#endif

#ifndef __IPHONE_11_0
  #define __IPHONE_11_0 110000
#endif

#define A_S_AT_LEA_ST_IOS9   (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
#define A_S_AT_LEA_ST_IOS10  (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_10_0)
#define A_S_AT_LEA_ST_IOS11  (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)

// Use __builtin_available if we're on Xcode >= 9, A_S_AT_LEA_ST otherwise.
#if __has_builtin(__builtin_available)
  #define A_S_AVAILABLE_IOS(ver)   __builtin_available(iOS ver, *)
#else
  #define A_S_AVAILABLE_IOS(ver)   A_S_AT_LEA_ST_IOS##ver
#endif

// If Yoga is available, make it available anywhere we use A_SAvailability.
// This reduces Yoga-specific code in other files.
// NOTE: Yoga integration is experimental and not fully tested. Use with caution and test layouts carefully.
#ifndef YOGA_HEADER_PATH
  #define YOGA_HEADER_PATH <yoga/Yoga.h>
#endif

#ifndef YOGA
  #define YOGA __has_include(YOGA_HEADER_PATH)
#endif

// When enabled, use A_STextNode2 for ALL instances of A_STextNode.
// This includes what A_SButtonNode uses internally, as well as all app references to A_STextNode.
// See A_STextNode+Beta.h declaration of A_STextNodeExperimentOptions for more details.
#ifndef A_STEXTNODE_EXPERIMENT_GLOBAL_ENABLE
  #define A_STEXTNODE_EXPERIMENT_GLOBAL_ENABLE 0
#endif

#define A_S_PI_N_REMOTE_IMAGE __has_include(<PI_NRemoteImage/PI_NRemoteImage.h>)
#define A_S_IG_LIST_KIT __has_include(<IGListKit/IGListKit.h>)

/**
 * For IGListKit versions < 3.0, you have to use IGListCollectionView.
 * For 3.0 and later, that class is removed and you use UICollectionView.
 */
#define IG_LIST_COLLECTION_VIEW __has_include(<IGListKit/IGListCollectionView.h>)
