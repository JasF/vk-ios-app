//
//  CollectionViewController.m
//  Sample
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

#import "CollectionViewController.h"
#import "KittenNode.h"
#import <Async_DisplayKit/A_STraitCollection.h>

@interface CollectionViewController () <A_SCollectionDelegate, A_SCollectionDataSource>
@property (nonatomic, strong) A_SCollectionNode *collectionNode;
@end

@implementation CollectionViewController

- (instancetype)init
{
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 10;
  layout.minimumInteritemSpacing = 10;
  
  A_SCollectionNode *collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:layout];
  
  if (!(self = [super initWithNode:collectionNode]))
    return nil;
  
  self.title = @"Collection Node";
  _collectionNode = collectionNode;
  collectionNode.dataSource = self;
  collectionNode.delegate = self;
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.collectionNode.view.contentInset = UIEdgeInsetsMake(20, 10, CGRectGetHeight(self.tabBarController.tabBar.frame), 10);
}

#pragma mark - A_SCollectionDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 50;
}

- (A_SCellNode *)collectionView:(A_SCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  KittenNode *cell = [[KittenNode alloc] init];
  cell.textNode.maximumNumberOfLines = 3;
  cell.imageTappedBlock = ^{
    [KittenNode defaultImageTappedAction:self];
  };
  return cell;
}

- (A_SSizeRange)collectionView:(A_SCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  A_STraitCollection *traitCollection = [self.collectionNode asyncTraitCollection];
  
  if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    return A_SSizeRangeMake(CGSizeMake(200, 120), CGSizeMake(200, 120));
  }
  return A_SSizeRangeMake(CGSizeMake(132, 180), CGSizeMake(132, 180));
}

@end
