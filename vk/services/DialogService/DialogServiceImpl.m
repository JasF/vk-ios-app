//
//  DialogServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogServiceImpl.h"

@interface DialogServiceImpl ()
@property id<DialogServiceHandlerProtocol> handler;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(results[@"items"]);
            }
        });
    });
}

@end
