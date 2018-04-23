//
//  PhotoNode.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Photo.h"

@interface PhotoNode : ASCellNode
- (id)initWithPhoto:(Photo *)photo;
@end
