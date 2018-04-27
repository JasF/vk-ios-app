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

@class WallPost;

@interface WallPostNode : ASCellNode <PostsService>
- (instancetype)initWithPost:(WallPost *)post
                 nodeFactory:(id<NodeFactory>)nodeFactory
                    embedded:(NSNumber *)embedded;
@end
