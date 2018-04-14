//
//  A_SListTestSupplementarySource.m
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

#import "A_SListTestSupplementarySource.h"
#import "A_SListTestSupplementaryNode.h"

@implementation A_SListTestSupplementarySource

- (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [A_SIGListSupplementaryViewSourceMethods viewForSupplementaryElementOfKind:elementKind atIndex:index sectionController:self.sectionController];
}

- (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [A_SIGListSupplementaryViewSourceMethods sizeForSupplementaryViewOfKind:elementKind atIndex:index];
}

- (A_SCellNodeBlock)nodeBlockForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return ^{
    A_SListTestSupplementaryNode *node = [[A_SListTestSupplementaryNode alloc] init];
    node.style.preferredSize = CGSizeMake(100, 10);
    return node;
  };
}

@end
