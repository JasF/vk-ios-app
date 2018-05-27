//
//  ChatListViewController.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatListViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "VKSdkManager.h"
#import <VK-ios-sdk/VKSdk.h>
#import "WallPost.h"
#import "Dialog.h"
#import "Oxy_Feed-Swift.h"

@interface ChatListViewController () <BaseViewControllerDataSource, ASCollectionDelegate, ChatListViewModelDelegate>
@property (strong, nonatomic) id<ChatListViewModel> viewModel;
@end

@implementation ChatListViewController

- (instancetype)initWithViewModel:(id<ChatListViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    _viewModel = viewModel;
    _viewModel.delegate = self;
    self.dataSource = self;
    
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        [self setTitle:L(@"title_dialogs")];
    }
    
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_viewModel);
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_viewModel becomeActive];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_viewModel resignActive];
}
#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_viewModel menuTapped];
}

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getDialogsWithOffset:offset completion:^(NSArray<Dialog *> *dialogs, NSError *error) {
        if ([error utils_isConnectivityError]) {
            [self showNoConnectionAlert];
            completion(@[]);
            return;
        }
        completion(dialogs);
    }];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableNode:tableNode didSelectRowAtIndexPath:indexPath];
    Dialog *item = self.objectsArray[indexPath.row];
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
    //DDLogInfo(@"chatlist typing: %@ userId: %@", @(enabled), @(userId));
    for (Dialog *dialog in [self objectsArray]) {
        if (dialog.message.user_id == userId) {
            dialog.message.isTyping = enabled;
            [self.tableNode reloadData];
            break;
        }
    }
}

@end
