//
//  DialogServiceImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogService.h"
#import "HandlersFactory.h"


@protocol PyDialogService <NSObject>
- (NSDictionary *)getMessages:(NSNumber *)offset
                       userId:(NSNumber *)userId;

- (NSDictionary *)getMessages:(NSNumber *)offset
                       userId:(NSNumber *)userId
               startMessageId:(NSNumber *)startMessageId;

- (void)sendTextMessage:(NSString *)text userId:(NSNumber *)userId;
@end

@interface DialogServiceImpl : NSObject <DialogService>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end
