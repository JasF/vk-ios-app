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
#import "ScreensManager.h"

@interface WallViewController () <BaseTableViewControllerDataSource, WallUserScrollNodeDelegate, WallUserMessageNodeDelegate, ViewControllerActionsExtension>
@property (strong, nonatomic) id<WallViewModel> viewModel;
@property (weak, nonatomic) WallUserScrollNode *scrollNode;
@end

@implementation WallViewController

@synthesize needsUpdateContentOnAppear = _needsUpdateContentOnAppear;

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.pushed && !self.navigationItem.leftBarButtonItem) {
        [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
    }
    if (self.needsUpdateContentOnAppear) {
        self.needsUpdateContentOnAppear = NO;
        [self pullToRefreshAction];
    }
}

#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_viewModel menuTapped];
}

- (void)addPostTapped:(id)sender {
    [_viewModel addPostTapped];
}

- (void)addRightIconIfNeeded {
    User *user = self.viewModel.currentUser;
    if (!self.navigationItem.rightBarButtonItem && user.can_post && user.id > 0) {
        UIButton *button = [UIButton new];
        [button addTarget:self action:@selector(addPostTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"add_post"] forState:UIControlStateNormal];
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:button];
        self.navigationItem.rightBarButtonItem = backButton;
        [button sizeToFit];
    }
}

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    @weakify(self);
    [_viewModel getWallPostsWithOffset:offset
                            completion:^(NSArray *objects) {
                                @strongify(self);
                                if (!offset) {
                                    [self addRightIconIfNeeded];
                                }
                                if (completion) {
                                    completion(objects);
                                }
                            }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!self.sectionsArray && self.viewModel.currentUser) {
        NSMutableArray *array = [@[[[WallUserCellModel alloc] init:WallUserCellModelTypeImage user:self.viewModel.currentUser]] mutableCopy];
        if (!self.viewModel.currentUser.currentUser) {
            [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeMessage user:self.viewModel.currentUser]];
        }
        [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeActions user:self.viewModel.currentUser]];
        self.sectionsArray = @[array];
    }
    [super performBatchAnimated:animated];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)aNode {
    [super tableNode:tableNode willDisplayRowWithNode:aNode];
    if ([aNode isKindOfClass:[WallUserScrollNode class]]) {
        self.scrollNode = (WallUserScrollNode *)aNode;
        self.scrollNode.delegate = self;
    }
    else if ([aNode isKindOfClass:[WallUserMessageNode class]]) {
        WallUserMessageNode *node = (WallUserMessageNode *)aNode;
        node.delegate = self;
    }
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
- (void)groupsTapped {
    [_viewModel groupsTapped];
}

#pragma mark - WallUserMessageNodeDelegate
- (void)messageButtonTapped {
    [_viewModel messageButtonTapped];
}

- (void)friendButtonTapped:(void(^)(NSInteger resultCode))callback {
    [_viewModel friendButtonTapped:callback];
}

#pragma mark - Overriden
- (void)pullToRefreshAction {
    [_viewModel getLatestPostsWithCompletion:^(NSArray *objects) {
        id object = objects.firstObject;
        if (!object) {
            return;
        }
        [self.tableNode performBatchUpdates:^{
            NSInteger section = [self.tableNode numberOfSections] - 1;
            [self.tableNode insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:section]]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.objectsArray insertObject:object atIndex:0];
        }
                                 completion:^(BOOL finished) {
                                     
                                 }];
    }];
}

@end
