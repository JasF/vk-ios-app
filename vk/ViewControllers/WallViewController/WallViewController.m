//
//  WallViewController.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Post.h"
#import "PostNode.h"
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "WallPostNode.h"
#import "User.h"
#import "BlurbNode.h"
#import "LoadingNode.h"

@interface WallViewController () <BaseCollectionViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<WallViewModel> viewModel;
@end

@implementation WallViewController {
    BOOL _hasHeaderSection;
}

- (instancetype)initWithViewModel:(id<WallViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"VK Wall";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}

#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_viewModel menuTapped];
}

#pragma mark - ASCollectionDelegate, ASCollectionDataSource
- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
    if (_hasHeaderSection) {
        return 2;
    }
    return 1;
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_hasHeaderSection && !indexPath.section) {
        return ^{
            WallUser *wallPost = [[WallUser alloc] initWithUser:self.viewModel.currentUser];
            ASCellNode *node = (ASCellNode *)[self.nodeFactory nodeForItem:wallPost];
            return node;
        };
    }
    return [super collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_hasHeaderSection && !indexPath.section) {
        return self.viewModel.currentUser;
    }
    return [super collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    if (_hasHeaderSection && !section) {
        return 1;
    }
    return [super collectionNode:collectionNode numberOfItemsInSection:section];
}

#pragma mark - BaseCollectionViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getWallPostsWithOffset:offset
                            completion:^(NSArray *objects) {
                                if (completion) {
                                    completion(objects);
                                }
                            }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!_hasHeaderSection) {
        _hasHeaderSection = (self.viewModel.currentUser != nil) ? YES : NO;
        if (_hasHeaderSection) {
            [self.collectionNode insertSections:[NSIndexSet indexSetWithIndex:0]];
            [self.collectionNode insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]]];
        }
    }
    [super performBatchAnimated:animated];
}

@end
