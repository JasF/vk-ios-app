//
//  PostBaseNode.h
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "LikesNode.h"
#import "CommentsNode.h"
#import "RepostNode.h"

@interface PostBaseNode : ASCellNode
- (id)initWithEmbedded:(BOOL)embedded likesCount:(NSInteger)likesCount liked:(BOOL)liked repostsCount:(NSInteger)repostsCount reposted:(BOOL)reposted commentsCount:(NSInteger)commentsCount;
- (ASLayoutSpec *)controlsStack;
@property (strong, nonatomic) LikesNode *likesNode;
@property (strong, nonatomic) CommentsNode *commentsNode;
@property (strong, nonatomic) RepostNode *repostNode;
@end
