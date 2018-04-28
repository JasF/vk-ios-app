//
//  AnswersServiceImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AnswersServiceImpl.h"

@implementation AnswersServiceImpl

- (NSArray<Answer *> *)parse:(NSDictionary *)photosData {
    if (![photosData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *response = photosData[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = response[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *users = photosData[@"users"];
    NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                   withMapping:[User objectMapping]];
    NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
    for (User *user in usersObjects) {
        [usersDictionary setObject:user forKey:@(user.id)];
    }
    
    NSMutableArray *objects = [NSMutableArray new];
    for (NSDictionary *representation in items) {
        Answer *answer = [Answer new];
        if (![answer fillWithRepresentation:representation users:usersDictionary]) {
            continue;
        }
        [objects addObject:answer];
    }
    
    return objects;
}

@end
