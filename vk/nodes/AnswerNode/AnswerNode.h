//
//  AnswerNode.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Answer.h"

@interface AnswerNode : ASCellNode
- (id)initWithAnswer:(Answer *)answer;
@end
