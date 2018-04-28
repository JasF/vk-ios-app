//
//  WallViewController.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "vk-Swift.h"

@interface WallViewController () <BaseTableViewControllerDataSource, WallUserScrollNodeDelegate>
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

#pragma mark - BaseTableViewControllerDataSource
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
        self.sectionsArray = @[@[[[WallUserCellModel alloc] init:WallUserCellModelTypeImage user:self.viewModel.currentUser],
                                 [[WallUserCellModel alloc] init:WallUserCellModelTypeMessage user:self.viewModel.currentUser],
                                 [[WallUserCellModel alloc] init:WallUserCellModelTypeActions user:self.viewModel.currentUser]
                                 ]];
    }
    [super performBatchAnimated:animated];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)node {
    if ([node isKindOfClass:[WallUserScrollNode class]]) {
        WallUserScrollNode *scrollNode = (WallUserScrollNode *)node;
        scrollNode.delegate = self;
    }
}

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!indexPath.section) {
        return;
    }
    NSArray *objects = [self objectsArray];
    NSCAssert(indexPath.row < objects.count, @"index out of bounds: %@ %@", indexPath, objects);
    if (indexPath.row >= objects.count) {
        return;
    }
    
    [_viewModel tappedOnPost:objects[indexPath.row]];
}

#pragma mark - WallUserScrollNodeDelegate
- (void)friendsTapped {
    [_viewModel friendsTapped];
}
- (void)commonTapped {
    [_viewModel commonTapped];
}
- (void)subscribtionsTapped {
    [_viewModel subscribtionsTapped];
}
- (void)followersTapped {
    [_viewModel followersTapped];
}
- (void)photosTapped {
    [_viewModel photosTapped];
}
- (void)videosTapped {
    [_viewModel videosTapped];
}

@end
