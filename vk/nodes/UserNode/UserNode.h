//
//  UserNode.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class User;

@interface UserNode : ASCellNode
- (id)initWithUser:(User *)user;
@end
