//
//  WallUserNode.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class WallUser;
@interface WallUserNode : ASCellNode
- (id)initWithWallUser:(WallUser *)user;
@end
