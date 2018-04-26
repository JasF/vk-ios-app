//
//  UICollectionViewLayout+A_SConvenience.m
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

#import <Async_DisplayKit/UICollectionViewLayout+A_SConvenience.h>

#import <UIKit/UICollectionViewFlowLayout.h>

#import <Async_DisplayKit/A_SCollectionViewFlowLayoutInspector.h>

@implementation UICollectionViewLayout (A_SLayoutInspectorProviding)

- (id<A_SCollectionViewLayoutInspecting>)asdk_layoutInspector
{
  UICollectionViewFlowLayout *flow = A_SDynamicCast(self, UICollectionViewFlowLayout);
  if (flow != nil) {
    return [[A_SCollectionViewFlowLayoutInspector alloc] initWithFlowLayout:flow];
  } else {
    return [[A_SCollectionViewLayoutInspector alloc] init];
  }
}

@end
