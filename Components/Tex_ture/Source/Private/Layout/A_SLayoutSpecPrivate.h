//
//  A_SLayoutSpecPrivate.h
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

#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SThread.h>

#if DEBUG
  #define A_S_DEDUPE_LAYOUT_SPEC_TREE 1
#else
  #define A_S_DEDUPE_LAYOUT_SPEC_TREE 0
#endif

NS_ASSUME_NONNULL_BEGIN

@interface A_SLayoutSpec() {
  A_SDN::RecursiveMutex __instanceLock__;
  std::atomic <A_SPrimitiveTraitCollection> _primitiveTraitCollection;
  A_SLayoutElementStyle *_style;
  NSMutableArray *_childrenArray;
}

#if A_S_DEDUPE_LAYOUT_SPEC_TREE
/**
 * Recursively search the subtree for elements that occur more than once.
 */
- (nullable NSHashTable<id<A_SLayoutElement>> *)findDuplicatedElementsInSubtree;
#endif

@end

NS_ASSUME_NONNULL_END
