//
//  PostsViewModel.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WallPost;
@class User, CommentsPreloadModel;
@class Video;

@protocol PostsViewModel <NSObject>
- (void)likeActionWithItem:(id)item completion:(void(^)(NSInteger likesCount, BOOL liked, BOOL error))completion;
- (void)repostActionWithItem:(id)item completion:(void(^)(NSInteger likes, NSInteger reposts, BOOL error))completion;
- (void)titleNodeTapped:(WallPost *)post;
- (void)tappedOnCellWithUser:(User *)user;
- (void)tappedOnPreloadCommentsWithModel:(CommentsPreloadModel *)model completion:(void(^)(NSArray *comments))completion;
- (void)sendCommentWithText:(NSString *)text item:(id)item completion:(void(^)(NSInteger commentId, NSInteger ownerId, NSInteger postId, NSInteger reply_to_commentId, User *user))completion;
- (void)tappedOnPost:(WallPost *)post;
- (void)tappedOnPhotoWithIndex:(NSInteger)index withPost:(WallPost *)post;
- (void)tappedOnPhotoItemWithIndex:(NSInteger)index withPost:(WallPost *)post;
- (void)tappedOnVideo:(Video *)video;
@end
