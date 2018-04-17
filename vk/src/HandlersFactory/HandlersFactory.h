//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol WallServiceHandlerProtocol;
@protocol NewsHandlerProtocol;
@protocol DialogsHandlerProtocol;
@protocol PyChatListScreenViewModel;
@protocol PyDialogScreenViewModel;

@protocol HandlersFactory <NSObject>
- (id<WallServiceHandlerProtocol>)wallServiceHandler;
- (id<NewsHandlerProtocol>)newsHandler;
- (id<PyChatListScreenViewModel>)chatListViewModelHandler:(id)delegate;
- (id<PyDialogScreenViewModel>)dialogViewModelHandler;
@end
