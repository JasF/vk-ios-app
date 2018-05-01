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
        Likes *likesObject = nil;
        [self invokePayloadWithModel:item type:&type ownerId:&ownerId postId:&itemId commentsCount:nil likes:&likesObject reposts:nil];
        liked = likesObject.user_likes;
        if (!type || !ownerId || !itemId) {
            return;
        }
        NSDictionary *response = [self.handler likeObjectWithType:type
                                                          ownerId:@(ownerId)
                                                           itemId:@(itemId)
                                                        accessKey:@""
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
        NSInteger ownerId = 0;
        NSInteger itemId = 0;
        [self invokePayloadWithModel:item type:&identifier ownerId:&ownerId postId:&itemId commentsCount:nil likes:&likesObject reposts:&repostsObject];
        if (!identifier) {
            return;
        }
        identifier = [NSString stringWithFormat:@"%@%@_%@", identifier, @(ownerId), @(itemId)];
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
        NSString *type=nil;
        NSInteger ownerId=0;
        NSInteger postId=0;
        NSInteger count=0;
        [self invokePayloadWithModel:model type:&type ownerId:&ownerId postId:&postId commentsCount:&count likes:nil reposts:nil];
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

- (void)invokePayloadWithModel:(id)model
                          type:(NSString **)sType
                       ownerId:(NSInteger *)sOwnerId
                        postId:(NSInteger *)sPostId
                 commentsCount:(NSInteger *)sCommentsCount
                         likes:(Likes **)sLikes
                       reposts:(Reposts **)sReposts {
    NSCAssert(sType && sOwnerId && sPostId, @"required storage missing");
    if ([model isKindOfClass:[CommentsPreloadModel class]]) {
        CommentsPreloadModel *cpm = (CommentsPreloadModel *)model;
        if (cpm.post) {
            model = cpm.post;
        }
        else if (cpm.photo) {
            model = cpm.photo;
        }
        else if (cpm.video) {
            model = cpm.video;
        }
        else {
            NSCAssert(false, @"Unknown condition for CommentsPreloadModel");
            return;
        }
    }
    NSString *type = nil;
    NSInteger ownerId = 0;
    NSInteger postId = 0;
    NSInteger count = 0;
    Likes *likes = nil;
    Reposts *reposts = nil;
    
    if ([model isKindOfClass:[WallPost class]]) {
        WallPost *post = (WallPost *)model;
        type = @"wall";
        ownerId = post.owner_id;
        postId = post.identifier;
        count = post.comments.count;
        likes = post.likes;
        reposts = post.reposts;
    }
    else if ([model isKindOfClass:[Photo class]]) {
        Photo *photo = (Photo *)model;
        type = @"photo";
        ownerId = photo.owner_id;
        postId = photo.id;
        count = photo.comments.count;
        likes = photo.likes;
        reposts = photo.reposts;
    }
    else if ([model isKindOfClass:[Video class]]) {
        Video *video = (Video *)model;
        type = @"video";
        ownerId = video.owner_id;
        postId = video.id;
        count = video.comments;
        likes = video.likes;
        reposts = video.reposts;
    }
    else {
        NSCAssert(false, @"Unknown condition for model");
        return;
    }
    if (sType) {
        *sType = type;
    }
    if (sOwnerId) {
        *sOwnerId = ownerId;
    }
    if (sPostId) {
        *sPostId = postId;
    }
    if (sCommentsCount) {
        *sCommentsCount = count;
    }
    if (sLikes) {
        *sLikes = likes;
    }
    if (sReposts) {
        *sReposts = reposts;
    }
}

- (void)sendCommentWithText:(NSString *)text item:(id)item completion:(void(^)(NSInteger commentId, NSInteger ownerId, NSInteger postId, NSInteger reply_to_commentId, User *user))completion {
    dispatch_python(^{
        NSString *type=nil;
        NSInteger ownerId=0;
        NSInteger postId=0;
        [self invokePayloadWithModel:item type:&type ownerId:&ownerId postId:&postId commentsCount:nil likes:nil reposts:nil];
        if (!type.length || !ownerId || !postId) {
            return;
        }
        NSDictionary *response = [self.handler sendCommentWithType:type ownerId:@(ownerId) postId:@(postId) text:text];
        NSInteger commentId = 0;
        User *user = nil;
        if ([response isKindOfClass:[NSDictionary class]]) {
            commentId = [response[@"comment_id"] integerValue];
            user = [self.postsService parseUserInfo:response[@"user_info"]];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(commentId, ownerId, postId, 0, user);
            }
        });
        NSLog(@"Response from send comment is: %@", response);
        /*
         2018-05-01 14:33:31.078273+0300 vk[73878:19462853] Response from send comment is: {
         "comment_id" = 1971;
         }
         */
    });
    
}

@end
