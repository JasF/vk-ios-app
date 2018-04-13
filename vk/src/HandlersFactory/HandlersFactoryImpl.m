//
//  HandlersFactoryImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "HandlersFactoryImpl.h"
#import "WallServiceImpl.h"
#import "NewsViewController.h"
#import "DialogsViewController.h"
#import "DialogsServiceImpl.h"

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

- (id<DialogsServiceHandlerProtocol>)dialogsServiceHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(DialogsServiceHandlerProtocol)];
}

- (id<DialogsHandlerProtocol>)dialogsHandler {
    return [_pythonBridge handlerWithProtocol:@protocol(DialogsHandlerProtocol)];
}

@end
