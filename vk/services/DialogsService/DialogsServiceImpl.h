//
//  DialogsServiceImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogsService.h"
#import "HandlersFactory.h"

@protocol DialogsServiceHandlerProtocol <NSObject>
- (NSDictionary *)getDialogs:(NSNumber *)offset;
@end

@interface DialogsServiceImpl : NSObject <DialogsService>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end
