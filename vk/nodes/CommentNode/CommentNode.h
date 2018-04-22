//
//  CommentNode.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class Comment;
@interface CommentNode : ASCellNode
- (id)initWithComment:(Comment *)comment;
@end
