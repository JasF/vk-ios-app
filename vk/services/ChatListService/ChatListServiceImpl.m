//
//  ChatListServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatListServiceImpl.h"
#import "User.h"

@interface ChatListServiceImpl ()
@end

@implementation ChatListServiceImpl

#pragma mark - Initialization
- (id)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark - ChatListService
- (NSArray<Dialog *> *)parse:(NSDictionary *)dialogsData {
    NSCAssert([dialogsData isKindOfClass:[NSDictionary class]] || !dialogsData, @"wallData unknown type");
    if (![dialogsData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *response = dialogsData[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *users = dialogsData[@"users"];
    NSArray *items = response[@"items"];
    
    NSArray *dialogs = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                              withMapping:[Dialog objectMapping]];
    
    NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                   withMapping:[User objectMapping]];
    
    NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
    for (User *user in usersObjects) {
        [usersDictionary setObject:user forKey:@(user.identifier)];
    }
    
    for (Dialog *dialog in dialogs) {
        User *user = usersDictionary[@(ABS(dialog.message.user_id))];
        if (user) {
            dialog.username = [user nameString];
            dialog.avatarURLString = user.photo_100;
        }
    }
    
    return dialogs;
}

@end
