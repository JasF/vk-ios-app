//
//  PhotoFeedNodeController.m
//  Sample
//
//  Created by Hannah Troisi on 2/17/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "PhotoFeedNodeController.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
#import "Utilities.h"
#import "PhotoModel.h"
#import "PhotoCellNode.h"
#import "PhotoFeedModel.h"

#define AUTO_TAIL_LOADING_NUM_SCREENFULS  2.5

@interface PhotoFeedNodeController () <A_STableDelegate, A_STableDataSource>
@property (nonatomic, strong) A_STableNode *tableNode;
@end

@implementation PhotoFeedNodeController

#pragma mark - Lifecycle

// -init is often called off the main thread in A_SDK. Therefore it is imperative that no UIKit objects are accessed.
// Examples of common errors include accessing the node’s view or creating a gesture recognizer.
- (instancetype)init
{
  _tableNode = [[A_STableNode alloc] init];
  self = [super initWithNode:_tableNode];

  if (self) {
    self.navigationItem.title = @"A_SDK";
    [self.navigationController setNavigationBarHidden:YES];

    _tableNode.dataSource = self;
    _tableNode.delegate = self;
  }

  return self;
}

// -loadView is guaranteed to be called on the main thread and is the appropriate place to
// set up an UIKit objects you may be using.
- (void)loadView
{
  [super loadView];

  self.tableNode.leadingScreensForBatching = AUTO_TAIL_LOADING_NUM_SCREENFULS;  // overriding default of 2.0
}

- (void)loadPageWithContext:(A_SBatchContext *)context
{
  [self.photoFeed requestPageWithCompletionBlock:^(NSArray *newPhotos){

    [self insertNewRows:newPhotos];
    [self requestCommentsForPhotos:newPhotos];
    if (context) {
      [context completeBatchFetching:YES];
    }
  } numResultsToReturn:20];
}

#pragma mark - Subclassing

- (UITableView *)tableView
{
  return _tableNode.view;
}

- (void)loadPage
{
  [self loadPageWithContext:nil];
}

- (void)requestCommentsForPhotos:(NSArray *)newPhotos
{
  // Do nothing (#1530).
}

#pragma mark - A_STableDataSource methods

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return [self.photoFeed numberOfItemsInFeed];
}

- (A_SCellNodeBlock)tableNode:(A_STableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PhotoModel *photoModel = [self.photoFeed objectAtIndex:indexPath.row];
  // this will be executed on a background thread - important to make sure it's thread safe
  A_SCellNode *(^A_SCellNodeBlock)() = ^A_SCellNode *() {
    PhotoCellNode *cellNode = [[PhotoCellNode alloc] initWithPhotoObject:photoModel];
    return cellNode;
  };

  return A_SCellNodeBlock;
}

#pragma mark - A_STableDelegate methods

// Receive a message that the tableView is near the end of its data set and more data should be fetched if necessary.
- (void)tableNode:(A_STableNode *)tableNode willBeginBatchFetchWithContext:(A_SBatchContext *)context
{
  [context beginBatchFetching];
  [self loadPageWithContext:context];
}

@end
