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

@interface ChatListViewController () <BaseCollectionViewControllerDataSource, ASCollectionDelegate, ChatListViewModelDelegate>
@property (strong, nonatomic) id<ChatListViewModel> viewModel;
@property (strong, nonatomic) id<NodeFactory> nodeFactory;
@end

@implementation ChatListViewController

- (instancetype)initWithViewModel:(id<ChatListViewModel>)viewModel
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

#pragma mark - ChatListViewModelDelegate
- (void)reloadData {
    [super reloadData];
}

- (void)setTypingEnabled:(BOOL)enabled
                  userId:(NSInteger)userId {
    NSLog(@"chatlist typing: %@ userId: %@", @(enabled), @(userId));
    for (Dialog *dialog in [self objectsArray]) {
        if (dialog.message.user_id == userId) {
            dialog.message.isTyping = enabled;
            [self simpleReloadCollectionView];
            break;
        }
    }
}

@end
