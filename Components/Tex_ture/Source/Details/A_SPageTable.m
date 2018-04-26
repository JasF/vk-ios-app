//
//  A_SPageTable.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SPageTable.h>

extern A_SPageCoordinate A_SPageCoordinateMake(uint16_t x, uint16_t y)
{
  // Add 1 to the end result because 0 is not accepted by NSArray and NSMapTable.
  // To avoid overflow after adding, x and y can't be UINT16_MAX (0xFFFF) **at the same time**.
  // But for API simplification, we enforce the same restriction to both values.
  A_SDisplayNodeCAssert(x < UINT16_MAX, @"x coordinate must be less than 65,535");
  A_SDisplayNodeCAssert(y < UINT16_MAX, @"y coordinate must be less than 65,535");
  return (x << 16) + y + 1;
}

extern A_SPageCoordinate A_SPageCoordinateForPageThatContainsPoint(CGPoint point, CGSize pageSize)
{
  return A_SPageCoordinateMake((MAX(0.0, point.x) / pageSize.width), (MAX(0.0, point.y) / pageSize.height));
}

extern uint16_t A_SPageCoordinateGetX(A_SPageCoordinate pageCoordinate)
{
  return (pageCoordinate - 1) >> 16;
}

extern uint16_t A_SPageCoordinateGetY(A_SPageCoordinate pageCoordinate)
{
  return (pageCoordinate - 1) & ~(0xFFFF<<16);
}

extern CGRect A_SPageCoordinateGetPageRect(A_SPageCoordinate pageCoordinate, CGSize pageSize)
{
  CGFloat pageWidth = pageSize.width;
  CGFloat pageHeight = pageSize.height;
  return CGRectMake(A_SPageCoordinateGetX(pageCoordinate) * pageWidth, A_SPageCoordinateGetY(pageCoordinate) * pageHeight, pageWidth, pageHeight);
}

extern NSPointerArray *A_SPageCoordinatesForPagesThatIntersectRect(CGRect rect, CGSize contentSize, CGSize pageSize)
{
  CGRect contentRect = CGRectMake(0.0, 0.0, contentSize.width, contentSize.height);
  // Make sure the specified rect is within contentRect
  rect = CGRectIntersection(rect, contentRect);
  if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) {
    return nil;
  }
  
  NSPointerArray *result = [NSPointerArray pointerArrayWithOptions:(NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory)];
  
  A_SPageCoordinate minPage = A_SPageCoordinateForPageThatContainsPoint(CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect)), pageSize);
  A_SPageCoordinate maxPage = A_SPageCoordinateForPageThatContainsPoint(CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)), pageSize);
  if (minPage == maxPage) {
    [result addPointer:(void *)minPage];
    return result;
  }
  
  NSUInteger minX = A_SPageCoordinateGetX(minPage);
  NSUInteger minY = A_SPageCoordinateGetY(minPage);
  NSUInteger maxX = A_SPageCoordinateGetX(maxPage);
  NSUInteger maxY = A_SPageCoordinateGetY(maxPage);
  
  for (NSUInteger x = minX; x <= maxX; x++) {
    for (NSUInteger y = minY; y <= maxY; y++) {
      A_SPageCoordinate page = A_SPageCoordinateMake(x, y);
      [result addPointer:(void *)page];
    }
  }
  
  return result;
}

@implementation NSMapTable (A_SPageTableMethods)

+ (instancetype)pageTableWithValuePointerFunctions:(NSPointerFunctions *)valueFuncs
{
  static NSPointerFunctions *pageCoordinatesFuncs;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pageCoordinatesFuncs = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsIntegerPersonality | NSPointerFunctionsOpaqueMemory];
  });
  
  return [[NSMapTable alloc] initWithKeyPointerFunctions:pageCoordinatesFuncs valuePointerFunctions:valueFuncs capacity:0];
}

+ (A_SPageTable *)pageTableForStrongObjectPointers
{
  static NSPointerFunctions *strongObjectPointerFuncs;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    strongObjectPointerFuncs = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsStrongMemory];
  });
  return [self pageTableWithValuePointerFunctions:strongObjectPointerFuncs];
}

+ (A_SPageTable *)pageTableForWeakObjectPointers
{
  static NSPointerFunctions *weakObjectPointerFuncs;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    weakObjectPointerFuncs = [NSPointerFunctions pointerFunctionsWithOptions:NSPointerFunctionsWeakMemory];
  });
  return [self pageTableWithValuePointerFunctions:weakObjectPointerFuncs];
}

+ (A_SPageToLayoutAttributesTable *)pageTableWithLayoutAttributes:(id<NSFastEnumeration>)layoutAttributesEnumerator contentSize:(CGSize)contentSize pageSize:(CGSize)pageSize
{
  A_SPageToLayoutAttributesTable *result = [A_SPageTable pageTableForStrongObjectPointers];
  for (UICollectionViewLayoutAttributes *attrs in layoutAttributesEnumerator) {
    // This attrs may span multiple pages. Make sure it's registered to all of them
    NSPointerArray *pages = A_SPageCoordinatesForPagesThatIntersectRect(attrs.frame, contentSize, pageSize);
    
    for (id pagePtr in pages) {
      A_SPageCoordinate page = (A_SPageCoordinate)pagePtr;
      NSMutableArray<UICollectionViewLayoutAttributes *> *attrsInPage = [result objectForPage:page];
      if (attrsInPage == nil) {
        attrsInPage = [NSMutableArray array];
        [result setObject:attrsInPage forPage:page];
      }
      [attrsInPage addObject:attrs];
    }
  }  
  return result;
}

- (id)objectForPage:(A_SPageCoordinate)page
{
  __unsafe_unretained id key = (__bridge id)(void *)page;
  return [self objectForKey:key];
}

- (void)setObject:(id)object forPage:(A_SPageCoordinate)page
{
  __unsafe_unretained id key = (__bridge id)(void *)page;
  [self setObject:object forKey:key];
}

- (void)removeObjectForPage:(A_SPageCoordinate)page
{
  __unsafe_unretained id key = (__bridge id)(void *)page;
  [self removeObjectForKey:key];
}

@end
