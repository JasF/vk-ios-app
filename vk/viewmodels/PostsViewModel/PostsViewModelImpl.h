//
//  PostsViewModelImpl.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewModel.h"
#import "HandlersFactory.h"

@protocol PyPostsViewModel <NSObject>
- (NSDictionary *)likeObjectWithType:(NSString *)type ownerId:(NSNumber *)ownerId itemId:(NSNumber *)itemId accessKey:(NSString *)accessKey like:(NSNumber *)like;
- (NSDictionary *)repostObjectWithIdentifier:(NSString *)identifier;
@end

@interface PostsViewModelImpl : NSObject <PostsViewModel>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end