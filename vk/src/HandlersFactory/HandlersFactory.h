//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol WallServiceHandlerProtocol;
@protocol PyChatListService;
@protocol PyDialogService;
@protocol NewsHandlerProtocol;
@protocol DialogsHandlerProtocol;
@protocol PyChatListScreenViewModel;

@protocol HandlersFactory <NSObject>
- (id<WallServiceHandlerProtocol>)wallServiceHandler;
- (id<PyChatListService>)chatListServiceHandler;
- (id<PyDialogService>)dialogServiceHandler;
- (id<NewsHandlerProtocol>)newsHandler;
- (id<PyChatListScreenViewModel>)chatListHandler;
@end
