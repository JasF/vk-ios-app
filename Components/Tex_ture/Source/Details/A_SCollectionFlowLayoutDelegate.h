//
//  A_SCollectionFlowLayoutDelegate.h
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

#import <Async_DisplayKit/A_SCollectionLayoutDelegate.h>

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED

/**
 * A thread-safe, high performant layout delegate that arranges items into a flow layout. 
 * It uses a concurrent and multi-line A_SStackLayoutSpec under the hood. Thus, per-child flex properties (i.e alignSelf, 
 * flexShrink, flexGrow, etc - see @A_SStackLayoutElement) can be set directly on cell nodes to be used
 * to calculate the final collection layout.
 */
@interface A_SCollectionFlowLayoutDelegate : NSObject <A_SCollectionLayoutDelegate>

- (instancetype)initWithScrollableDirections:(A_SScrollDirection)scrollableDirections NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
