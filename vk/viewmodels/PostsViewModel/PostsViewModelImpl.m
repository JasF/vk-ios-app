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
#import "Video.h"
#import "Photo.h"
#import "vk-Swift.h"

@interface PostsViewModelImpl () <PostsViewModel>
@property id<PyPostsViewModel> handler;
@property id<PostsService> postsService;
@end

@implementation PostsViewModelImpl

#pragma mark - Initialization
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                 postsService:(id<PostsService>)postsService {
    NSCParameterAssert(handlersFactory);
    if (self = [super init]) {
        _handler = [handlersFactory postsViewModelHandlerWithDelegate:self];
        _postsService = postsService;
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
        if ([item isKindOfClass:[Video class]]) {
            Video *video = (Video *)item;
            type = @"video";
            likesObject = video.likes;
            ownerId = video.owner_id;
            itemId = video.id;
        }
        else if ([item isKindOfClass:[WallPost class]]) {
            WallPost *post = (WallPost *)item;
            likesObject = post.likes;
            type = @"post";
            ownerId = post.owner_id;
            itemId = post.identifier;
        }
        else if ([item isKindOfClass:[Photo class]]) {
            Photo *photo = (Photo *)item;
            likesObject = photo.likes;
            type = @"photo";
            ownerId = photo.owner_id;
            itemId = photo.id;
        }
        liked = likesObject.user_likes;
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

- (void)repostActionWithItem:(id)item completion:(void(^)(NSInteger likes, NSInteger reposts, BOOL error))completion {
    dispatch_python(^{
        NSString *identifier = nil;
        Reposts *repostsObject = nil;
        Likes *likesObject = nil;
        if ([item isKindOfClass:[WallPost class]]) {
            WallPost *post = (WallPost *)item;
            repostsObject = post.reposts;
            likesObject = post.likes;
            identifier = [NSString stringWithFormat:@"wall%@_%@", @(post.owner_id), @(post.identifier)];
        }
        else if ([item isKindOfClass:[Video class]]) {
            Video *video = (Video *)item;
            repostsObject = video.reposts;
            likesObject = video.likes;
            identifier = [NSString stringWithFormat:@"video%@_%@", @(video.owner_id), @(video.id)];
        }
        else if ([item isKindOfClass:[Photo class]]) {
            Photo *photo = (Photo *)item;
            likesObject = photo.likes;
            repostsObject = photo.reposts;
            identifier = [NSString stringWithFormat:@"photo%@_%@", @(photo.owner_id), @(photo.id)];
        }
        NSCAssert(identifier, @"Unhandled item type for repost");
        if (!identifier) {
            return;
        }
        NSDictionary *response = [self.handler repostObjectWithIdentifier:identifier];
        NSLog(@"resp: %@", response);
        NSInteger likes = 0;
        NSInteger reposts = 0;
        BOOL error = YES;
        if ([response isKindOfClass:[NSDictionary class]]) {
            NSNumber *likesValue = response[@"likes_count"];
            NSNumber *reposts_count = response[@"reposts_count"];
            if ([likesValue isKindOfClass:[NSNumber class]]) {
                likes = likesValue.integerValue;
            }
            if ([reposts_count isKindOfClass:[NSNumber class]]) {
                reposts = reposts_count.integerValue;
            }
            if ((likesValue || reposts_count) && response[@"success"]) {
                error = NO;
            }
        }
        if (!error) {
            likesObject.count = likes;
            likesObject.user_likes = YES;
            repostsObject.count = reposts;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(likes, reposts, error);
            }
        });
    });
}

- (void)titleNodeTapped:(WallPost *)post {
    dispatch_python(^{
        [_handler titleNodeTapped:@(post.owner_id)];
    });
}

- (void)tappedOnCellWithUser:(User *)user {
    dispatch_python(^{
        [_handler tappedOnCellWithUserId:@(user.id)];
    });
}

- (void)tappedOnPreloadCommentsWithModel:(CommentsPreloadModel *)model completion:(void(^)(NSArray *comments))completion {
    dispatch_python(^{
        NSString *type = nil;
        NSInteger ownerId = 0;
        NSInteger postId = 0;
        NSInteger count = 0;
        if (model.post) {
            type = @"post";
            ownerId = model.post.owner_id;
            postId = model.post.identifier;
            count = model.post.comments.count;
        }
        else if (model.video) {
            type = @"video";
            ownerId = model.video.owner_id;
            postId = model.video.id;
            count = model.video.comments;
        }
        else if (model.photo) {
            type = @"photo";
            ownerId = model.photo.owner_id;
            postId = model.photo.id;
            count = model.photo.comments.count;
        }
        NSCAssert(type.length && ownerId && postId, @"Unknown item with comments type");
        if (!type.length || !ownerId || !postId) {
            return;
        }
        
        NSDictionary *commentsData = [_handler preloadCommentsWithType:type
                                                               ownerId:@(ownerId)
                                                                postId:@(postId)
                                                                 count:@(count)
                                                                loaded:@(model.loaded)];
        NSArray *comments = [_postsService parseComments:commentsData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(comments);
            }
        });
    });
}

@end
