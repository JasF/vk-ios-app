//
//  DialogServiceImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogService.h"
#import "HandlersFactory.h"

@protocol DialogServiceHandlerProtocol <NSObject>
- (NSArray *)getMessages:(NSNumber *)offset;
@end

@interface DialogServiceImpl : NSObject <DialogService>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end
