//
//  PostsViewModelImpl.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPost.h"
#import "PostsViewModelImpl.h"
#import "PostsService.h"

@interface PostsViewModelImpl () <PostsViewModel>
@property id<PyPostsViewModel> handler;
@end

@implementation PostsViewModelImpl

#pragma mark - Initialization
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [super init]) {
        _handler = [handlersFactory postsViewModelHandlerWithDelegate:self];
    }
    return self;
}

#pragma mark - PostsViewModel
- (void)likeActionWithItem:(id)item completion:(void(^)(NSInteger likesCount, BOOL liked, BOOL error))completion {
    dispatch_python(^{
        NSInteger ownerId = 0;
        NSInteger itemId = 0;
        NSString *type = nil;
        BOOL liked = NO;
        NSString *accessKey = @"";
        Likes *likesObject = nil;
        if ([item isKindOfClass:[WallPost class]]) {
            WallPost *post = (WallPost *)item;
            likesObject = post.likes;
            type = @"post";
            ownerId = post.owner_id;
            itemId = post.identifier;
            liked = likesObject.user_likes;
        }
        NSCAssert(type && ownerId && itemId, @"Unhandled item type for like");
        if (!type || !ownerId || !itemId) {
            return;
        }
        NSDictionary *response = [self.handler likeObjectWithType:type
                                                          ownerId:@(ownerId)
                                                           itemId:@(itemId)
                                                        accessKey:accessKey
                                                             like:@(!liked)];
        NSInteger likes = 0;
        BOOL error = YES;
        if ([response isKindOfClass:[NSDictionary class]]) {
            NSNumber *likesValue = response[@"likes"];
            if ([likesValue isKindOfClass:[NSNumber class]]) {
                likes = likesValue.integerValue;
                error = NO;
            }
        }
        if (!error) {
            likesObject.user_likes = !liked;
            likesObject.count = likes;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(likes, !liked, error);
            }
        });
    });
}

- (void)repostActionWithItem:(id)item {
    
}

@end
