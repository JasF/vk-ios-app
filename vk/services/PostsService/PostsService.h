//
//  PostsService.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@protocol PostsService;

@protocol PostsServiceConsumer <NSObject>
@property (weak) id<PostsService> postsService;
- (void)setLikesCount:(NSInteger)likes liked:(BOOL)liked;
@end

@protocol PostsService <NSObject>
- (void)consumer:(id<PostsServiceConsumer>)consumer likeActionWithItem:(id)item;
- (void)consumer:(id<PostsServiceConsumer>)consumer repostActionWithItem:(id)item;
@end
