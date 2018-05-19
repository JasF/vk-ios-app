//
//  PostsViewController.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewController.h"
#import "WallPostNode.h"
#import "CommentNode.h"
#import "WallPost.h"
#import "Oxy_Feed-Swift.h"
#import "DialogNode.h"


@interface PostsViewController () <ASTableDelegate, PostsService, WallPostNodeDelegate, CommentNodeDelegate, DialogNodeDelegate>
@end

@implementation PostsViewController

#pragma mark - ASTableDelegate
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)aNode {
    if ([aNode isKindOfClass:[DialogNode class]]) {
        DialogNode *node = (DialogNode *)aNode;
        node.delegate = self;
    }
    else if ([aNode isKindOfClass:[WallPostNode class]]) {
        WallPostNode *node = (WallPostNode *)aNode;
        node.delegate = self;
    }
    else if ([aNode isKindOfClass:[CommentNode class]]) {
        CommentNode *node = (CommentNode *)aNode;
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
    [super tableNode:tableNode didSelectRowAtIndexPath:indexPath];
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
            
            [self.tableNode performBatchUpdates:^{
                NSInteger section = [self.tableNode numberOfSections] - 1;
                NSMutableArray *indexPathes = [NSMutableArray new];
                for (int i=0;i<comments.count;++i) {
                    [indexPathes addObject:[NSIndexPath indexPathForRow:i inSection:section]];
                }
                [self.tableNode insertRowsAtIndexPaths:indexPathes withRowAnimation:UITableViewRowAnimationFade];
                [self.objectsArray insertObjects:comments atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, comments.count)]];
                [self numberOfCommentsDidUpdated:self.objectsArray.count];
                [self performBatchAnimated:YES];
            }
                                     completion:^(BOOL c) {
                                         self.commentsPreloading = NO;
                                     }];
        }];
    }
    
    if (indexPath.section < [tableNode numberOfSections] - 1) {
        return;
    }
    if ([cellNode isKindOfClass:[WallPostNode class]]) {
        WallPostNode *postNode = (WallPostNode *)cellNode;
        WallPost *post = postNode.post;
        if (post) {
            [_postsViewModel tappedOnPost:post];
        }
    }
}

- (void)numberOfCommentsDidUpdated:(NSInteger)numberOfComments {
    
}

#pragma mark - WallPostNodeDelegate
- (void)titleNodeTapped:(WallPost *)post {
    if ([_postsViewModel respondsToSelector:@selector(titleNodeTapped:)]) {
        [_postsViewModel titleNodeTapped:post];
    }
}

- (void)postNode:(WallPostNode *)node tappedOnPhotoWithIndex:(NSInteger)index withPost:(WallPost *)post {
    if ([_postsViewModel respondsToSelector:@selector(tappedOnPhotoWithIndex:withPost:)]) {
        [_postsViewModel tappedOnPhotoWithIndex:index withPost:post];
    }
}

- (void)postNode:(WallPostNode *)node tappedOnPhotoItemWithIndex:(NSInteger)index withPost:(WallPost *)post {
    if ([_postsViewModel respondsToSelector:@selector(tappedOnPhotoItemWithIndex:withPost:)]) {
        [_postsViewModel tappedOnPhotoItemWithIndex:index withPost:post];
    }
}

- (void)postNode:(WallPostNode *)node tappedOnVideo:(Video *)video {
    if ([_postsViewModel respondsToSelector:@selector(tappedOnVideo:)]) {
        [_postsViewModel tappedOnVideo:video];
    }
}

- (void)postNode:(WallPostNode *)node optionsTappedWithPost:(WallPost *)post {
    if ([_postsViewModel respondsToSelector:@selector(optionsTappedWithPost:)]) {
        [_postsViewModel optionsTappedWithPost:post];
    }
}

#pragma mark - CommentNodeDelegate
- (void)commentNode:(CommentNode *)node
       tappedOnUser:(User *)user {
    if ([_postsViewModel respondsToSelector:@selector(tappedOnCellWithUser:)]) {
        [_postsViewModel tappedOnCellWithUser:user];
    }
}

- (void)dialogNode:(DialogNode *)node tappedWithUser:(User *)user {
    if ([_postsViewModel respondsToSelector:@selector(tappedOnCellWithUser:)]) {
        [_postsViewModel tappedOnCellWithUser:user];
    }
}

@end
