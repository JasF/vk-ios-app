//
//  PhotoFeedSectionController.m
//  Sample
//
//  Created by Adlai Holler on 12/29/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "PhotoFeedSectionController.h"
#import "PhotoFeedModel.h"
#import "PhotoModel.h"
#import "PhotoCellNode.h"
#import "TailLoadingNode.h"
#import "FeedHeaderNode.h"

@interface PhotoFeedSectionController () <A_SSupplementaryNodeSource, IGListSupplementaryViewSource>
@property (nonatomic, strong) NSString *paginatingSpinner;
@end

@implementation PhotoFeedSectionController

- (instancetype)init
{
  if (self = [super init]) {
    _paginatingSpinner = @"Paginating Spinner";
    self.supplementaryViewSource = self;
  }
  return self;
}

#pragma mark - IGListSectionType

- (void)didUpdateToObject:(id)object
{
  _photoFeed = object;
  [self setItems:_photoFeed.photos animated:NO completion:nil];
}

- (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index
{
  return [A_SIGListSectionControllerMethods cellForItemAtIndex:index sectionController:self];
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index
{
  return [A_SIGListSectionControllerMethods sizeForItemAtIndex:index];
}

- (void)didSelectItemAtIndex:(NSInteger)index
{
  // nop
}

#pragma mark - A_SSectionController

- (A_SCellNodeBlock)nodeBlockForItemAtIndex:(NSInteger)index
{
  id object = self.items[index];
  // this will be executed on a background thread - important to make sure it's thread safe
  A_SCellNode *(^nodeBlock)() = nil;
  if (object == _paginatingSpinner) {
    nodeBlock = ^{
      return [[TailLoadingNode alloc] init];
    };
  } else if ([object isKindOfClass:[PhotoModel class]]) {
    PhotoModel *photoModel = object;
    nodeBlock = ^{
      PhotoCellNode *cellNode = [[PhotoCellNode alloc] initWithPhotoObject:photoModel];
      return cellNode;
    };
  }

  return nodeBlock;
}

- (void)beginBatchFetchWithContext:(A_SBatchContext *)context
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // Immediately add the loading spinner if needed.
    if (self.items.count > 0) {
      NSArray *newItems = [self.items arrayByAddingObject:_paginatingSpinner];
      [self setItems:newItems animated:NO completion:nil];
    }

    // Start the fetch, then update the items (removing the spinner) when they are loaded.
    [_photoFeed requestPageWithCompletionBlock:^(NSArray *newPhotos){
      [self setItems:_photoFeed.photos animated:NO completion:^{
        [context completeBatchFetching:YES];
      }];
    } numResultsToReturn:20];
  });
}

#pragma mark - RefreshingSectionControllerType

- (void)refreshContentWithCompletion:(void(^)())completion
{
  [_photoFeed refreshFeedWithCompletionBlock:^(NSArray *addedItems) {
    [self setItems:_photoFeed.photos animated:YES completion:completion];
  } numResultsToReturn:4];
}

#pragma mark - A_SSupplementaryNodeSource

- (A_SCellNodeBlock)nodeBlockForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  A_SDisplayNodeAssert([elementKind isEqualToString:UICollectionElementKindSectionHeader], nil);
  return ^{
    return [[FeedHeaderNode alloc] init];
  };
}

- (A_SSizeRange)sizeRangeForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  if ([elementKind isEqualToString:UICollectionElementKindSectionHeader]) {
    return A_SSizeRangeUnconstrained;
  } else {
    return A_SSizeRangeZero;
  }
}

#pragma mark - IGListSupplementaryViewSource

- (NSArray<NSString *> *)supportedElementKinds
{
  return @[ UICollectionElementKindSectionHeader ];
}

- (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [A_SIGListSupplementaryViewSourceMethods viewForSupplementaryElementOfKind:elementKind atIndex:index sectionController:self];
}

- (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [A_SIGListSupplementaryViewSourceMethods sizeForSupplementaryViewOfKind:elementKind atIndex:index];
}

@end
