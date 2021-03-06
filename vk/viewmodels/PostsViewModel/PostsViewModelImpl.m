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
#import "Oxy_Feed-Swift.h"

@protocol PyPostsViewModelDelegate <NSObject>
- (void)copyUrl:(NSString *)url;
- (void)hideOptionsNode;
- (void)commentDeleted;
- (NSString *)localize:(NSString *)string;
@end

@interface PostsViewModelImpl () <PostsViewModel>
@property id<PyPostsViewModel> handler;
@property id<PostsService> postsService;
@property (strong, nonatomic) NSIndexPath *optionsCellIndexPath;
@property (strong, nonatomic) id optionsParentItem;
@end

@implementation PostsViewModelImpl

@synthesize delegate = _delegate;

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
        DDLogInfo(@"resp: %@", response);
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
    if ([model isKindOfClass:[VideoModel class]]) {
        VideoModel *vm = (VideoModel *)model;
        model = vm.video;
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
        DDLogInfo(@"Response from send comment is: %@", response);
        /*
         2018-05-01 14:33:31.078273+0300 vk[73878:19462853] Response from send comment is: {
         "comment_id" = 1971;
         }
         */
    });
}

- (void)tappedOnPost:(WallPost *)post {
    dispatch_python(^{
        [_handler tappedOnPostWithOwnerId:@(post.getOwnerId) postId:@(post.identifier)];
    });
}

- (void)tappedOnPhotoWithIndex:(NSInteger)index withPost:(WallPost *)post {
    dispatch_python(^{
        [_handler tappedOnPhotoWithIndex:@(index) withPostId:@(post.identifier) ownerId:@(post.owner_id)];
    });
}

- (void)tappedOnPhotoItemWithIndex:(NSInteger)index withPost:(WallPost *)post {
    dispatch_python(^{
        [_handler tappedOnPhotoItemWithIndex:@(index) withPostId:@(post.identifier) ownerId:@(post.owner_id)];
    });
}

- (void)tappedOnVideo:(Video *)video {
    dispatch_python(^{
        NSDictionary *representation = [EKSerializer serializeObject:video
                                                         withMapping:[Video objectMapping]];
        [self.handler tappedOnVideoWithId:@(video.id) ownerId:@(video.owner_id) representation:representation];
    });
}

- (void)optionsTappedWithPost:(WallPost *)post indexPath:(NSIndexPath *)indexPath {
    self.optionsCellIndexPath = indexPath;
    BOOL isNewsViewController = NO;
    if ([self.delegate respondsToSelector:@selector(isNewsViewController)]) {
        isNewsViewController = [self.delegate isNewsViewController];
    }
    dispatch_python(^{
        [self.handler optionsTappedWithPostId:@(post.identifier)
                                      ownerId:@(post.owner_id)
                         isNewsViewController:@(isNewsViewController)];
    });
}

- (void)tappedOnComment:(Comment *)comment
             parentItem:(id)parentItem
                   type:(NSString *)type
              indexPath:(NSIndexPath *)indexPath {
    NSCParameterAssert(comment);
    NSCParameterAssert(parentItem);
    NSCParameterAssert(type);
    NSNumber *ownerId = nil;
    if ([parentItem isKindOfClass:[WallPost class]]) {
        WallPost *post = (WallPost *)parentItem;
        ownerId = @(post.getOwnerId);
    }
    else if ([parentItem isKindOfClass:[Photo class]]) {
        Photo *photo = (Photo *)parentItem;
        ownerId = @(photo.owner_id);
    }
    else if ([parentItem isKindOfClass:[Video class]]) {
        Video *video = (Video *)parentItem;
        ownerId = @(video.owner_id);
    }
    NSCAssert(ownerId, @"cannot determine owner_id from: %@", parentItem);
    if (!ownerId) {
        return;
    }
    _optionsParentItem = parentItem;
    _optionsCellIndexPath = indexPath;
    dispatch_python(^{
        [self.handler tappedOnCommentWithOwnerId:@(comment.from_id)
                                       commentId:@(comment.id)
                                            type:type
                               parentItemOwnerId:ownerId];
    });
}

#pragma mark - PyPostsViewModelDelegate
- (void)copyUrl:(NSString *)url {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = url;
}

- (void)hideOptionsNode {
    NSCAssert(_optionsCellIndexPath, @"options node index path missing");
    NSIndexPath *indexPath = _optionsCellIndexPath;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(hideNodeAtIndexPath:)]) {
            [self.delegate hideNodeAtIndexPath:indexPath];
        }
    });
    _optionsCellIndexPath = nil;
}

- (void)commentDeleted {
    NSIndexPath *indexPath = _optionsCellIndexPath;
    
    if ([_optionsParentItem isKindOfClass:[WallPost class]]) {
        WallPost *post = (WallPost *)_optionsParentItem;
        post.comments.count = post.comments.count - 1;
    }
    else if ([_optionsParentItem isKindOfClass:[Photo class]]) {
        Photo *photo = (Photo *)_optionsParentItem;
        photo.comments.count = photo.comments.count - 1;
    }
    else if ([_optionsParentItem isKindOfClass:[Video class]]) {
        Video *video = (Video *)_optionsParentItem;
        video.comments = video.comments - 1;
    }
    else {
        NSCAssert(false, @"unknown parent item for deleted comment");
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(hideNodeAtIndexPath:)]) {
            [self.delegate hideNodeAtIndexPath:indexPath];
        }
    });
    _optionsCellIndexPath = nil;
    _optionsParentItem = nil;
}

- (NSString *)localize:(NSString *)string {
    return L(string);
}

- (void)optionsTappedWithPhoto:(Photo *)photo {
    NSCParameterAssert(photo);
    if (!photo) {
        return;
    }
    dispatch_python(^{
        [self.handler optionsTappedWithPhotoId:@(photo.id) ownerId:@(photo.owner_id)];
    });
}

- (void)optionsTappedWithUser:(User *)user {
    NSCParameterAssert(user);
    if (!user) {
        return;
    }
    dispatch_python(^{
        [self.handler optionsTappedWithUserId:@(user.id)];
    });
}

- (void)optionsTappedWithVideo:(Video *)video {
    NSCParameterAssert(video);
    if (!video) {
        return;
    }
    dispatch_python(^{
        [self.handler optionsTappedWithVideoId:@(video.id) ownerId:@(video.owner_id)];
    });
}

@end
