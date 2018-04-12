//
//  WallPostNode.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class WallPost;

@interface WallPostNode : ASCellNode

- (instancetype)initWithPost:(WallPost *)post;
- (instancetype)initWithPost:(WallPost *)post embedded:(BOOL)embedded;

@end
