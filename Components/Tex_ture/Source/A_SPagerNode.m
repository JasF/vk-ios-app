//
//  A_SPagerNode.m
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

#import <Async_DisplayKit/A_SPagerNode.h>
#import <Async_DisplayKit/A_SPagerNode+Beta.h>

#import <Async_DisplayKit/A_SCollectionGalleryLayoutDelegate.h>
#import <Async_DisplayKit/A_SCollectionNode+Beta.h>
#import <Async_DisplayKit/A_SDelegateProxy.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SPagerFlowLayout.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SCollectionView+Undeprecated.h>
#import <Async_DisplayKit/UIResponder+Async_DisplayKit.h>

@interface A_SPagerNode () <A_SCollectionDataSource, A_SCollectionDelegate, A_SCollectionDelegateFlowLayout, A_SDelegateProxyInterceptor, A_SCollectionGalleryLayoutPropertiesProviding>
{
  __weak id <A_SPagerDataSource> _pagerDataSource;
  A_SPagerNodeProxy *_proxyDataSource;
  struct {
    unsigned nodeBlockAtIndex:1;
    unsigned nodeAtIndex:1;
  } _pagerDataSourceFlags;

  __weak id <A_SPagerDelegate> _pagerDelegate;
  A_SPagerNodeProxy *_proxyDelegate;
}

@end

@implementation A_SPagerNode

@dynamic view, delegate, dataSource;

#pragma mark - Lifecycle

- (instancetype)init
{
  A_SPagerFlowLayout *flowLayout = [[A_SPagerFlowLayout alloc] init];
  flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  flowLayout.minimumInteritemSpacing = 0;
  flowLayout.minimumLineSpacing = 0;
  
  return [self initWithCollectionViewLayout:flowLayout];
}

- (instancetype)initWithCollectionViewLayout:(A_SPagerFlowLayout *)flowLayout;
{
  A_SDisplayNodeAssert([flowLayout isKindOfClass:[A_SPagerFlowLayout class]], @"A_SPagerNode requires a flow layout.");
  A_SDisplayNodeAssertTrue(flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal);
  self = [super initWithCollectionViewLayout:flowLayout];
  return self;
}

- (instancetype)initUsingAsyncCollectionLayout
{
  A_SCollectionGalleryLayoutDelegate *layoutDelegate = [[A_SCollectionGalleryLayoutDelegate alloc] initWithScrollableDirections:A_SScrollDirectionHorizontalDirections];
  self = [super initWithLayoutDelegate:layoutDelegate layoutFacilitator:nil];
  if (self) {
    layoutDelegate.propertiesProvider = self;
  }
  return self;
}

#pragma mark - A_SDisplayNode

- (void)didLoad
{
  [super didLoad];
  
  A_SCollectionView *cv = self.view;
  cv.asyncDataSource = (id<A_SCollectionDataSource>)_proxyDataSource ?: self;
  cv.asyncDelegate = (id<A_SCollectionDelegate>)_proxyDelegate ?: self;
#if TARGET_OS_IOS
  cv.pagingEnabled = YES;
  cv.scrollsToTop = NO;
#endif
  cv.allowsSelection = NO;
  cv.showsVerticalScrollIndicator = NO;
  cv.showsHorizontalScrollIndicator = NO;

  A_SRangeTuningParameters minimumRenderParams = { .leadingBufferScreenfuls = 0.0, .trailingBufferScreenfuls = 0.0 };
  A_SRangeTuningParameters minimumPreloadParams = { .leadingBufferScreenfuls = 1.0, .trailingBufferScreenfuls = 1.0 };
  [self setTuningParameters:minimumRenderParams forRangeMode:A_SLayoutRangeModeMinimum rangeType:A_SLayoutRangeTypeDisplay];
  [self setTuningParameters:minimumPreloadParams forRangeMode:A_SLayoutRangeModeMinimum rangeType:A_SLayoutRangeTypePreload];
  
  A_SRangeTuningParameters fullRenderParams = { .leadingBufferScreenfuls = 1.0, .trailingBufferScreenfuls = 1.0 };
  A_SRangeTuningParameters fullPreloadParams = { .leadingBufferScreenfuls = 2.0, .trailingBufferScreenfuls = 2.0 };
  [self setTuningParameters:fullRenderParams forRangeMode:A_SLayoutRangeModeFull rangeType:A_SLayoutRangeTypeDisplay];
  [self setTuningParameters:fullPreloadParams forRangeMode:A_SLayoutRangeModeFull rangeType:A_SLayoutRangeTypePreload];
}

#pragma mark - Getters / Setters

- (NSInteger)currentPageIndex
{
  return (self.view.contentOffset.x / [self pageSize].width);
}

- (CGSize)pageSize
{
  UIEdgeInsets contentInset = self.contentInset;
  CGSize pageSize = self.bounds.size;
  pageSize.height -= (contentInset.top + contentInset.bottom);
  return pageSize;
}

#pragma mark - Helpers

- (void)scrollToPageAtIndex:(NSInteger)index animated:(BOOL)animated
{
  NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
  [self scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionLeft animated:animated];
}

- (A_SCellNode *)nodeForPageAtIndex:(NSInteger)index
{
  return [self nodeForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

- (NSInteger)indexOfPageWithNode:(A_SCellNode *)node
{
  NSIndexPath *indexPath = [self indexPathForNode:node];
  if (!indexPath) {
    return NSNotFound;
  }
  return indexPath.row;
}

#pragma mark - A_SCollectionGalleryLayoutPropertiesProviding

- (CGSize)galleryLayoutDelegate:(nonnull A_SCollectionGalleryLayoutDelegate *)delegate sizeForElements:(nonnull A_SElementMap *)elements
{
  A_SDisplayNodeAssertMainThread();
  return [self pageSize];
}

#pragma mark - A_SCollectionDataSource

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_pagerDataSourceFlags.nodeBlockAtIndex) {
    return [_pagerDataSource pagerNode:self nodeBlockAtIndex:indexPath.item];
  } else if (_pagerDataSourceFlags.nodeAtIndex) {
    A_SCellNode *node = [_pagerDataSource pagerNode:self nodeAtIndex:indexPath.item];
    return ^{ return node; };
  } else {
    A_SDisplayNodeFailAssert(@"Pager data source must implement either %@ or %@. Data source: %@", NSStringFromSelector(@selector(pagerNode:nodeBlockAtIndex:)), NSStringFromSelector(@selector(pagerNode:nodeAtIndex:)), _pagerDataSource);
    return ^{
      return [[A_SCellNode alloc] init];
    };
  }
}

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  A_SDisplayNodeAssert(_pagerDataSource != nil, @"A_SPagerNode must have a data source to load nodes to display");
  return [_pagerDataSource numberOfPagesInPagerNode:self];
}

#pragma mark - A_SCollectionDelegate

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return A_SSizeRangeMake([self pageSize]);
}

#pragma mark - Data Source Proxy

- (id <A_SPagerDataSource>)dataSource
{
  return _pagerDataSource;
}

- (void)setDataSource:(id <A_SPagerDataSource>)dataSource
{
  if (dataSource != _pagerDataSource) {
    _pagerDataSource = dataSource;
    
    if (dataSource == nil) {
      memset(&_pagerDataSourceFlags, 0, sizeof(_pagerDataSourceFlags));
    } else {
      _pagerDataSourceFlags.nodeBlockAtIndex = [_pagerDataSource respondsToSelector:@selector(pagerNode:nodeBlockAtIndex:)];
      _pagerDataSourceFlags.nodeAtIndex = [_pagerDataSource respondsToSelector:@selector(pagerNode:nodeAtIndex:)];
    }
    
    _proxyDataSource = dataSource ? [[A_SPagerNodeProxy alloc] initWithTarget:dataSource interceptor:self] : nil;
    
    super.dataSource = (id <A_SCollectionDataSource>)_proxyDataSource;
  }
}

- (void)setDelegate:(id<A_SPagerDelegate>)delegate
{
  if (delegate != _pagerDelegate) {
    _pagerDelegate = delegate;
    _proxyDelegate = delegate ? [[A_SPagerNodeProxy alloc] initWithTarget:delegate interceptor:self] : nil;
    super.delegate = (id <A_SCollectionDelegate>)_proxyDelegate;
  }
}

- (void)proxyTargetHasDeallocated:(A_SDelegateProxy *)proxy
{
  [self setDataSource:nil];
  [self setDelegate:nil];
}

- (void)didEnterVisibleState
{
	[super didEnterVisibleState];

	// Check that our view controller does not automatically set our content insets
	// It would be better to have a -didEnterHierarchy hook to put this in, but
	// such a hook doesn't currently exist, and in every use case I can imagine,
	// the pager is not hosted inside a range-managed node.
	if (_allowsAutomaticInsetsAdjustment == NO) {
		UIViewController *vc = [self.view asdk_associatedViewController];
		if (vc.automaticallyAdjustsScrollViewInsets) {
			NSLog(@"Async_DisplayKit: A_SPagerNode is setting automaticallyAdjustsScrollViewInsets=NO on its owning view controller %@. This automatic behavior will be disabled in the future. Set allowsAutomaticInsetsAdjustment=YES on the pager node to suppress this behavior.", vc);
			vc.automaticallyAdjustsScrollViewInsets = NO;
		}
	}
}

@end
