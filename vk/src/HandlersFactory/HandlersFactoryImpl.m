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
#import "ChatListScreenViewModelImpl.h"
#import "DialogScreenViewModelImpl.h"
#import "WallScreenViewModelImpl.h"
#import "MenuScreenViewModelImpl.h"


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

- (id<PyChatListScreenViewModel>)chatListViewModelHandler:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyChatListScreenViewModel) delegate:delegate];
}

- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyDialogScreenViewModel) delegate:delegate];
}

- (id<PyWallScreenViewModel>)wallViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyWallScreenViewModel)];
}

- (id<PyMenuScreenViewModel>)menuViewModelHandler {
    return [_pythonBridge instantiateHandlerWithProtocol:@protocol(PyMenuScreenViewModel)];
}

@end
