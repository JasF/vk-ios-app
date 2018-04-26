//
//  ViewController.m
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

#import "ViewController.h"

#import <Async_DisplayKit/Async_DisplayKit.h>
#import "ItemNode.h"
#import "BlurbNode.h"
#import "LoadingNode.h"

static const NSTimeInterval kWebResponseDelay = 1.0;
static const BOOL kSimulateWebResponse = YES;
static const NSInteger kBatchSize = 20;

static const CGFloat kHorizontalSectionPadding = 10.0f;

@interface ViewController () <A_SCollectionDataSource, A_SCollectionDelegate, A_SCollectionDelegateFlowLayout>
{
  A_SCollectionNode *_collectionNode;
  NSMutableArray *_data;
}

@end


@implementation ViewController

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init
{
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  _collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];

  self = [super initWithNode:_collectionNode];
  
  if (self) {
    
    self.title = @"Cat Deals";
  
    _collectionNode.dataSource = self;
    _collectionNode.delegate = self;
    _collectionNode.backgroundColor = [UIColor grayColor];
    _collectionNode.accessibilityIdentifier = @"Cat deals list";
    
    A_SRangeTuningParameters preloadTuning;
    preloadTuning.leadingBufferScreenfuls = 2;
    preloadTuning.trailingBufferScreenfuls = 1;
    [_collectionNode setTuningParameters:preloadTuning forRangeType:A_SLayoutRangeTypePreload];
    
    A_SRangeTuningParameters displayTuning;
    displayTuning.leadingBufferScreenfuls = 1;
    displayTuning.trailingBufferScreenfuls = 0.5;
    [_collectionNode setTuningParameters:displayTuning forRangeType:A_SLayoutRangeTypeDisplay];
    
    [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionHeader];
    [_collectionNode registerSupplementaryNodeOfKind:UICollectionElementKindSectionFooter];
    
    _data = [[NSMutableArray alloc] init];
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadTapped)];
  }
  
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // set any collectionView properties here (once the node's backing view is loaded)
  _collectionNode.leadingScreensForBatching = 2;
  [self fetchMoreCatsWithCompletion:nil];
}

- (void)fetchMoreCatsWithCompletion:(void (^)(BOOL))completion {
  if (kSimulateWebResponse) {
    __weak typeof(self) weakSelf = self;
    void(^mockWebService)() = ^{
      NSLog(@"ViewController \"got data from a web service\"");
      ViewController *strongSelf = weakSelf;
      if (strongSelf != nil)
      {
        [strongSelf appendMoreItems:kBatchSize completion:completion];
      }
      else {
        NSLog(@"ViewController is nil - won't update collection");
      }
    };
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kWebResponseDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), mockWebService);
  } else {
    [self appendMoreItems:kBatchSize completion:completion];
  }
}

- (void)appendMoreItems:(NSInteger)numberOfNewItems completion:(void (^)(BOOL))completion {
  NSArray *newData = [self getMoreData:numberOfNewItems];
  [_collectionNode performBatchAnimated:YES updates:^{
    [_data addObjectsFromArray:newData];
    NSArray *addedIndexPaths = [self indexPathsForObjects:newData];
    [_collectionNode insertItemsAtIndexPaths:addedIndexPaths];
  } completion:completion];
}

- (NSArray *)getMoreData:(NSInteger)count {
  NSMutableArray *data = [NSMutableArray array];
  for (int i = 0; i < count; i++) {
    [data addObject:[ItemViewModel randomItem]];
  }
  return data;
}

- (NSArray *)indexPathsForObjects:(NSArray *)data {
  NSMutableArray *indexPaths = [NSMutableArray array];
  NSInteger section = 0;
  for (ItemViewModel *viewModel in data) {
    NSInteger item = [_data indexOfObject:viewModel];
    NSAssert(item < [_data count] && item != NSNotFound, @"Item should be in _data");
    [indexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
  }
  return indexPaths;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
  [_collectionNode.view.collectionViewLayout invalidateLayout];
}

- (void)reloadTapped
{
  [_collectionNode reloadData];
}

#pragma mark - A_SCollectionNodeDelegate / A_SCollectionNodeDataSource

- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ItemViewModel *viewModel = _data[indexPath.item];
  return ^{
    return [[ItemNode alloc] initWithViewModel:viewModel];
  };
}

- (A_SCellNode *)collectionNode:(A_SCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if ([kind isEqualToString:UICollectionElementKindSectionHeader] && indexPath.section == 0) {
    return [[BlurbNode alloc] init];
  } else if ([kind isEqualToString:UICollectionElementKindSectionFooter] && indexPath.section == 0) {
    return [[LoadingNode alloc] init];
  }
  return nil;
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  CGFloat collectionViewWidth = CGRectGetWidth(self.view.frame) - 2 * kHorizontalSectionPadding;
  CGFloat oneItemWidth = [ItemNode preferredViewSize].width;
  NSInteger numColumns = floor(collectionViewWidth / oneItemWidth);
  // Number of columns should be at least 1
  numColumns = MAX(1, numColumns);
  
  CGFloat totalSpaceBetweenColumns = (numColumns - 1) * kHorizontalSectionPadding;
  CGFloat itemWidth = ((collectionViewWidth - totalSpaceBetweenColumns) / numColumns);
  CGSize itemSize = [ItemNode sizeForWidth:itemWidth];
  return A_SSizeRangeMake(itemSize, itemSize);
}

- (NSInteger)collectionNode:(A_SCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return [_data count];
}

- (NSInteger)numberOfSectionsInCollectionNode:(A_SCollectionNode *)collectionNode
{
  return 1;
}

- (void)collectionNode:(A_SCollectionNode *)collectionNode willBeginBatchFetchWithContext:(A_SBatchContext *)context
{
  [self fetchMoreCatsWithCompletion:^(BOOL finished){
    [context completeBatchFetching:YES];
  }];
}

#pragma mark - A_SCollectionDelegateFlowLayout

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
  if (section == 0) {
    return A_SSizeRangeUnconstrained;
  } else {
    return A_SSizeRangeZero;
  }
}

- (A_SSizeRange)collectionNode:(A_SCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
  if (section == 0) {
    return A_SSizeRangeUnconstrained;
  } else {
    return A_SSizeRangeZero;
  }
}

@end
