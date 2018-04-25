//
//  VideoNode.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Video.h"

@interface VideoNode : ASCellNode
- (id)initWithVideo:(Video *)video;
@end
