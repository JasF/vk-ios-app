//
//  PostsViewController.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewController.h"
#import "WallPostNode.h"

@interface PostsViewController () <ASTableDelegate, PostsService>
@end

@implementation PostsViewController

#pragma mark - ASTableDelegate
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)node {
    if ([node conformsToProtocol:@protocol(PostsServiceConsumer)]) {
        id<PostsServiceConsumer> consumer = (id<PostsServiceConsumer>)node;
        consumer.postsService = self;
    }
}

#pragma mark - PostsService
- (void)consumer:(id<PostsServiceConsumer>)consumer likeActionWithItem:(id)item {
    [_postsViewModel likeActionWithItem:item
                             completion:^(NSInteger likesCount, BOOL liked, BOOL error) {
                                 if (error) {
                                     return;
                                 }
                                 [consumer setLikesCount:likesCount liked:liked];
    }];
}

- (void)consumer:(id<PostsServiceConsumer>)consumer repostActionWithItem:(id)item {
    [_postsViewModel repostActionWithItem:item
                               completion:^(NSInteger likes, NSInteger reposts, BOOL error) {
                                   if (error) {
                                       return;
                                   }
                                   [consumer setLikesCount:likes liked:YES];
                                   [consumer setRepostsCount:reposts reposted:YES];
                               }];
}

@end