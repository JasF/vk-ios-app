//
//  PostsViewModelImpl.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewModel.h"
#import "HandlersFactory.h"
#import "PostsService.h"

@protocol PyPostsViewModel <NSObject>
- (NSDictionary *)likeObjectWithType:(NSString *)type ownerId:(NSNumber *)ownerId itemId:(NSNumber *)itemId accessKey:(NSString *)accessKey like:(NSNumber *)like;
- (NSDictionary *)repostObjectWithIdentifier:(NSString *)identifier;
- (void)titleNodeTapped:(NSNumber *)userId;
- (void)tappedOnCellWithUserId:(NSNumber *)userId;
- (NSDictionary *)preloadCommentsWithType:(NSString *)type
                                  ownerId:(NSNumber *)ownerId
                                   postId:(NSNumber *)postId
                                    count:(NSNumber *)count
                                   loaded:(NSNumber *)loaded;
- (NSDictionary *)sendCommentWithType:(NSString *)type
                              ownerId:(NSNumber *)ownerId
                               postId:(NSNumber *)postId
                                 text:(NSString *)text;
- (void)tappedOnPostWithOwnerId:(NSNumber *)ownerId
                         postId:(NSNumber *)identifier;
- (void)tappedOnPhotoWithIndex:(NSNumber *)index
                    withPostId:(NSNumber *)postId
                       ownerId:(NSNumber *)ownerId;
- (void)tappedOnPhotoItemWithIndex:(NSNumber *)index
                        withPostId:(NSNumber *)postId
                           ownerId:(NSNumber *)ownerId;
- (void)tappedOnVideoWithId:(NSNumber *)videoId
                    ownerId:(NSNumber *)ownerId
             representation:(NSDictionary *)representation;
- (void)optionsTappedWithPostId:(NSNumber *)postId
                        ownerId:(NSNumber *)ownerId
           isNewsViewController:(NSNumber *)isNewsViewController;
- (void)tappedOnCommentWithOwnerId:(NSNumber *)ownerId
                         commentId:(NSNumber *)commentId
                              type:(NSString *)type
                 parentItemOwnerId:(NSNumber *)parentItemOwnerId;
- (void)optionsTappedWithPhotoId:(NSNumber *)photoId
                         ownerId:(NSNumber *)ownerId;
- (void)optionsTappedWithVideoId:(NSNumber *)videoId
                         ownerId:(NSNumber *)ownerId;
- (void)optionsTappedWithUserId:(NSNumber *)userId;
@end

@interface PostsViewModelImpl : NSObject <PostsViewModel>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                 postsService:(id<PostsService>)postsService;
@end
