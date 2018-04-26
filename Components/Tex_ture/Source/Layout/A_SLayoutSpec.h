//
//  A_SLayoutSpec.h
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

#import <Async_DisplayKit/A_SLayoutElement.h>
#import <Async_DisplayKit/A_SAsciiArtBoxCreator.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A layout spec is an immutable object that describes a layout, loosely inspired by React.
 */
@interface A_SLayoutSpec : NSObject <A_SLayoutElement, A_SLayoutElementStylability, NSFastEnumeration, A_SDescriptionProvider>

/** 
 * Creation of a layout spec should only happen by a user in layoutSpecThatFits:. During that method, a
 * layout spec can be created and mutated. Once it is passed back to A_SDK, the isMutable flag will be
 * set to NO and any further mutations will cause an assert.
 */
@property (nonatomic, assign) BOOL isMutable;

/**
 * First child within the children's array.
 *
 * @discussion Every A_SLayoutSpec must act on at least one child. The A_SLayoutSpec base class takes the
 * responsibility of holding on to the spec children. Some layout specs, like A_SInsetLayoutSpec,
 * only require a single child.
 *
 * For layout specs that require a known number of children (A_SBackgroundLayoutSpec, for example)
 * a subclass should use this method to set the "primary" child. It can then use setChild:atIndex:
 * to set any other required children. Ideally a subclass would hide this from the user, and use the
 * setChild:atIndex: internally. For example, A_SBackgroundLayoutSpec exposes a "background"
 * property that behind the scenes is calling setChild:atIndex:.
 */
@property (nullable, strong, nonatomic) id<A_SLayoutElement> child;

/**
 * An array of A_SLayoutElement children
 * 
 * @discussion Every A_SLayoutSpec must act on at least one child. The A_SLayoutSpec base class takes the
 * reponsibility of holding on to the spec children. Some layout specs, like A_SStackLayoutSpec,
 * can take an unknown number of children. In this case, the this method should be used.
 * For good measure, in these layout specs it probably makes sense to define
 * setChild: and setChild:forIdentifier: methods to do something appropriate or to assert.
 */
@property (nullable, strong, nonatomic) NSArray<id<A_SLayoutElement>> *children;

@end

/**
 * An A_SLayoutSpec subclass that can wrap one or more A_SLayoutElement and calculates the layout based on the
 * sizes of the children. If multiple children are provided the size of the biggest child will be used to for
 * size of this layout spec.
 */
@interface A_SWrapperLayoutSpec : A_SLayoutSpec

/*
 * Returns an A_SWrapperLayoutSpec object with the given layoutElement as child.
 */
+ (instancetype)wrapperWithLayoutElement:(id<A_SLayoutElement>)layoutElement A_S_WARN_UNUSED_RESULT;

/*
 * Returns an A_SWrapperLayoutSpec object with the given layoutElements as children.
 */
+ (instancetype)wrapperWithLayoutElements:(NSArray<id<A_SLayoutElement>> *)layoutElements A_S_WARN_UNUSED_RESULT;

/*
 * Returns an A_SWrapperLayoutSpec object initialized with the given layoutElement as child.
 */
- (instancetype)initWithLayoutElement:(id<A_SLayoutElement>)layoutElement A_S_WARN_UNUSED_RESULT;

/*
 * Returns an A_SWrapperLayoutSpec object initialized with the given layoutElements as children.
 */
- (instancetype)initWithLayoutElements:(NSArray<id<A_SLayoutElement>> *)layoutElements A_S_WARN_UNUSED_RESULT;

/*
 * Init not available for A_SWrapperLayoutSpec
 */
- (instancetype)init __unavailable;

@end

@interface A_SLayoutSpec (Debugging) <A_SDebugNameProvider>
/**
 *  Used by other layout specs to create ascii art debug strings
 */
+ (NSString *)asciiArtStringForChildren:(NSArray *)children parentName:(NSString *)parentName direction:(A_SStackLayoutDirection)direction;
+ (NSString *)asciiArtStringForChildren:(NSArray *)children parentName:(NSString *)parentName;

@end

NS_ASSUME_NONNULL_END
