//
//  PostVideoNode.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Attachments.h"

@class Video;
@interface PostVideoNode : ASDisplayNode
@property (nonatomic, copy) void (^tappedOnVideoHandler)(Video *);
- (id)initWithVideo:(Video *)video;
@end
