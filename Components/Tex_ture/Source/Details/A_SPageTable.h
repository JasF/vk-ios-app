//
//  A_SPageTable.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

@class A_SCollectionElement;

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

/**
 * Represents x and y coordinates of a page.
 */
typedef uintptr_t A_SPageCoordinate;

/**
 * Returns a page coordinate with the given x and y values. Both of them must be less than 65,535.
 */
extern A_SPageCoordinate A_SPageCoordinateMake(uint16_t x, uint16_t y) A_S_WARN_UNUSED_RESULT;

/**
 * Returns coordinate of the page that contains the specified point.
 * Similar to CGRectContainsPoint, a point is considered inside a page if its  lie inside the page or on the minimum X or minimum Y edge.
 *
 * @param point The point that the page at the returned  should contain. Any negative  of the point will be corrected to 0.0
 *
 * @param pageSize The size of each page.
 */
extern A_SPageCoordinate A_SPageCoordinateForPageThatContainsPoint(CGPoint point, CGSize pageSize) A_S_WARN_UNUSED_RESULT;

extern uint16_t A_SPageCoordinateGetX(A_SPageCoordinate pageCoordinate) A_S_WARN_UNUSED_RESULT;

extern uint16_t A_SPageCoordinateGetY(A_SPageCoordinate pageCoordinate) A_S_WARN_UNUSED_RESULT;

extern CGRect A_SPageCoordinateGetPageRect(A_SPageCoordinate pageCoordinate, CGSize pageSize) A_S_WARN_UNUSED_RESULT;

/**
 * Returns coordinate pointers for pages that intersect the specified rect. For each pointer, use A_SPageCoordinateFromPointer() to get the original coordinate.
 * The specified rect is restricted to the bounds of a content rect that has an origin of {0, 0} and a size of the given contentSize.
 *
 * @param rect The rect intersecting the target pages.
 *
 * @param contentSize The combined size of all pages.
 *
 * @param pageSize The size of each page.
 */
extern NSPointerArray * _Nullable A_SPageCoordinatesForPagesThatIntersectRect(CGRect rect, CGSize contentSize, CGSize pageSize) A_S_WARN_UNUSED_RESULT;

A_SDISPLAYNODE_EXTERN_C_END

/**
 * An alias for an NSMapTable created to store objects using A_SPageCoordinates as keys.
 *
 * You should not call -objectForKey:, -setObject:forKey:, or -removeObjectForKey:
 * on these objects.
 */
typedef NSMapTable A_SPageTable;

/**
 * A page to array of layout attributes table.
 */
typedef A_SPageTable<id, NSMutableArray<UICollectionViewLayoutAttributes *> *> A_SPageToLayoutAttributesTable;

/**
 * A category for creating & using map tables meant for storing objects using A_SPage as keys.
 */
@interface NSMapTable<id, ObjectType> (A_SPageTableMethods)

/**
 * Creates a new page table with (NSMapTableStrongMemory | NSMapTableObjectPointerPersonality) for values.
 */
+ (A_SPageTable *)pageTableForStrongObjectPointers;

/**
 * Creates a new page table with (NSMapTableWeakMemory | NSMapTableObjectPointerPersonality) for values.
 */
+ (A_SPageTable *)pageTableForWeakObjectPointers;

/**
 * Builds a new page to layout attributes from the given layout attributes.
 *
 * @param layoutAttributesEnumerator The layout attributes to build from
 *
 * @param contentSize The combined size of all pages.
 *
 * @param pageSize The size of each page.
 */
+ (A_SPageToLayoutAttributesTable *)pageTableWithLayoutAttributes:(id<NSFastEnumeration>)layoutAttributesEnumerator contentSize:(CGSize)contentSize pageSize:(CGSize)pageSize;

/**
 * Retrieves the object for a given page, or nil if the page is not found.
 *
 * @param page A page to lookup the object for.
 */
- (nullable ObjectType)objectForPage:(A_SPageCoordinate)page;

/**
 * Sets the given object for the associated page.
 *
 * @param object The object to store as value.
 *
 * @param page The page to use for the rect.
 */
- (void)setObject:(ObjectType)object forPage:(A_SPageCoordinate)page;

/**
 * Removes the object for the given page, if one exists.
 *
 * @param page The page to remove.
 */
- (void)removeObjectForPage:(A_SPageCoordinate)page;

@end

NS_ASSUME_NONNULL_END
