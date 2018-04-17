//
//  DialogService.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "Message.h"

@protocol DialogService <NSObject>
- (void)getMessagesWithOffset:(NSInteger)offset
                       userId:(NSInteger)userId
                   completion:(void(^)(NSArray<Message *> *messages))completion;
    
- (void)getMessagesWithOffset:(NSInteger)offset
                       userId:(NSInteger)userId
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion;

- (void)sendTextMessage:(NSString *)text
                 userId:(NSInteger)userId;
@end

