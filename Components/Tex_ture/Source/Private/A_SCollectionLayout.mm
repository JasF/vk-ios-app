//
//  A_SCollectionLayout.mm
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

#import <Async_DisplayKit/A_SCollectionLayout.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SAbstractLayoutController.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionLayoutCache.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext+Private.h>
#import <Async_DisplayKit/A_SCollectionLayoutDelegate.h>
#import <Async_DisplayKit/A_SCollectionLayoutState+Private.h>
#import <Async_DisplayKit/A_SCollectionNode+Beta.h>
#import <Async_DisplayKit/A_SDispatch.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SPageTable.h>

static const A_SRangeTuningParameters kA_SDefaultMeasureRangeTuningParameters = {
  .leadingBufferScreenfuls = 2.0,
  .trailingBufferScreenfuls = 2.0
};

static const A_SScrollDirection kA_SStaticScrollDirection = (A_SScrollDirectionRight | A_SScrollDirectionDown);

@interface A_SCollectionLayout () <A_SDataControllerLayoutDelegate> {
  A_SCollectionLayoutCache *_layoutCache;
  A_SCollectionLayoutState *_layout; // Main thread only.

  struct {
    unsigned int implementsAdditionalInfoForLayoutWithElements:1;
  } _layoutDelegateFlags;
}

@end

@implementation A_SCollectionLayout

- (instancetype)initWithLayoutDelegate:(id<A_SCollectionLayoutDelegate>)layoutDelegate
{
  self = [super init];
  if (self) {
    A_SDisplayNodeAssertNotNil(layoutDelegate, @"Collection layout delegate cannot be nil");
    _layoutDelegate = layoutDelegate;
    _layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements = [layoutDelegate respondsToSelector:@selector(additionalInfoForLayoutWithElements:)];
    _layoutCache = [[A_SCollectionLayoutCache alloc] init];
  }
  return self;
}

#pragma mark - A_SDataControllerLayoutDelegate

- (A_SCollectionLayoutContext *)layoutContextWithElements:(A_SElementMap *)elements
{
  A_SDisplayNodeAssertMainThread();

  Class<A_SCollectionLayoutDelegate> layoutDelegateClass = [_layoutDelegate class];
  A_SCollectionLayoutCache *layoutCache = _layoutCache;
  A_SCollectionNode *collectionNode = _collectionNode;
  if (collectionNode == nil) {
    return [[A_SCollectionLayoutContext alloc] initWithViewportSize:CGSizeZero
                                              initialContentOffset:CGPointZero
                                              scrollableDirections:A_SScrollDirectionNone
                                                          elements:[[A_SElementMap alloc] init]
                                               layoutDelegateClass:layoutDelegateClass
                                                       layoutCache:layoutCache
                                                    additionalInfo:nil];
  }

  A_SScrollDirection scrollableDirections = [_layoutDelegate scrollableDirections];
  CGSize viewportSize = [A_SCollectionLayout _viewportSizeForCollectionNode:collectionNode scrollableDirections:scrollableDirections];
  CGPoint contentOffset = collectionNode.contentOffset;

  id additionalInfo = nil;
  if (_layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements) {
    additionalInfo = [_layoutDelegate additionalInfoForLayoutWithElements:elements];
  }

  return [[A_SCollectionLayoutContext alloc] initWithViewportSize:viewportSize
                                            initialContentOffset:contentOffset
                                            scrollableDirections:scrollableDirections
                                                        elements:elements
                                             layoutDelegateClass:layoutDelegateClass
                                                     layoutCache:layoutCache
                                                  additionalInfo:additionalInfo];
}

+ (A_SCollectionLayoutState *)calculateLayoutWithContext:(A_SCollectionLayoutContext *)context
{
  if (context.elements == nil) {
    return [[A_SCollectionLayoutState alloc] initWithContext:context];
  }

  A_SCollectionLayoutState *layout = [context.layoutDelegateClass calculateLayoutWithContext:context];
  [context.layoutCache setLayout:layout forContext:context];

  // Measure elements in the measure range ahead of time
  CGSize viewportSize = context.viewportSize;
  CGPoint contentOffset = context.initialContentOffset;
  CGRect initialRect = CGRectMake(contentOffset.x, contentOffset.y, viewportSize.width, viewportSize.height);
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(initialRect,
                                                                   kA_SDefaultMeasureRangeTuningParameters,
                                                                   context.scrollableDirections,
                                                                   kA_SStaticScrollDirection);
  // The first call to -layoutAttributesForElementsInRect: will be with a rect that is way bigger than initialRect here.
  // If we only block on initialRect, a few elements that are outside of initialRect but inside measureRect
  // may not be available by the time -layoutAttributesForElementsInRect: is called.
  // Since this method is usually run off main, let's spawn more threads to measure and block on all elements in measureRect.
  [self _measureElementsInRect:measureRect blockingRect:measureRect layout:layout];

  return layout;
}

#pragma mark - UICollectionViewLayout overrides

- (void)prepareLayout
{
  A_SDisplayNodeAssertMainThread();
  [super prepareLayout];

  A_SCollectionLayoutContext *context = [self layoutContextWithElements:_collectionNode.visibleElements];
  if (_layout != nil && A_SObjectIsEqual(_layout.context, context)) {
    // The existing layout is still valid. No-op
    return;
  }

  if (A_SCollectionLayoutState *cachedLayout = [_layoutCache layoutForContext:context]) {
    _layout = cachedLayout;
  } else {
    // A new layout is needed now. Calculate and apply it immediately
    _layout = [A_SCollectionLayout calculateLayoutWithContext:context];
  }
}

- (void)invalidateLayout
{
  A_SDisplayNodeAssertMainThread();
  [super invalidateLayout];
  if (_layout != nil) {
    [_layoutCache removeLayoutForContext:_layout.context];
    _layout = nil;
  }
}

- (CGSize)collectionViewContentSize
{
  A_SDisplayNodeAssertMainThread();
  // The content size can be queried right after a layout invalidation (https://github.com/Tex_tureGroup/Tex_ture/pull/509).
  // In that case, return zero.
  return _layout ? _layout.contentSize : CGSizeZero;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)blockingRect
{
  A_SDisplayNodeAssertMainThread();
  if (CGRectIsEmpty(blockingRect)) {
    return nil;
  }

  // Measure elements in the measure range, block on the requested rect
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(blockingRect,
                                                                   kA_SDefaultMeasureRangeTuningParameters,
                                                                   _layout.context.scrollableDirections,
                                                                   kA_SStaticScrollDirection);
  [A_SCollectionLayout _measureElementsInRect:measureRect blockingRect:blockingRect layout:_layout];
  
  NSArray<UICollectionViewLayoutAttributes *> *result = [_layout layoutAttributesForElementsInRect:blockingRect];

  A_SElementMap *elements = _layout.context.elements;
  for (UICollectionViewLayoutAttributes *attrs in result) {
    A_SCollectionElement *element = [elements elementForLayoutAttributes:attrs];
    A_SCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  }

  return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  A_SDisplayNodeAssertMainThread();

  A_SCollectionElement *element = [_layout.context.elements elementForItemAtIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];

  A_SCellNode *node = element.node;
  CGSize elementSize = attrs.frame.size;
  if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
    [node layoutThatFits:A_SCollectionLayoutElementSizeRangeFromSize(elementSize)];
  }

  A_SCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  A_SCollectionElement *element = [_layout.context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];

  A_SCellNode *node = element.node;
  CGSize elementSize = attrs.frame.size;
  if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
    [node layoutThatFits:A_SCollectionLayoutElementSizeRangeFromSize(elementSize)];
  }

  A_SCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  return attrs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  return (! CGSizeEqualToSize([A_SCollectionLayout _boundsForCollectionNode:_collectionNode], newBounds.size));
}

#pragma mark - Private methods

+ (CGSize)_boundsForCollectionNode:(nonnull A_SCollectionNode *)collectionNode
{
  if (collectionNode == nil) {
    return CGSizeZero;
  }

  if (!collectionNode.isNodeLoaded) {
    // TODO consider calculatedSize as well
    return collectionNode.threadSafeBounds.size;
  }

  A_SDisplayNodeAssertMainThread();
  return collectionNode.view.bounds.size;
}

+ (CGSize)_viewportSizeForCollectionNode:(nonnull A_SCollectionNode *)collectionNode scrollableDirections:(A_SScrollDirection)scrollableDirections
{
  if (collectionNode == nil) {
    return CGSizeZero;
  }

  CGSize result = [A_SCollectionLayout _boundsForCollectionNode:collectionNode];
  // TODO: Consider using adjustedContentInset on iOS 11 and later, to include the safe area of the scroll view
  UIEdgeInsets contentInset = collectionNode.contentInset;
  if (A_SScrollDirectionContainsHorizontalDirection(scrollableDirections)) {
    result.height -= (contentInset.top + contentInset.bottom);
  } else {
    result.width -= (contentInset.left + contentInset.right);
  }
  return result;
}

/**
 * Measures all elements in the specified rect and blocks the calling thread while measuring those in the blocking rect.
 */
+ (void)_measureElementsInRect:(CGRect)rect blockingRect:(CGRect)blockingRect layout:(A_SCollectionLayoutState *)layout
{
  if (CGRectIsEmpty(rect) || layout.context.elements == nil) {
    return;
  }
  BOOL hasBlockingRect = !CGRectIsEmpty(blockingRect);
  if (hasBlockingRect && CGRectContainsRect(rect, blockingRect) == NO) {
    A_SDisplayNodeCAssert(NO, @"Blocking rect, if specified, must be within the other (outer) rect");
    return;
  }

  // Step 1: Clamp the specified rects between the bounds of content rect
  CGSize contentSize = layout.contentSize;
  CGRect contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
  rect = CGRectIntersection(contentRect, rect);
  if (CGRectIsNull(rect)) {
    return;
  }
  if (hasBlockingRect) {
    blockingRect = CGRectIntersection(contentRect, blockingRect);
    hasBlockingRect = !CGRectIsNull(blockingRect);
  }

  // Step 2: Get layout attributes of all elements within the specified outer rect
  A_SPageToLayoutAttributesTable *attrsTable = [layout getAndRemoveUnmeasuredLayoutAttributesPageTableInRect:rect];
  if (attrsTable.count == 0) {
    // No elements in this rect! Bail early
    return;
  }

  // Step 3: Split all those attributes into blocking and non-blocking buckets
  // Use ordered sets here because some items may span multiple pages, and the sets will be accessed by indexes later on.
  A_SCollectionLayoutContext *context = layout.context;
  CGSize pageSize = context.viewportSize;
  NSMutableOrderedSet<UICollectionViewLayoutAttributes *> *blockingAttrs = hasBlockingRect ? [NSMutableOrderedSet orderedSet] : nil;
  NSMutableOrderedSet<UICollectionViewLayoutAttributes *> *nonBlockingAttrs = [NSMutableOrderedSet orderedSet];
  for (id pagePtr in attrsTable) {
    A_SPageCoordinate page = (A_SPageCoordinate)pagePtr;
    NSArray<UICollectionViewLayoutAttributes *> *attrsInPage = [attrsTable objectForPage:page];
    // Calculate the page's rect but only if it's going to be used.
    CGRect pageRect = hasBlockingRect ? A_SPageCoordinateGetPageRect(page, pageSize) : CGRectZero;

    if (hasBlockingRect && CGRectContainsRect(blockingRect, pageRect)) {
      // The page fits well within the blocking rect. All attributes in this page are blocking.
      [blockingAttrs addObjectsFromArray:attrsInPage];
    } else if (hasBlockingRect && CGRectIntersectsRect(blockingRect, pageRect)) {
      // The page intersects the blocking rect. Some elements in this page are blocking, some are not.
      for (UICollectionViewLayoutAttributes *attrs in attrsInPage) {
        if (CGRectIntersectsRect(blockingRect, attrs.frame)) {
          [blockingAttrs addObject:attrs];
        } else {
          [nonBlockingAttrs addObject:attrs];
        }
      }
    } else {
      // The page doesn't intersect the blocking rect. All elements in this page are non-blocking.
      [nonBlockingAttrs addObjectsFromArray:attrsInPage];
    }
  }

  // Step 4: Allocate and measure blocking elements' node
  A_SElementMap *elements = context.elements;
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  if (NSUInteger count = blockingAttrs.count) {
    A_SDispatchApply(count, queue, 0, ^(size_t i) {
      UICollectionViewLayoutAttributes *attrs = blockingAttrs[i];
      A_SCellNode *node = [elements elementForItemAtIndexPath:attrs.indexPath].node;
      CGSize expectedSize = attrs.frame.size;
      if (! CGSizeEqualToSize(expectedSize, node.calculatedSize)) {
        [node layoutThatFits:A_SCollectionLayoutElementSizeRangeFromSize(expectedSize)];
      }
    });
  }

  // Step 5: Allocate and measure non-blocking ones
  if (NSUInteger count = nonBlockingAttrs.count) {
    __weak A_SElementMap *weakElements = elements;
    A_SDispatchAsync(count, queue, 0, ^(size_t i) {
      __strong A_SElementMap *strongElements = weakElements;
      if (strongElements) {
        UICollectionViewLayoutAttributes *attrs = nonBlockingAttrs[i];
        A_SCellNode *node = [elements elementForItemAtIndexPath:attrs.indexPath].node;
        CGSize expectedSize = attrs.frame.size;
        if (! CGSizeEqualToSize(expectedSize, node.calculatedSize)) {
          [node layoutThatFits:A_SCollectionLayoutElementSizeRangeFromSize(expectedSize)];
        }
      }
    });
  }
}

# pragma mark - Convenient inline functions

A_SDISPLAYNODE_INLINE A_SSizeRange A_SCollectionLayoutElementSizeRangeFromSize(CGSize size)
{
  // The layout delegate consulted us that this element must fit within this size,
  // and the only way to achieve that without asking it again is to use an exact size range here.
  return A_SSizeRangeMake(size);
}

A_SDISPLAYNODE_INLINE void A_SCollectionLayoutSetSizeToElement(CGSize size, A_SCollectionElement *element)
{
  if (A_SCellNode *node = element.node) {
    if (! CGSizeEqualToSize(size, node.frame.size)) {
      CGRect frame = CGRectZero;
      frame.size = size;
      node.frame = frame;
    }
  }
}

@end
