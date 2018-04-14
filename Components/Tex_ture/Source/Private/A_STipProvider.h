//
//  A_STipProvider.h
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

#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#if A_S_ENABLE_TIPS

@class A_SDisplayNode, A_STip;

NS_ASSUME_NONNULL_BEGIN

/**
 * An abstract superclass for all tip providers.
 */
@interface A_STipProvider : NSObject

/**
 * The provider looks at the node's current situation and
 * generates a tip, if any, to add to the node.
 *
 * Subclasses must override this.
 */
- (nullable A_STip *)tipForNode:(A_SDisplayNode *)node;

@end

@interface A_STipProvider (Lookup)

@property (class, nonatomic, copy, readonly) NSArray<__kindof A_STipProvider *> *all;

@end

NS_ASSUME_NONNULL_END

#endif // A_S_ENABLE_TIPS
