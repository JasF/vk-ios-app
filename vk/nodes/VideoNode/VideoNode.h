//
//  VideoNode.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Video.h"
#import "PostBaseNode.h"

@interface VideoNode : PostBaseNode
- (id)initWithVideo:(Video *)video;
@end
