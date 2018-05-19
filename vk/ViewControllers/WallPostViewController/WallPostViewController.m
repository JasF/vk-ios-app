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
#import "Oxy_Feed-Swift.h"

static NSInteger const kOffsetForPreloadLatestComments = -1;

@interface WallPostViewController () <BaseViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<WallPostViewModel> viewModel;
@property WallPost *post;
@property BOOL commentsEmpty;
@property BOOL didAppear;
@end

@implementation WallPostViewController {
    BOOL _hasHeaderSection;
}

- (instancetype)initWithViewModel:(id<WallPostViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        [self setTitle:L(@"title_detail_post")];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _didAppear = YES;
    [self showCommentsToolbarIfPossible];
}

- (void)showCommentsToolbarIfPossible {
    if (!_didAppear) {
        return;
    }
    self.commentsParentItem = self.post;
    if (self.post.comments.canPost) {
        [self showCommentsToolbar];
    }
}

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    if (offset || self.commentsEmpty) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    @weakify(self);
    void (^postBlock)(WallPost *post) = ^void(WallPost *post) {
        @strongify(self);
        if (!self.post && post) {
            self.post = post;
        }
        if (completion) {
            completion(@[]);
        }
    };
    if (self.post) {
        postBlock = nil;
    }
    [_viewModel getWallPostWithCommentsOffset:kOffsetForPreloadLatestComments
                                    postBlock:postBlock
                                   completion:^(NSArray *comments) {
                                       @strongify(self);
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
    if (self.objectsArray.count && self.post.comments.count > self.objectsArray.count) {
        [self showPreloadCommentsCellWithCount:self.post.comments.count item:self.post section:section];
    }
    self.sectionsArray = @[section];
    [super performBatchAnimated:animated];
    [self showCommentsToolbarIfPossible];
}

#pragma mark - PostsViewController
- (void)numberOfCommentsDidUpdated:(NSInteger)numberOfComments {
   
}

#pragma mark - BaseViewController
- (ScreenType)screenType {
    return ScreenWallPost;
}

@end
