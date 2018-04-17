//
//  WallServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallServiceImpl.h"
#import "WallPost.h"
#import "User.h"

@implementation WallServiceImpl

#pragma mark - Private Methods
- (void)setHistoryFromArray:(NSMutableArray *)array toPost:(WallPost *)post {
    WallPost *history = [array firstObject];
    if (!history) {
        return;
    }
    [array removeObjectAtIndex:0];
    post.history = @[history];
    [self setHistoryFromArray:array toPost:history];
}

#pragma mark - WallService
- (NSArray<WallPost *> *)parse:(NSDictionary *)wallData {
    NSCAssert([wallData isKindOfClass:[NSDictionary class]] || !wallData, @"wallData unknown type");
    if (![wallData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *response = wallData[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *users = wallData[@"users"];
    NSArray *items = response[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        items = @[];
    }
    
    NSArray *posts = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                            withMapping:[WallPost objectMapping]];
    
    NSArray *usersObjects = [EKMapper arrayOfObjectsFromExternalRepresentation:users
                                                                   withMapping:[User objectMapping]];
    
    NSMutableDictionary *usersDictionary = [NSMutableDictionary new];
    for (User *user in usersObjects) {
        [usersDictionary setObject:user forKey:@(user.identifier)];
    }
    
    void (^updatePostBlock)(WallPost *post) = ^void(WallPost *post) {
        User *user = usersDictionary[@(ABS(post.from_id))];
        if (user) {
            post.firstName = [user nameString];
            post.avatarURLString = user.photo_100;
        }
    };
    for (WallPost *post in posts) {
        updatePostBlock(post);
        for (WallPost *history in post.history) {
            updatePostBlock(history);
        }
        NSMutableArray *mutableHistory = [post.history mutableCopy];
        [self setHistoryFromArray:mutableHistory toPost:post];
    }
    return posts;
}

@end
