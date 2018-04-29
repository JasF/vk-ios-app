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
- (void)titleNodeTapped:(WallPost *)post;
@end

@interface WallPostNode : PostBaseNode
- (instancetype)initWithPost:(WallPost *)post
                 nodeFactory:(id<NodeFactory>)nodeFactory
                    embedded:(NSNumber *)embedded;
@property id<WallPostNodeDelegate> delegate;
@end
