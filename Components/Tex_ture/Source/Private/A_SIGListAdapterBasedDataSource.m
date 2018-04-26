//
//  A_SIGListAdapterBasedDataSource.m
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

#import <Async_DisplayKit/A_SAvailability.h>

#if A_S_IG_LIST_KIT

#import "A_SIGListAdapterBasedDataSource.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <objc/runtime.h>

typedef IGListSectionController<A_SSectionController> A_SIGSectionController;

/// The optional methods that a class implements from A_SSectionController.
/// Note: Bitfields are not supported by NSValue so we can't use them.
typedef struct {
  BOOL sizeRangeForItem;
  BOOL shouldBatchFetch;
  BOOL beginBatchFetchWithContext;
} A_SSectionControllerOverrides;

/// The optional methods that a class implements from A_SSupplementaryNodeSource.
/// Note: Bitfields are not supported by NSValue so we can't use them.
typedef struct {
  BOOL sizeRangeForSupplementary;
} A_SSupplementarySourceOverrides;

@protocol A_SIGSupplementaryNodeSource <IGListSupplementaryViewSource, A_SSupplementaryNodeSource>
@end

@interface A_SIGListAdapterBasedDataSource ()
@property (nonatomic, weak, readonly) IGListAdapter *listAdapter;
@property (nonatomic, readonly) id<UICollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, readonly) id<UICollectionViewDataSource> dataSource;

/**
 * The section controller that we will forward beginBatchFetchWithContext: to.
 * Since shouldBatchFetch: is called on main, we capture the last section controller in there,
 * and then we use it and clear it in beginBatchFetchWithContext: (on default queue).
 *
 * It is safe to use it without a lock in this limited way, since those two methods will
 * never execute in parallel.
 */
@property (nonatomic, weak) A_SIGSectionController *sectionControllerForBatchFetching;
@end

@implementation A_SIGListAdapterBasedDataSource

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter
{
  if (self = [super init]) {
#if IG_LIST_COLLECTION_VIEW
    [A_SIGListAdapterBasedDataSource setA_SCollectionViewSuperclass];
#endif
    [A_SIGListAdapterBasedDataSource configureUpdater:listAdapter.updater];

    A_SDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDataSource)], @"Expected IGListAdapter to conform to UICollectionViewDataSource.");
    A_SDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)], @"Expected IGListAdapter to conform to UICollectionViewDelegateFlowLayout.");
    _listAdapter = listAdapter;
  }
  return self;
}

- (id<UICollectionViewDataSource>)dataSource
{
  return (id<UICollectionViewDataSource>)_listAdapter;
}

- (id<UICollectionViewDelegateFlowLayout>)delegate
{
  return (id<UICollectionViewDelegateFlowLayout>)_listAdapter;
}

#pragma mark - A_SCollectionDelegate

- (void)collectionNode:(A_SCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didSelectItemAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [self.delegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [self.delegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (BOOL)shouldBatchFetchForCollectionNode:(A_SCollectionNode *)collectionNode
{
  NSInteger sectionCount = [self numberOfSectionsInCollectionNode:collectionNode];
  if (sectionCount == 0) {
    return NO;
  }

  // If they implement shouldBatchFetch, call it. Otherwise, just say YES if they implement beginBatchFetch.
  A_SIGSectionController *ctrl = [self sectionControllerForSection:sectionCount - 1];
  A_SSectionControllerOverrides o = [A_SIGListAdapterBasedDataSource overridesForSectionControllerClass:ctrl.class];
  BOOL result = (o.shouldBatchFetch ? [ctrl shouldBatchFetch] : o.beginBatchFetchWithContext);
  if (result) {
    self.sectionControllerForBatchFetching = ctrl;
  }
  return result;
}

- (void)collectionNode:(A_SCollectionNode *)collectionNode willBeginBatchFetchWithContext:(A_SBatchContext *)context
{
  A_SIGSectionController *ctrl = self.sectionControllerForBatchFetching;
  self.sectionControllerForBatchFetching = nil;
  [ctrl beginBatchFetchWithContext:context];
}

/**
 * Note: It is not documented that A_SCollectionNode will forward these UIKit delegate calls if they are implemented.
 * It is not considered harmful to do so, and adding them to documentation will confuse most users, who should
 * instead using the A_SCollectionDelegate callbacks.
 */
#pragma mark - A_SCollectionDelegateInterop

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
}

#pragma mark - A_SCollectionDelegateFlowLayout

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
  id<A_SIGSupplementaryNodeSource> src = [self supplementaryElementSourceForSection:section];
  if ([A_SIGListAdapterBasedDataSource overridesForSupplementarySourceClass:[src class]].sizeRangeForSupplementary) {
    return [src sizeRangeForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndex:0];
  } else {
    return A_SSizeRangeZero;
  }
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
  id<A_SIGSupplementaryNodeSource> src = [self supplementaryElementSourceForSection:section];
  if ([A_SIGListAdapterBasedDataSource overridesForSupplementarySourceClass:[src class]].sizeRangeForSupplementary) {
    return [src sizeRangeForSupplementaryElementOfKind:UICollectionElementKindSectionFooter atIndex:0];
  } else {
    return A_SSizeRangeZero;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

#pragma mark - A_SCollectionDataSource

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return [self.dataSource collectionView:collectionNode.view numberOfItemsInSection:section];
}

- (NSInteger)numberOfSectionsInCollectionNode:(A_SCollectionNode *)collectionNode
{
  return [self.dataSource numberOfSectionsInCollectionView:collectionNode.view];
}

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[self sectionControllerForSection:indexPath.section] nodeBlockForItemAtIndex:indexPath.item];
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  A_SIGSectionController *ctrl = [self sectionControllerForSection:indexPath.section];
  if ([A_SIGListAdapterBasedDataSource overridesForSectionControllerClass:ctrl.class].sizeRangeForItem) {
    return [ctrl sizeRangeForItemAtIndex:indexPath.item];
  } else {
    return A_SSizeRangeUnconstrained;
  }
}

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  return [[self supplementaryElementSourceForSection:indexPath.section] nodeBlockForSupplementaryElementOfKind:kind atIndex:indexPath.item];
}

- (NSArray<NSString *> *)collectionNode:(A_SCollectionNode *)collectionNode supplementaryElementKindsInSection:(NSInteger)section
{
  return [[self supplementaryElementSourceForSection:section] supportedElementKinds];
}

#pragma mark - A_SCollectionDataSourceInterop

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  return [self.dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  return [self.dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

+ (BOOL)dequeuesCellsForNodeBackedItems
{
  return YES;
}

#pragma mark - Helpers

- (id<A_SIGSupplementaryNodeSource>)supplementaryElementSourceForSection:(NSInteger)section
{
  A_SIGSectionController *ctrl = [self sectionControllerForSection:section];
  id<A_SIGSupplementaryNodeSource> src = (id<A_SIGSupplementaryNodeSource>)ctrl.supplementaryViewSource;
  A_SDisplayNodeAssert(src == nil || [src conformsToProtocol:@protocol(A_SSupplementaryNodeSource)], @"Supplementary view source should conform to %@", NSStringFromProtocol(@protocol(A_SSupplementaryNodeSource)));
  return src;
}

- (A_SIGSectionController *)sectionControllerForSection:(NSInteger)section
{
  id object = [_listAdapter objectAtSection:section];
  A_SIGSectionController *ctrl = (A_SIGSectionController *)[_listAdapter sectionControllerForObject:object];
  A_SDisplayNodeAssert([ctrl conformsToProtocol:@protocol(A_SSectionController)], @"Expected section controller to conform to %@. Controller: %@", NSStringFromProtocol(@protocol(A_SSectionController)), ctrl);
  return ctrl;
}

/// If needed, set A_SCollectionView's superclass to IGListCollectionView (IGListKit < 3.0).
#if IG_LIST_COLLECTION_VIEW
+ (void)setA_SCollectionViewSuperclass
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    class_setSuperclass([A_SCollectionView class], [IGListCollectionView class]);
  });
#pragma clang diagnostic pop
}
#endif

/// Ensure updater won't call reloadData on us.
+ (void)configureUpdater:(id<IGListUpdatingDelegate>)updater
{
  // Cast to NSObject will be removed after https://github.com/Instagram/IGListKit/pull/435
  if ([(id<NSObject>)updater isKindOfClass:[IGListAdapterUpdater class]]) {
    [(IGListAdapterUpdater *)updater setAllowsBackgroundReloading:NO];
  } else {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSLog(@"WARNING: Use of non-%@ updater with Async_DisplayKit is discouraged. Updater: %@", NSStringFromClass([IGListAdapterUpdater class]), updater);
    });
  }
}

+ (A_SSupplementarySourceOverrides)overridesForSupplementarySourceClass:(Class)c
{
  static NSCache<Class, NSValue *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSValue *obj = [cache objectForKey:c];
  A_SSupplementarySourceOverrides o;
  if (obj == nil) {
    o.sizeRangeForSupplementary = [c instancesRespondToSelector:@selector(sizeRangeForSupplementaryElementOfKind:atIndex:)];
    obj = [NSValue valueWithBytes:&o objCType:@encode(A_SSupplementarySourceOverrides)];
    [cache setObject:obj forKey:c];
  } else {
    [obj getValue:&o];
  }
  return o;
}

+ (A_SSectionControllerOverrides)overridesForSectionControllerClass:(Class)c
{
  static NSCache<Class, NSValue *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSValue *obj = [cache objectForKey:c];
  A_SSectionControllerOverrides o;
  if (obj == nil) {
    o.sizeRangeForItem = [c instancesRespondToSelector:@selector(sizeRangeForItemAtIndex:)];
    o.beginBatchFetchWithContext = [c instancesRespondToSelector:@selector(beginBatchFetchWithContext:)];
    o.shouldBatchFetch = [c instancesRespondToSelector:@selector(shouldBatchFetch)];
    obj = [NSValue valueWithBytes:&o objCType:@encode(A_SSectionControllerOverrides)];
    [cache setObject:obj forKey:c];
  } else {
    [obj getValue:&o];
  }
  return o;
}

@end

#endif // A_S_IG_LIST_KIT
