//
//  AvatarNode.h
//  vk
//
//  Created by Jasf on 18.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "User.h"

@interface AvatarNode : ASNetworkImageNode
@property (readonly) User *user;
- (id)initWithUser:(User *)user;
@end
