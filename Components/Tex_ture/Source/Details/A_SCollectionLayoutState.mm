//
//  A_SCollectionLayoutState.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SCollectionLayoutState.h>
#import <Async_DisplayKit/A_SCollectionLayoutState+Private.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SPageTable.h>
#import <Async_DisplayKit/A_SThread.h>

#import <queue>

@implementation NSMapTable (A_SCollectionLayoutConvenience)

+ (NSMapTable<A_SCollectionElement *, UICollectionViewLayoutAttributes *> *)elementToLayoutAttributesTable
{
  return [NSMapTable mapTableWithKeyOptions:(NSMapTableWeakMemory | NSMapTableObjectPointerPersonality) valueOptions:NSMapTableStrongMemory];
}

@end

@implementation A_SCollectionLayoutState {
  A_SDN::Mutex __instanceLock__;
  NSMapTable<A_SCollectionElement *, UICollectionViewLayoutAttributes *> *_elementToLayoutAttributesTable;
  A_SPageToLayoutAttributesTable *_pageToLayoutAttributesTable;
  A_SPageToLayoutAttributesTable *_unmeasuredPageToLayoutAttributesTable;
}

- (instancetype)initWithContext:(A_SCollectionLayoutContext *)context
{
  return [self initWithContext:context
                   contentSize:CGSizeZero
elementToLayoutAttributesTable:[NSMapTable elementToLayoutAttributesTable]];
}

- (instancetype)initWithContext:(A_SCollectionLayoutContext *)context
                         layout:(A_SLayout *)layout
                getElementBlock:(A_SCollectionLayoutStateGetElementBlock)getElementBlock
{
  A_SElementMap *elements = context.elements;
  NSMapTable *table = [NSMapTable elementToLayoutAttributesTable];

  // Traverse the given layout tree in breadth first fashion. Generate layout attributes for all included elements along the way. 
  struct Context {
    A_SLayout *layout;
    CGPoint absolutePosition;
  };

  std::queue<Context> queue;
  queue.push({layout, CGPointZero});

  while (!queue.empty()) {
    Context context = queue.front();
    queue.pop();

    A_SLayout *layout = context.layout;
    const CGPoint absolutePosition = context.absolutePosition;

    A_SCollectionElement *element = getElementBlock(layout);
    if (element != nil) {
      NSIndexPath *indexPath = [elements indexPathForElement:element];
      NSString *supplementaryElementKind = element.supplementaryElementKind;

      UICollectionViewLayoutAttributes *attrs;
      if (supplementaryElementKind == nil) {
        attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
      } else {
        attrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:supplementaryElementKind withIndexPath:indexPath];
      }

      CGRect frame = layout.frame;
      frame.origin = absolutePosition;
      attrs.frame = frame;
      [table setObject:attrs forKey:element];
    }

    // Add all sublayouts to process in next step
    for (A_SLayout *sublayout in layout.sublayouts) {
      queue.push({sublayout, absolutePosition + sublayout.position});
    }
  }

  return [self initWithContext:context contentSize:layout.size elementToLayoutAttributesTable:table];
}

- (instancetype)initWithContext:(A_SCollectionLayoutContext *)context
                    contentSize:(CGSize)contentSize
 elementToLayoutAttributesTable:(NSMapTable *)table
{
  self = [super init];
  if (self) {
    _context = context;
    _contentSize = contentSize;
    _elementToLayoutAttributesTable = [table copy]; // Copy the given table to make sure clients can't mutate it after this point.
    CGSize pageSize = context.viewportSize;
    _pageToLayoutAttributesTable = [A_SPageTable pageTableWithLayoutAttributes:table.objectEnumerator contentSize:contentSize pageSize:pageSize];
    _unmeasuredPageToLayoutAttributesTable = [A_SCollectionLayoutState _unmeasuredLayoutAttributesTableFromTable:table contentSize:contentSize pageSize:pageSize];
  }
  return self;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)allLayoutAttributes
{
  return [_elementToLayoutAttributesTable.objectEnumerator allObjects];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  A_SCollectionElement *element = [_context.elements elementForItemAtIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)elementKind
                                                                        atIndexPath:(NSIndexPath *)indexPath
{
  A_SCollectionElement *element = [_context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForElement:(A_SCollectionElement *)element
{
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
  CGSize pageSize = _context.viewportSize;
  NSPointerArray *pages = A_SPageCoordinatesForPagesThatIntersectRect(rect, _contentSize, pageSize);
  if (pages.count == 0) {
    return @[];
  }

  // Use a set here because some items may span multiple pages
  NSMutableSet<UICollectionViewLayoutAttributes *> *result = [NSMutableSet set];
  for (id pagePtr in pages) {
    A_SPageCoordinate page = (A_SPageCoordinate)pagePtr;
    NSArray<UICollectionViewLayoutAttributes *> *allAttrs = [_pageToLayoutAttributesTable objectForPage:page];
    if (allAttrs.count > 0) {
      CGRect pageRect = A_SPageCoordinateGetPageRect(page, pageSize);

      if (CGRectContainsRect(rect, pageRect)) {
        [result addObjectsFromArray:allAttrs];
      } else {
        for (UICollectionViewLayoutAttributes *attrs in allAttrs) {
          if (CGRectIntersectsRect(rect, attrs.frame)) {
            [result addObject:attrs];
          }
        }
      }
    }
  }

  return [result allObjects];
}

- (A_SPageToLayoutAttributesTable *)getAndRemoveUnmeasuredLayoutAttributesPageTableInRect:(CGRect)rect
{
  CGSize pageSize = _context.viewportSize;
  CGSize contentSize = _contentSize;

  A_SDN::MutexLocker l(__instanceLock__);
  if (_unmeasuredPageToLayoutAttributesTable.count == 0 || CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGSizeEqualToSize(CGSizeZero, contentSize) || CGSizeEqualToSize(CGSizeZero, pageSize)) {
    return nil;
  }

  // Step 1: Determine all the pages that intersect the specified rect
  NSPointerArray *pagesInRect = A_SPageCoordinatesForPagesThatIntersectRect(rect, contentSize, pageSize);
  if (pagesInRect.count == 0) {
    return nil;
  }

  // Step 2: Filter out attributes in these pages that intersect the specified rect.
  A_SPageToLayoutAttributesTable *result = nil;
  for (id pagePtr in pagesInRect) {
    A_SPageCoordinate page = (A_SPageCoordinate)pagePtr;
    NSMutableArray *attrsInPage = [_unmeasuredPageToLayoutAttributesTable objectForPage:page];
    if (attrsInPage.count == 0) {
      continue;
    }

    NSMutableArray *intersectingAttrsInPage = nil;
    CGRect pageRect = A_SPageCoordinateGetPageRect(page, pageSize);
    if (CGRectContainsRect(rect, pageRect)) {
      // This page fits well within the specified rect. Simply return all of its attributes.
      intersectingAttrsInPage = attrsInPage;
    } else {
      // The page intersects the specified rect. Some attributes in this page are returned, some are not.
      for (UICollectionViewLayoutAttributes *attrs in attrsInPage) {
        if (CGRectIntersectsRect(rect, attrs.frame)) {
          if (intersectingAttrsInPage == nil) {
            intersectingAttrsInPage = [NSMutableArray array];
          }
          [intersectingAttrsInPage addObject:attrs];
        }
      }
    }

    if (intersectingAttrsInPage.count > 0) {
      if (attrsInPage.count == intersectingAttrsInPage.count) {
        [_unmeasuredPageToLayoutAttributesTable removeObjectForPage:page];
      } else {
        [attrsInPage removeObjectsInArray:intersectingAttrsInPage];
      }
      if (result == nil) {
        result = [A_SPageTable pageTableForStrongObjectPointers];
      }
      [result setObject:intersectingAttrsInPage forPage:page];
    }
  }

  return result;
}

#pragma mark - Private methods

+ (A_SPageToLayoutAttributesTable *)_unmeasuredLayoutAttributesTableFromTable:(NSMapTable<A_SCollectionElement *, UICollectionViewLayoutAttributes *> *)table
                                                                 contentSize:(CGSize)contentSize
                                                                    pageSize:(CGSize)pageSize
{
  NSMutableArray<UICollectionViewLayoutAttributes *> *unmeasuredAttrs = [NSMutableArray array];
  for (A_SCollectionElement *element in table) {
    UICollectionViewLayoutAttributes *attrs = [table objectForKey:element];
    if (element.nodeIfAllocated == nil || CGSizeEqualToSize(element.nodeIfAllocated.calculatedSize, attrs.frame.size) == NO) {
      [unmeasuredAttrs addObject:attrs];
    }
  }

  return [A_SPageTable pageTableWithLayoutAttributes:unmeasuredAttrs contentSize:contentSize pageSize:pageSize];
}

@end
