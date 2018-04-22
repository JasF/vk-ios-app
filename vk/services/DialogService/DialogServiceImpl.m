//
//  DialogServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogServiceImpl.h"

@implementation DialogServiceImpl
#pragma mark - Private Methods
- (NSArray<Message *> *)parse:(NSDictionary *)results {

    if (![results isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *response = results[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = response[@"items"];
    NSArray *messages = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                               withMapping:[Message objectMapping]];

    return messages;
}

- (Message *)parseOne:(NSDictionary *)messageDictionary {
    if (![messageDictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    Message *message = [EKMapper objectFromExternalRepresentation:messageDictionary
                                                      withMapping:[Message objectMapping]];
    return message;
}

@end
