//
//  PhotoNode.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoNode.h"

@interface PhotoNode ()
@property ASNetworkImageNode *imageNode;
@end

@implementation PhotoNode

- (id)initWithPhoto:(Photo *)photo {
    NSCParameterAssert(photo);
    if (self = [super initWithEmbedded:photo.asGallery.boolValue likesCount:photo.likes.count liked:photo.likes.user_likes repostsCount:photo.reposts.count reposted:photo.reposts.user_reposted commentsCount:photo.comments.count]) {
        self.item = photo;
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.URL = [NSURL URLWithString:photo.photo_130];
        [self addSubnode:_imageNode];
        _imageNode.layerBacked = YES;
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASRatioLayoutSpec *ratioSpec = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:1.f child:_imageNode];
    ratioSpec.style.flexShrink = 1.0f;
    ratioSpec.style.flexGrow = 1.0f;
    ASLayoutSpec *controlsStack = [self controlsStack];
    if (controlsStack) {
        ASStackLayoutSpec *subnodesStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                                                   spacing:0.0
                                                                            justifyContent:ASStackLayoutJustifyContentStart
                                                                                alignItems:ASStackLayoutAlignItemsStretch
                                                                                  children:@[ratioSpec, controlsStack]];
        subnodesStack.style.flexGrow = 1;
        return subnodesStack;
    }
    return ratioSpec;
}

@end
