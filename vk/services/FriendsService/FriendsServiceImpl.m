//
//  FriendsServiceImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "FriendsServiceImpl.h"

@implementation FriendsServiceImpl

- (NSArray<User *> *)parse:(NSDictionary *)friendsData {
    if (![friendsData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = friendsData[@"response"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray *messages = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                               withMapping:[User objectMapping]];
    
    return messages;
}

@end
