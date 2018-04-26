//
//  A_STip.h
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

NS_ASSUME_NONNULL_BEGIN

@class A_SDisplayNode;

typedef NS_ENUM (NSInteger, A_STipKind) {
  A_STipKindEnableLayerBacking
};

A_S_SUBCLASSING_RESTRICTED
@interface A_STip : NSObject

- (instancetype)initWithNode:(A_SDisplayNode *)node
                        kind:(A_STipKind)kind
                      format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

/**
 * The kind of tip this is.
 */
@property (nonatomic, readonly) A_STipKind kind;

/**
 * The node that this tip applies to.
 */
@property (nonatomic, strong, readonly) A_SDisplayNode *node;

/**
 * The text to show the user.
 */
@property (nonatomic, strong, readonly) NSString *text;

@end

NS_ASSUME_NONNULL_END

#endif // A_S_ENABLE_TIPS
