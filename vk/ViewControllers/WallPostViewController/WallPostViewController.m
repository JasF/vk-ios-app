//
//  WallPostViewController.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "vk-Swift.h"

static NSInteger const kOffsetForPreloadLatestComments = -1;
static NSInteger const kNumberOfCommentsForPreload = 40;

@interface WallPostViewController () <BaseTableViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<WallPostViewModel> viewModel;
@property WallPost *post;
@property BOOL commentsEmpty;
@end

@implementation WallPostViewController {
    BOOL _hasHeaderSection;
    CommentsPreloadModel *_commentsPreloadModel;
}

- (instancetype)initWithViewModel:(id<WallPostViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        self.title = @"VK Post & Comments";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    if (self.sectionsArray.count || offset || self.commentsEmpty) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    @weakify(self);
    [_viewModel getWallPostWithCommentsOffset:kOffsetForPreloadLatestComments completion:^(WallPost *post, NSArray *comments) {
        @strongify(self);
        if (!self.post) {
            self.post = post;
            if (self.post.comments.canPost) {
                [self showCommentsToolbar];
            }
            self.commentsParentItem = post;
        }
        if (completion) {
            completion(comments);
        }
        if (!offset && !comments.count) {
            self.commentsEmpty = YES;
            return;
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    NSMutableArray *section = [NSMutableArray new];
    if (self.post) {
        [section addObject:self.post];
    }
    if (self.post.comments.count > self.objectsArray.count) {
        NSInteger remaining = self.post.comments.count - self.objectsArray.count;
        NSInteger preload = MIN(remaining, kNumberOfCommentsForPreload);
        self.commentsPreloadModel.post = self.post;
        self.commentsPreloadModel.loaded = self.objectsArray.count;
        [self.commentsPreloadModel set:preload remaining:remaining];
        [section addObject:self.commentsPreloadModel];
    }
    self.sectionsArray = @[section];
    [super performBatchAnimated:animated];
}

- (CommentsPreloadModel *)commentsPreloadModel {
    if (!_commentsPreloadModel) {
        _commentsPreloadModel = [[CommentsPreloadModel alloc] init:0 remaining:0];
    }
    return _commentsPreloadModel;
}

#pragma mark - PostsViewController
- (void)numberOfCommentsDidUpdated:(NSInteger)numberOfComments {
   
}

@end
