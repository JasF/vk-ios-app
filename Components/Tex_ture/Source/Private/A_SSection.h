//
//  A_SSection.h
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

@protocol A_SSectionContext;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object representing the metadata for a section of elements in a collection.
 *
 * Its sectionID is namespaced to the data controller that created the section.
 *
 * These are useful for tracking the movement & lifetime of sections, independent of
 * their contents.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SSection : NSObject

@property (assign, readonly) NSInteger sectionID;
@property (strong, nullable, readonly) id<A_SSectionContext> context;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSectionID:(NSInteger)sectionID context:(nullable id<A_SSectionContext>)context NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
