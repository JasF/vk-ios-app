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
@end

@interface PostsViewModelImpl : NSObject <PostsViewModel>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                 postsService:(id<PostsService>)postsService;
@end
