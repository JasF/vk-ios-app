//
//  CommentNode.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "User.h"

@class CommentNode;
@protocol CommentNodeDelegate <NSObject>
- (void)commentNode:(CommentNode *)node tappedOnUser:(User *)user;
@end

@class Comment;
@interface CommentNode : ASCellNode
@property (weak, nonatomic) id<CommentNodeDelegate> delegate;
- (id)initWithComment:(Comment *)comment;
@end
