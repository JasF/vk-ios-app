//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol WallServiceHandlerProtocol;
@protocol DialogsServiceHandlerProtocol;
@protocol NewsHandlerProtocol;
@protocol DialogsHandlerProtocol;

@protocol HandlersFactory <NSObject>
- (id<WallServiceHandlerProtocol>)wallServiceHandler;
- (id<DialogsServiceHandlerProtocol>)dialogsServiceHandler;
- (id<NewsHandlerProtocol>)newsHandler;
- (id<DialogsHandlerProtocol>)dialogsHandler;
@end
