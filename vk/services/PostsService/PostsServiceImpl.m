//
//  PostsServiceImpl.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsServiceImpl.h"
#import "Comment.h"

@import EasyMapping;

@implementation PostsServiceImpl

- (void)likeActionWithItem:(id)item {
    
}

- (void)repostActionWithItem:(id)item {
    
}

- (NSArray *)parseComments:(NSDictionary *)comments {
    if (![comments isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSDictionary *commentsResponse = comments[@"comments"];
    if (![commentsResponse isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *commentsData = commentsResponse[@"items"];
    if (![commentsData isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray *results = [EKMapper arrayOfObjectsFromExternalRepresentation:commentsData
                                                              withMapping:[Comment objectMapping]];
    return results;
}

- (void)consumer:(id<PostsServiceConsumer>)consumer likeActionWithItem:(id)item { 
    
}

- (void)consumer:(id<PostsServiceConsumer>)consumer repostActionWithItem:(id)item { 
    
}

@end
