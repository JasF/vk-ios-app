//
//  HandlersFactoryImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "HandlersFactoryImpl.h"
#import "WallServiceImpl.h"
#import "NewsViewController.h"
#import "ChatListViewController.h"
#import "ChatListServiceImpl.h"
#import "vk-Swift.h"
#import "DialogServiceImpl.h"
#import "ChatListScreenViewModelImpl.h"


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

- (id<WallServiceHandlerProtocol>)wallServiceHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(WallServiceHandlerProtocol)];
}

- (id<NewsHandlerProtocol>)newsHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(NewsHandlerProtocol)];
}

- (id<PyChatListService>)chatListServiceHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(PyChatListService)];
}

- (id<PyChatListScreenViewModel>)chatListHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(PyChatListScreenViewModel)];
}

- (id<PyDialogService>)dialogServiceHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(PyDialogService)];
}

@end
