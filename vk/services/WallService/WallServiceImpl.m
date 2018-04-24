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
        post.user = usersDictionary[@(ABS(post.validId))];
#ifdef DEBUG
        if ([post.user.first_name isEqualToString:@"Konstantin"]) {
            NSLog(@"!");
        }
#endif
    };
    void (^updateFriendsBlock)(WallPost *post) = ^void(WallPost *post) {
        NSMutableArray *friends = [NSMutableArray new];
        for (UserId *userId in post.friendsIds) {
            User *user = usersDictionary[@(userId.user_id)];
            if (user) {
                [friends addObject:user];
            }
            else {
                NSCAssert(user, @"User data must be exists");
            }
        }
        post.friends = friends;
    };
    NSMutableArray *results = [NSMutableArray new];
    NSArray *excludedTypes = @[@"wall_photo"];
    for (WallPost *post in posts) {
        if ([excludedTypes containsObject:post.type]) {
            continue;
        }
        [results addObject:post];
        updatePostBlock(post);
        if (post.friendsIds.count) {
            updateFriendsBlock(post);
        }
        for (WallPost *history in post.history) {
            updatePostBlock(history);
        }
        NSMutableArray *mutableHistory = [post.history mutableCopy];
        [self setHistoryFromArray:mutableHistory toPost:post];
    }
    return results;
}

- (User *)parseUserInfo:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return [EKMapper objectFromExternalRepresentation:data
                                          withMapping:[User objectMapping]];
}

@end
