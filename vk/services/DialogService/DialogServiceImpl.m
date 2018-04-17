//
//  DialogServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogServiceImpl.h"

@interface DialogServiceImpl ()
@property id<PyDialogService> handler;
@end

@implementation DialogServiceImpl

#pragma mark - Initialization
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [self init]) {
        _handler = [handlersFactory dialogServiceHandler];
    }
    return self;
}

- (void)getMessagesWithOffset:(NSInteger)offset
                       userId:(NSInteger)userId
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    dispatch_python(^{
        NSDictionary *results = [_handler getMessages:@(0) userId:@(userId)];
        [self processResponse:results
                   completion:completion];
    });
}

- (void)getMessagesWithOffset:(NSInteger)offset
                       userId:(NSInteger)userId
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    dispatch_python(^{
        NSDictionary *results = [_handler getMessages:@(0) userId:@(userId) startMessageId:@(startMessageId)];
        [self processResponse:results
                   completion:^(NSArray<Message *> *messages) {
                       NSMutableArray *mutableMessages = [messages mutableCopy];
                       if (mutableMessages.count) {
                           [mutableMessages removeObjectAtIndex:0];
                       }
                       if (completion) {
                           completion(mutableMessages);
                       }
                   }];
    });
}

- (void)sendTextMessage:(NSString *)text
                 userId:(NSInteger)userId {
    [_handler sendTextMessage:text userId:@(userId)];
}

#pragma mark - Private Methods
- (void)processResponse:(NSDictionary *)results
             completion:(void(^)(NSArray<Message *> *messages))completion {
    if (![results isKindOfClass:[NSDictionary class]]) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSDictionary *response = results[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    NSArray *items = response[@"items"];
    NSArray *messages = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                               withMapping:[Message objectMapping]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(messages);
        }
    });
}
    
@end
