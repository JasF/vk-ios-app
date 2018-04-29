//
//  GroupsServiceImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GroupsServiceImpl.h"
#import "User.h"

@implementation GroupsServiceImpl

- (NSArray *)parse:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *response = data[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = response[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *users = data[@"users"];
    NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                   withMapping:[User objectMapping]];
    NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
    for (User *user in usersObjects) {
        [usersDictionary setObject:user forKey:@(user.id)];
    }
    
    //NSCAssert(usersObjects.count == items.count, @"Number of groups IDs and groups infos missmatch");
    NSMutableArray *results = [NSMutableArray new];
    for (NSNumber *groupId in items) {
        User *group = usersDictionary[groupId];
        if (group) {
            [results addObject:group];
        }
    }
    
    return results;
}

@end
