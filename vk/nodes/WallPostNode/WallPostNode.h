//
//  WallPostNode.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "NodeFactory.h"
#import "PostsService.h"
#import "PostBaseNode.h"

@class WallPost;
@class WallPostNode;

@protocol WallPostNodeDelegate <NSObject>
@required
- (void)titleNodeTapped:(WallPost *)post;
- (void)postNode:(WallPostNode *)node tappedOnPhotoWithIndex:(NSInteger)index withPost:(WallPost *)post;
@end

@interface WallPostNode : PostBaseNode
@property (strong, nonatomic) WallPost *post;
- (instancetype)initWithPost:(WallPost *)post
                 nodeFactory:(id<NodeFactory>)nodeFactory
                    embedded:(NSNumber *)embedded;
@property id<WallPostNodeDelegate> delegate;
@end
