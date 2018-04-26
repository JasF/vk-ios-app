//
//  VideoFeedNodeController.m
//  Sample
//
//  Created by Erekle on 5/15/16.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "A_S IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "VideoFeedNodeController.h"
#import <Async_DisplayKit/A_SVideoPlayerNode.h>
#import "VideoModel.h"
#import "VideoContentCell.h"

@interface VideoFeedNodeController ()<A_STableDelegate, A_STableDataSource>

@end

@implementation VideoFeedNodeController
{
  A_STableNode *_tableNode;
  NSMutableArray<VideoModel*> *_videoFeedData;
}

- (instancetype)init
{
  _tableNode = [[A_STableNode alloc] init];
  _tableNode.delegate = self;
  _tableNode.dataSource = self;

  if (!(self = [super initWithNode:_tableNode])) {
    return nil;
  }
  
  [self generateFeedData];
  self.navigationItem.title = @"Home";

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [_tableNode reloadData];
}

- (void)generateFeedData
{
  _videoFeedData = [[NSMutableArray alloc] init];

  for (int i = 0; i < 30; i++) {
    [_videoFeedData addObject:[[VideoModel alloc] init]];
  }
}

#pragma mark - A_SCollectionDelegate - A_SCollectionDataSource

- (NSInteger)numberOfSectionsInTableNode:(A_STableNode *)tableNode
{
  return 1;
}

- (NSInteger)tableNode:(A_STableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return _videoFeedData.count;
}

- (A_SCellNode *)tableNode:(A_STableNode *)tableNode nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  VideoModel *videoObject = [_videoFeedData objectAtIndex:indexPath.row];
  VideoContentCell *cellNode = [[VideoContentCell alloc] initWithVideoObject:videoObject];
  
  return cellNode;
}

@end
