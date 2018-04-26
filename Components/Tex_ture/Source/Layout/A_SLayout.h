//
//  A_SLayout.h
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

#pragma once
#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SLayoutElement.h>

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

extern CGPoint const A_SPointNull; // {NAN, NAN}

extern BOOL A_SPointIsNull(CGPoint point);

/**
 * Safely calculates the layout of the given root layoutElement by guarding against nil nodes.
 * @param rootLayoutElement The root node to calculate the layout for.
 * @param sizeRange The size range to calculate the root layout within.
 */
extern A_SLayout *A_SCalculateRootLayout(id<A_SLayoutElement> rootLayoutElement, const A_SSizeRange sizeRange);

/**
 * Safely computes the layout of the given node by guarding against nil nodes.
 * @param layoutElement The layout element to calculate the layout for.
 * @param sizeRange The size range to calculate the node layout within.
 * @param parentSize The parent size of the node to calculate the layout for.
 */
extern A_SLayout *A_SCalculateLayout(id<A_SLayoutElement>layoutElement, const A_SSizeRange sizeRange, const CGSize parentSize);

A_SDISPLAYNODE_EXTERN_C_END

/**
 * A node in the layout tree that represents the size and position of the object that created it (A_SLayoutElement).
 */
@interface A_SLayout : NSObject

/**
 * The underlying object described by this layout
 */
@property (nonatomic, weak, readonly) id<A_SLayoutElement> layoutElement;

/**
 * The type of A_SLayoutElement that created this layout
 */
@property (nonatomic, assign, readonly) A_SLayoutElementType type;

/**
 * Size of the current layout
 */
@property (nonatomic, assign, readonly) CGSize size;

/**
 * Position in parent. Default to A_SPointNull.
 * 
 * @discussion When being used as a sublayout, this property must not equal A_SPointNull.
 */
@property (nonatomic, assign, readonly) CGPoint position;

/**
 * Array of A_SLayouts. Each must have a valid non-null position.
 */
@property (nonatomic, copy, readonly) NSArray<A_SLayout *> *sublayouts;

/**
 * The frame for the given element, or CGRectNull if 
 * the element is not a direct descendent of this layout.
 */
- (CGRect)frameForElement:(id<A_SLayoutElement>)layoutElement;

/**
 * @abstract Returns a valid frame for the current layout computed with the size and position.
 * @discussion Clamps the layout's origin or position to 0 if any of the calculated values are infinite.
 */
@property (nonatomic, assign, readonly) CGRect frame;

/**
 * Designated initializer
 */
- (instancetype)initWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                 size:(CGSize)size
                             position:(CGPoint)position
                           sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts NS_DESIGNATED_INITIALIZER;

/**
 * Convenience class initializer for layout construction.
 *
 * @param layoutElement The backing A_SLayoutElement object.
 * @param size             The size of this layout.
 * @param position         The position of this layout within its parent (if available).
 * @param sublayouts       Sublayouts belong to the new layout.
 */
+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                   size:(CGSize)size
                               position:(CGPoint)position
                             sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts A_S_WARN_UNUSED_RESULT;

/**
 * Convenience initializer that has CGPointNull position.
 * Best used by A_SDisplayNode subclasses that are manually creating a layout for -calculateLayoutThatFits:,
 * or for A_SLayoutSpec subclasses that are referencing the "self" level in the layout tree,
 * or for creating a sublayout of which the position is yet to be determined.
 *
 * @param layoutElement  The backing A_SLayoutElement object.
 * @param size              The size of this layout.
 * @param sublayouts        Sublayouts belong to the new layout.
 */
+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                   size:(CGSize)size
                             sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts A_S_WARN_UNUSED_RESULT;

/**
 * Convenience that has CGPointNull position and no sublayouts.
 * Best used for creating a layout that has no sublayouts, and is either a root one
 * or a sublayout of which the position is yet to be determined.
 *
 * @param layoutElement The backing A_SLayoutElement object.
 * @param size             The size of this layout.
 */
+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                   size:(CGSize)size A_S_WARN_UNUSED_RESULT;
/**
 * Traverses the existing layout tree and generates a new tree that represents only A_SDisplayNode layouts
 */
- (A_SLayout *)filteredNodeLayoutTree A_S_WARN_UNUSED_RESULT;

@end

@interface A_SLayout (Unavailable)

- (instancetype)init __unavailable;

@end

#pragma mark - Debugging

@interface A_SLayout (Debugging)

/**
 * Set to YES to tell all A_SLayout instances to retain their sublayout elements. Defaults to NO.
 * Can be overridden at instance level.
 */
+ (void)setShouldRetainSublayoutLayoutElements:(BOOL)shouldRetain;

/**
 * Whether or not A_SLayout instances should retain their sublayout elements.
 * Can be overridden at instance level.
 */
+ (BOOL)shouldRetainSublayoutLayoutElements;

/**
 * Recrusively output the description of the layout tree.
 */
- (NSString *)recursiveDescription;

@end

NS_ASSUME_NONNULL_END
