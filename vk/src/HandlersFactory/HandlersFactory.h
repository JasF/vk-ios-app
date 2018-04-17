//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol WallServiceHandlerProtocol;
@protocol DialogsServiceHandlerProtocol;
@protocol PyDialogService;
@protocol NewsHandlerProtocol;
@protocol DialogsHandlerProtocol;
@protocol DialogHandlerProtocol;

@protocol HandlersFactory <NSObject>
- (id<WallServiceHandlerProtocol>)wallServiceHandler;
- (id<DialogsServiceHandlerProtocol>)dialogsServiceHandler;
- (id<PyDialogService>)dialogServiceHandler;
- (id<NewsHandlerProtocol>)newsHandler;
- (id<DialogsHandlerProtocol>)dialogsHandler;
- (id<DialogHandlerProtocol>)dialogHandler;
@end
