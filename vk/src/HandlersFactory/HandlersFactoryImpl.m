//
//  HandlersFactoryImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "HandlersFactoryImpl.h"
#import "WallServiceImpl.h"
#import "WallViewController.h"
#import "ChatListViewController.h"
#import "ChatListServiceImpl.h"
#import "vk-Swift.h"
#import "DialogServiceImpl.h"
#import "ChatListViewModelImpl.h"
#import "DialogScreenViewModelImpl.h"
#import "WallViewModelImpl.h"
#import "MenuViewModelImpl.h"
#import "FriendsViewModelImpl.h"


@interface HandlersFactoryImpl ()
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@end

@implementation HandlersFactoryImpl

- (id)initWithPythonBridge:(id<PythonBridge>)pythonBridge {
    NSCParameterAssert(pythonBridge);
    if (self) {
        _pythonBridge = pythonBridge;
    }
    return self;
}

- (id<PyChatListViewModel>)chatListViewModelHandler:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyChatListViewModel) delegate:delegate];
}

- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate parameters:(NSDictionary *)parameters {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDialogScreenViewModel)
                                                delegate:delegate
                                              parameters:parameters];
}

- (id<PyWallViewModel>)wallViewModelHandlerWithDelegate:(id)delegate parameters:(NSDictionary *)parameters {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyWallViewModel)
                                                delegate:delegate
                                              parameters:parameters];
}

- (id<PyMenuViewModel>)menuViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyMenuViewModel)];
}

- (id<PyFriendsViewModel>)friendsViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyFriendsViewModel)];
}

@end
