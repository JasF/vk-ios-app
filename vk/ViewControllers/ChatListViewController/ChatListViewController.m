//
//  ChatListViewController.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatListViewController.h"
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
#import "Dialog.h"

@interface ChatListViewController () <BaseCollectionViewControllerDataSource, ASCollectionDelegate, ChatListScreenViewModelDelegate>
@property (strong, nonatomic) id<ChatListScreenViewModel> viewModel;
@property (strong, nonatomic) id<NodeFactory> nodeFactory;
@end

@implementation ChatListViewController

- (instancetype)initWithViewModel:(id<ChatListScreenViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    _nodeFactory = nodeFactory;
    _viewModel = viewModel;
    _viewModel.delegate = self;
    self.dataSource = self;
    
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        self.title = @"VK Dialogs";
    }
    
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_viewModel);
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
    [_viewModel getDialogsWithOffset:offset
                               completion:completion];
}

#pragma mark - ASCollectionNodeDelegate
- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Dialog *item = [collectionNode nodeModelForItemAtIndexPath:indexPath];
    if (!item) {
        return;
    }
    [_viewModel tappedOnDialogWithUserId:item.message.user_id];
}

#pragma mark - ChatListScreenViewModelDelegate
- (void)reloadData {
    [super reloadData];
}

@end
