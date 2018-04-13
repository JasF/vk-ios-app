//
//  WallServiceImpl.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "WallServiceImpl.h"
#import "WallPost.h"
#import "User.h"

@interface WallServiceImpl ()
@property id<WallServiceHandlerProtocol> handler;
@end

@implementation WallServiceImpl

#pragma mark - Initialization
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [self init]) {
        _handler = [handlersFactory wallServiceHandler];
    }
    return self;
}

#pragma mark - WallService
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSDictionary *wallData = [self.handler getWall:@(offset)];
        [self processWallData:wallData
                   completion:completion];
    });
}


- (void)setHistoryFromArray:(NSMutableArray *)array toPost:(WallPost *)post {
    WallPost *history = [array firstObject];
    if (!history) {
        return;
    }
    [array removeObjectAtIndex:0];
    post.history = @[history];
    [self setHistoryFromArray:array toPost:history];
}

- (void)processWallData:(NSDictionary *)wallData
             completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSCAssert([wallData isKindOfClass:[NSDictionary class]] || !wallData, @"wallData unknown type");
        if (![wallData isKindOfClass:[NSDictionary class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil);
                }
            });
            return;
        }
        NSDictionary *response = wallData[@"response"];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(posts);
            }
        });
    });
}


@end
