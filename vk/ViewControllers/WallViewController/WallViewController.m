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

@interface WallViewController () <BaseCollectionViewControllerDataSource>
@property (strong, nonatomic) id<WallViewModel> viewModel;
@end

@implementation WallViewController

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
    if (!self.sectionsArray && self.viewModel.currentUser) {
        self.sectionsArray = @[@[[ [WallUser alloc] initWithUser:self.viewModel.currentUser] ]];
        [self.collectionNode insertSections:[NSIndexSet indexSetWithIndex:0]];
        [self.collectionNode insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
    [super performBatchAnimated:animated];
}

#pragma mark - ASCollectionNodeDelegate
- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *objects = [self objectsArray];
    NSCAssert(indexPath.row < objects.count, @"index out of bounds: %@ %@", indexPath, objects);
    if (indexPath.row >= objects.count) {
        return;
    }
    
    [_viewModel tappedOnPost:objects[indexPath.row]];
}

@end
