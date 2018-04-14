//
//  A_SCollectionViewLayoutController.m
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

#import <Async_DisplayKit/A_SCollectionViewLayoutController.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/CoreGraphics+A_SConvenience.h>
#import <Async_DisplayKit/UICollectionViewLayout+A_SConvenience.h>

struct A_SRangeGeometry {
  CGRect rangeBounds;
  CGRect updateBounds;
};
typedef struct A_SRangeGeometry A_SRangeGeometry;


#pragma mark -
#pragma mark A_SCollectionViewLayoutController

@interface A_SCollectionViewLayoutController ()
{
  @package
  A_SCollectionView * __weak _collectionView;
  UICollectionViewLayout * __strong _collectionViewLayout;
}
@end

@implementation A_SCollectionViewLayoutController

- (instancetype)initWithCollectionView:(A_SCollectionView *)collectionView
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _collectionView = collectionView;
  _collectionViewLayout = [collectionView collectionViewLayout];
  return self;
}

- (NSHashTable<A_SCollectionElement *> *)elementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType map:(A_SElementMap *)map
{
  A_SRangeTuningParameters tuningParameters = [self tuningParametersForRangeMode:rangeMode rangeType:rangeType];
  CGRect rangeBounds = [self rangeBoundsWithScrollDirection:scrollDirection rangeTuningParameters:tuningParameters];
  return [self elementsWithinRangeBounds:rangeBounds map:map];
}

- (void)allElementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode displaySet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)displaySet preloadSet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)preloadSet map:(A_SElementMap *)map
{
  if (displaySet == NULL || preloadSet == NULL) {
    return;
  }
  
  A_SRangeTuningParameters displayParams = [self tuningParametersForRangeMode:rangeMode rangeType:A_SLayoutRangeTypeDisplay];
  A_SRangeTuningParameters preloadParams = [self tuningParametersForRangeMode:rangeMode rangeType:A_SLayoutRangeTypePreload];
  CGRect displayBounds = [self rangeBoundsWithScrollDirection:scrollDirection rangeTuningParameters:displayParams];
  CGRect preloadBounds = [self rangeBoundsWithScrollDirection:scrollDirection rangeTuningParameters:preloadParams];
  
  CGRect unionBounds = CGRectUnion(displayBounds, preloadBounds);
  NSArray *layoutAttributes = [_collectionViewLayout layoutAttributesForElementsInRect:unionBounds];
  NSInteger count = layoutAttributes.count;

  __auto_type display = [[NSHashTable<A_SCollectionElement *> alloc] initWithOptions:NSHashTableObjectPointerPersonality capacity:count];
  __auto_type preload = [[NSHashTable<A_SCollectionElement *> alloc] initWithOptions:NSHashTableObjectPointerPersonality capacity:count];

  for (UICollectionViewLayoutAttributes *la in layoutAttributes) {
    // Manually filter out elements that don't intersect the range bounds.
    // See comment in elementsForItemsWithinRangeBounds:
    // This is re-implemented here so that the iteration over layoutAttributes can be done once to check both ranges.
    CGRect frame = la.frame;
    BOOL intersectsDisplay = CGRectIntersectsRect(displayBounds, frame);
    BOOL intersectsPreload = CGRectIntersectsRect(preloadBounds, frame);
    if (intersectsDisplay == NO && intersectsPreload == NO && CATransform3DIsIdentity(la.transform3D) == YES) {
      // Questionable why the element would be included here, but it doesn't belong.
      continue;
    }
    
    // Avoid excessive retains and releases, as well as property calls. We know the element is kept alive by map.
    __unsafe_unretained A_SCollectionElement *e = [map elementForLayoutAttributes:la];
    if (e != nil && intersectsDisplay) {
      [display addObject:e];
    }
    if (e != nil && intersectsPreload) {
      [preload addObject:e];
    }
  }

  *displaySet = display;
  *preloadSet = preload;
  return;
}

- (NSHashTable<A_SCollectionElement *> *)elementsWithinRangeBounds:(CGRect)rangeBounds map:(A_SElementMap *)map
{
  NSArray *layoutAttributes = [_collectionViewLayout layoutAttributesForElementsInRect:rangeBounds];
  NSHashTable<A_SCollectionElement *> *elementSet = [[NSHashTable alloc] initWithOptions:NSHashTableObjectPointerPersonality capacity:layoutAttributes.count];
  
  for (UICollectionViewLayoutAttributes *la in layoutAttributes) {
    // Manually filter out elements that don't intersect the range bounds.
    // If a layout returns elements outside the requested rect this can be a huge problem.
    // For instance in a paging flow, you may only want to preload 3 pages (one center, one on each side)
    // but if flow layout includes the 4th page (which it does! as of iOS 9&10), you will preload a 4th
    // page as well.
    if (CATransform3DIsIdentity(la.transform3D) && CGRectIntersectsRect(la.frame, rangeBounds) == NO) {
      continue;
    }
    [elementSet addObject:[map elementForLayoutAttributes:la]];
  }

  return elementSet;
}

- (CGRect)rangeBoundsWithScrollDirection:(A_SScrollDirection)scrollDirection
                   rangeTuningParameters:(A_SRangeTuningParameters)tuningParameters
{
  CGRect rect = _collectionView.bounds;
  
  return CGRectExpandToRangeWithScrollableDirections(rect, tuningParameters, [_collectionView scrollableDirections], scrollDirection);
}

@end
