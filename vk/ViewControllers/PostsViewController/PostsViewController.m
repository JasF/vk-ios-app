//
//  PostsViewController.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewController.h"
#import "WallPostNode.h"
#import "WallPost.h"
#import "vk-Swift.h"

@interface PostsViewController () <ASTableDelegate, PostsService, WallPostNodeDelegate>
@property (nonatomic) BOOL commentsPreloading;
@end

@implementation PostsViewController

#pragma mark - ASTableDelegate
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)aNode {
    if ([aNode isKindOfClass:[WallPostNode class]]) {
        WallPostNode *node = (WallPostNode *)aNode;
        node.delegate = self;
    }
    if ([aNode conformsToProtocol:@protocol(PostsServiceConsumer)]) {
        id<PostsServiceConsumer> consumer = (id<PostsServiceConsumer>)aNode;
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

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ASCellNode *cellNode = [tableNode nodeForRowAtIndexPath:indexPath];
    if ([cellNode isKindOfClass:[AvatarNameDateNode class]]) {
        AvatarNameDateNode *node = (AvatarNameDateNode *)cellNode;
        [_postsViewModel tappedOnCellWithUser:node.user];
    }
    else if ([cellNode isKindOfClass:[CommentsPreloadNode class]]) {
        CommentsPreloadNode *node = (CommentsPreloadNode *)cellNode;
        if (self.commentsPreloading) {
            return;
        }
        self.commentsPreloading = YES;
        @weakify(self);
        [_postsViewModel tappedOnPreloadCommentsWithModel:node.model completion:^(NSArray *comments) {
            @strongify(self);
            NSLog(@"!");
            self.commentsPreloading = NO;
        }];
    }
}

#pragma mark - WallPostNodeDelegate
- (void)titleNodeTapped:(WallPost *)post {
    [_postsViewModel titleNodeTapped:post];
}

@end
