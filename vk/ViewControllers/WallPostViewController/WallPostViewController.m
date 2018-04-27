//
//  WallPostViewController.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostViewController.h"
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

@interface WallPostViewController () <BaseTableViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<WallPostViewModel> viewModel;
@property WallPost *post;
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
    if (offset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    if (self.sectionsArray.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    [_viewModel getWallPostWithCommentsOffset:offset completion:^(WallPost *post, NSArray *comments) {
        if (!self.post) {
            self.post = post;
        }
        if (completion) {
            completion(comments);
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!self.sectionsArray && self.post) {
        self.sectionsArray = @[@[self.post]];
    }
    [super performBatchAnimated:animated];
}
@end
