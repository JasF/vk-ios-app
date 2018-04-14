//
//  WallPostNode.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Async_DisplayKit/Async_DisplayKit.h>
#import "NodeFactory.h"

@class WallPost;

@interface WallPostNode : A_SCellNode
- (instancetype)initWithPost:(WallPost *)post
                 nodeFactory:(id<NodeFactory>)nodeFactory
                    embedded:(NSNumber *)embedded;
@end
