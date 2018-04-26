//
//  A_SLayoutSpec+Subclasses.h
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
#import <Async_DisplayKit/A_SLayoutSpec.h>
#import <Async_DisplayKit/A_SLayout.h>

NS_ASSUME_NONNULL_BEGIN

@protocol A_SLayoutElement;

@interface A_SLayoutSpec (Subclassing)

/**
 * Adds a child with the given identifier to this layout spec.
 *
 * @param child A child to be added.
 *
 * @param index An index associated with the child.
 *
 * @discussion Every A_SLayoutSpec must act on at least one child. The A_SLayoutSpec base class takes the
 * responsibility of holding on to the spec children. Some layout specs, like A_SInsetLayoutSpec,
 * only require a single child.
 *
 * For layout specs that require a known number of children (A_SBackgroundLayoutSpec, for example)
 * a subclass can use the setChild method to set the "primary" child. It should then use this method
 * to set any other required children. Ideally a subclass would hide this from the user, and use the
 * setChild:forIndex: internally. For example, A_SBackgroundLayoutSpec exposes a backgroundChild
 * property that behind the scenes is calling setChild:forIndex:.
 */
- (void)setChild:(id<A_SLayoutElement>)child atIndex:(NSUInteger)index;

/**
 * Returns the child added to this layout spec using the given index.
 *
 * @param index An identifier associated with the the child.
 */
- (nullable id<A_SLayoutElement>)childAtIndex:(NSUInteger)index;

@end

@interface A_SLayout ()

/**
 * Position in parent. Default to CGPointNull.
 *
 * @discussion When being used as a sublayout, this property must not equal CGPointNull.
 */
@property (nonatomic, assign, readwrite) CGPoint position;

@end

NS_ASSUME_NONNULL_END
