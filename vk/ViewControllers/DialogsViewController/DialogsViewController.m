//
//  DialogsViewController.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "DialogsViewController.h"
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
#import "AppDelegate.h"
#import "Dialog.h"

@interface DialogsViewController () <BaseCollectionViewControllerDataSource>
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

@end
