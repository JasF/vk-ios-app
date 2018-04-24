//
//  PostImagesNode.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface PostImagesNode : ASDisplayNode
- (id)initWithAttachments:(NSArray *)attachments;
- (id)initWithPhotos:(NSArray *)photos;
@end
