//
//  PostsServiceImpl.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsServiceImpl.h"
#import "Oxy_Feed-Swift.h"
#import "Comment.h"

@import EasyMapping;

@interface PostsServiceImpl ()
@property id<CommentsService> commentsService;
@end

@implementation PostsServiceImpl

- (void)likeActionWithItem:(id)item {
    
}

- (void)repostActionWithItem:(id)item {
    
}

- (NSArray *)parseComments:(NSDictionary *)comments {
    NSCParameterAssert(_commentsService);
    return [_commentsService parseComments:comments];
}

- (User *)parseUserInfo:(NSDictionary *)userInfo {
    if (![userInfo isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    User *user = [EKMapper objectFromExternalRepresentation:userInfo withMapping:[User objectMapping]];
    return user;
}

- (void)consumer:(id<PostsServiceConsumer>)consumer likeActionWithItem:(id)item { 
    
}

- (void)consumer:(id<PostsServiceConsumer>)consumer repostActionWithItem:(id)item { 
    
}

@end
