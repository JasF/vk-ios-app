//
//  DialogsViewController.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogsViewController.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
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

@interface DialogsViewController () <BaseCollectionViewControllerDataSource, A_SCollectionDelegate>
@property (strong, nonatomic) id<DialogsHandlerProtocol> handler;
@property (strong, nonatomic) id<NodeFactory> nodeFactory;
@property (strong, nonatomic) id<DialogsService> dialogsService;
@end

@implementation DialogsViewController

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            nodeFactory:(id<NodeFactory>)nodeFactory
                         dialogsService:(id<DialogsService>)dialogsService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(nodeFactory);
    NSCParameterAssert(dialogsService);
    _nodeFactory = nodeFactory;
    _dialogsService = dialogsService;
    _handler = [handlersFactory dialogsHandler];
    self.dataSource = self;
    
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        self.title = @"VK Dialogs";
    }
    
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_handler);
    [super viewDidLoad];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}

#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_handler menuTapped];
}

#pragma mark - BaseCollectionViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_dialogsService getDialogsWithOffset:offset
                               completion:completion];
}

#pragma mark - A_SCollectionNodeDelegate
- (void)collectionNode:(A_SCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Dialog *item = [collectionNode nodeModelForItemAtIndexPath:indexPath];
    if (!item) {
        return;
    }
    [_handler tappedOnDialogWithUserId:@(item.message.user_id)];
}

@end
