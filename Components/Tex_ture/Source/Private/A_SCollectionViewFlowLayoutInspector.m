//
//  A_SCollectionViewFlowLayoutInspector.m
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

#import <Async_DisplayKit/A_SCollectionViewFlowLayoutInspector.h>
#import <Async_DisplayKit/A_SCollectionView.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/A_SCollectionNode.h>

#define kDefaultItemSize CGSizeMake(50, 50)

#pragma mark - A_SCollectionViewFlowLayoutInspector

@interface A_SCollectionViewFlowLayoutInspector ()
@property (nonatomic, weak) UICollectionViewFlowLayout *layout;
@end
 
@implementation A_SCollectionViewFlowLayoutInspector {
  struct {
    unsigned int implementsSizeRangeForHeader:1;
    unsigned int implementsReferenceSizeForHeader:1;
    unsigned int implementsSizeRangeForFooter:1;
    unsigned int implementsReferenceSizeForFooter:1;
    unsigned int implementsConstrainedSizeForNodeAtIndexPathDeprecated:1;
    unsigned int implementsConstrainedSizeForItemAtIndexPath:1;
  } _delegateFlags;
}

#pragma mark Lifecycle

- (instancetype)initWithFlowLayout:(UICollectionViewFlowLayout *)flowLayout;
{
  NSParameterAssert(flowLayout);
  
  self = [super init];
  if (self != nil) {
    _layout = flowLayout;
  }
  return self;
}

#pragma mark A_SCollectionViewLayoutInspecting

- (void)didChangeCollectionViewDelegate:(id<A_SCollectionDelegate>)delegate;
{
  if (delegate == nil) {
    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
  } else {
    _delegateFlags.implementsSizeRangeForHeader = [delegate respondsToSelector:@selector(collectionNode:sizeRangeForHeaderInSection:)];
    _delegateFlags.implementsReferenceSizeForHeader = [delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)];
    _delegateFlags.implementsSizeRangeForFooter = [delegate respondsToSelector:@selector(collectionNode:sizeRangeForFooterInSection:)];
    _delegateFlags.implementsReferenceSizeForFooter = [delegate respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)];
    _delegateFlags.implementsConstrainedSizeForNodeAtIndexPathDeprecated = [delegate respondsToSelector:@selector(collectionView:constrainedSizeForNodeAtIndexPath:)];
    _delegateFlags.implementsConstrainedSizeForItemAtIndexPath = [delegate respondsToSelector:@selector(collectionNode:constrainedSizeForItemAtIndexPath:)];
  }
}

- (A_SSizeRange)collectionView:(A_SCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  A_SSizeRange result = A_SSizeRangeUnconstrained;
  if (_delegateFlags.implementsConstrainedSizeForItemAtIndexPath) {
    result = [collectionView.asyncDelegate collectionNode:collectionView.collectionNode constrainedSizeForItemAtIndexPath:indexPath];
  } else if (_delegateFlags.implementsConstrainedSizeForNodeAtIndexPathDeprecated) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    result = [collectionView.asyncDelegate collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath];
#pragma clang diagnostic pop
  } else {
    // With 2.0 `collectionView:constrainedSizeForNodeAtIndexPath:` was moved to the delegate. Assert if not implemented on the delegate but on the data source
    A_SDisplayNodeAssert([collectionView.asyncDataSource respondsToSelector:@selector(collectionView:constrainedSizeForNodeAtIndexPath:)] == NO, @"collectionView:constrainedSizeForNodeAtIndexPath: was moved from the A_SCollectionDataSource to the A_SCollectionDelegate.");
  }

  // If we got no size range:
  if (A_SSizeRangeEqualToSizeRange(result, A_SSizeRangeUnconstrained)) {
    // Use itemSize if they set it.
    CGSize itemSize = _layout.itemSize;
    if (CGSizeEqualToSize(itemSize, kDefaultItemSize) == NO) {
      result = A_SSizeRangeMake(itemSize, itemSize);
    } else {
      // Compute constraint from scroll direction otherwise.
      result = NodeConstrainedSizeForScrollDirection(collectionView);
    }
  }
  
  return result;
}

- (A_SSizeRange)collectionView:(A_SCollectionView *)collectionView constrainedSizeForSupplementaryNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  A_SSizeRange result = A_SSizeRangeZero;
  if (A_SObjectIsEqual(kind, UICollectionElementKindSectionHeader)) {
    if (_delegateFlags.implementsSizeRangeForHeader) {
      result = [[self delegateForCollectionView:collectionView] collectionNode:collectionView.collectionNode sizeRangeForHeaderInSection:indexPath.section];
    } else if (_delegateFlags.implementsReferenceSizeForHeader) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      CGSize exactSize = [[self delegateForCollectionView:collectionView] collectionView:collectionView layout:_layout referenceSizeForHeaderInSection:indexPath.section];
#pragma clang diagnostic pop
      result = A_SSizeRangeMake(exactSize);
    } else {
      result = A_SSizeRangeMake(_layout.headerReferenceSize);
    }
  } else if (A_SObjectIsEqual(kind, UICollectionElementKindSectionFooter)) {
    if (_delegateFlags.implementsSizeRangeForFooter) {
      result = [[self delegateForCollectionView:collectionView] collectionNode:collectionView.collectionNode sizeRangeForFooterInSection:indexPath.section];
    } else if (_delegateFlags.implementsReferenceSizeForFooter) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      CGSize exactSize = [[self delegateForCollectionView:collectionView] collectionView:collectionView layout:_layout referenceSizeForFooterInSection:indexPath.section];
#pragma clang diagnostic pop
      result = A_SSizeRangeMake(exactSize);
    } else {
      result = A_SSizeRangeMake(_layout.footerReferenceSize);
    }
  } else {
    A_SDisplayNodeFailAssert(@"Unexpected supplementary kind: %@", kind);
    return A_SSizeRangeZero;
  }

  if (_layout.scrollDirection == UICollectionViewScrollDirectionVertical) {
    result.min.width = result.max.width = CGRectGetWidth(collectionView.bounds);
  } else {
    result.min.height = result.max.height = CGRectGetHeight(collectionView.bounds);
  }
  return result;
}

- (NSUInteger)collectionView:(A_SCollectionView *)collectionView supplementaryNodesOfKind:(NSString *)kind inSection:(NSUInteger)section
{
  A_SSizeRange constraint = [self collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:kind atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
  if (_layout.scrollDirection == UICollectionViewScrollDirectionVertical) {
    return (constraint.max.height > 0 ? 1 : 0);
  } else {
    return (constraint.max.width > 0 ? 1 : 0);
  }
}

- (A_SScrollDirection)scrollableDirections
{
  return (self.layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) ? A_SScrollDirectionHorizontalDirections : A_SScrollDirectionVerticalDirections;
}

#pragma mark - Private helpers

- (id<A_SCollectionDelegateFlowLayout>)delegateForCollectionView:(A_SCollectionView *)collectionView
{
  return (id<A_SCollectionDelegateFlowLayout>)collectionView.asyncDelegate;
}

@end
