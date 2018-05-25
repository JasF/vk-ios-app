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
#import "Oxy_Feed-Swift.h"
#import "ScreensManager.h"

static CGFloat const kButtonSize = 44.f;

@interface WallViewController () <BaseViewControllerDataSource, WallUserScrollNodeDelegate, WallUserMessageNodeDelegate, ViewControllerActionsExtension>
@property (strong, nonatomic) id<WallViewModel> viewModel;
@property (weak, nonatomic) WallUserScrollNode *scrollNode;

@property (nonatomic) WallUserCellModel *imageModel;
@property (nonatomic) WallUserCellModel *messageModel;
@property (nonatomic) WallUserCellModel *actionsModel;
@property (nonatomic) BOOL updating;
@property (nonatomic) BOOL needsReload;
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
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    @weakify(self);
    [_viewModel getUserInfo:^(User *user) {
        @strongify(self);
        if (!user) {
            return;
        }
        if (!self.title.length) {
            self.title = (user.first_name.length > 0) ? user.first_name : user.nameString;
        }
        if (!self.sectionsArray) {
            [self.tableNode reloadData];
            return;
        }
        [self addRightIconIfNeeded];
        [self.imageModel setUser:user];
        [self.messageModel setUser:user];
        [self.actionsModel setUser:user];
        DDLogInfo(@"latest user friends_count: %@", @(self.viewModel.currentUser.friends_count));
       // if (self.updating) {
        //    self.needsReload = YES;
       // }
        //else {
       //     [self.tableNode reloadData];
       // }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
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

- (void)optionsTapped:(id)sender {
    NSCAssert(self.viewModel.currentUser, @"user missing for options");
    [self.postsViewModel optionsTappedWithUser:self.viewModel.currentUser];
}

- (void)addRightIconIfNeeded {
    User *user = self.viewModel.currentUser;
    if (!self.navigationItem.rightBarButtonItem) {
        UIButton *button = [UIButton new];
        [button addTarget:self action:@selector(addPostTapped:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"add_post"] forState:UIControlStateNormal];
        UIBarButtonItem *addPost = [[UIBarButtonItem alloc] initWithCustomView:button];
        
        button.size = CGSizeMake(kButtonSize, kButtonSize);
        CGFloat spacerWidth = -10;
        if (@available(iOS 11, *)) {
            spacerWidth = 6;
        }
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        negativeSpacer.width = spacerWidth;
        NSMutableArray *array = [@[negativeSpacer] mutableCopy];
        
        if (!user.currentUser) {
            UIButton *button = [UIButton new];
            [button addTarget:self action:@selector(optionsTapped:) forControlEvents:UIControlEventTouchUpInside];
            [button setImage:[UIImage imageNamed:@"icon_more"] forState:UIControlStateNormal];
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 16);
            UIBarButtonItem *more = [[UIBarButtonItem alloc] initWithCustomView:button];
            [array addObject:more];
        }
        if (user.can_post) {
            [array addObject:addPost];
        }
        self.navigationItem.rightBarButtonItems = array;
    }
}

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    if (!self.sectionsArray) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
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
        NSMutableArray *array = [@[[self imageModel]] mutableCopy];
        if (!self.viewModel.currentUser.currentUser) {
            [array addObject:[self messageModel]];
        }
        [array addObject:[self actionsModel]];
        self.sectionsArray = @[array];
    }
    [super performBatchAnimated:animated];
}

- (WallUserCellModel *)imageModel {
    if (!_imageModel) {
        _imageModel = [[WallUserCellModel alloc] init:WallUserCellModelTypeImage user:self.viewModel.currentUser];
    }
    return _imageModel;
}

- (WallUserCellModel *)messageModel {
    if (!_messageModel) {
        _messageModel = [[WallUserCellModel alloc] init:WallUserCellModelTypeMessage user:self.viewModel.currentUser];
    }
    return _messageModel;
}

- (WallUserCellModel *)actionsModel {
    if (!_actionsModel) {
        _actionsModel = [[WallUserCellModel alloc] init:WallUserCellModelTypeActions user:self.viewModel.currentUser];
    }
    return _actionsModel;
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
