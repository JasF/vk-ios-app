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

@implementation PhotoNode {
    Photo *_photo;
    BOOL _asGallery;
}

- (id)initWithPhoto:(Photo *)photo {
    NSCParameterAssert(photo);
    _asGallery = photo.asGallery.boolValue;
    if (self = [super initWithEmbedded:_asGallery likesCount:photo.likes.count liked:photo.likes.user_likes repostsCount:-1 reposted:photo.reposts.user_reposted commentsCount:-1]) {
        _photo = photo;
        self.item = photo;
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        if (_asGallery) {
            _imageNode.URL = [NSURL URLWithString:photo.photo_130];
        }
        else {
            _imageNode.URL = [NSURL URLWithString:photo.photo_807];
        }
        [self addSubnode:_imageNode];
        _imageNode.layerBacked = YES;
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    CGFloat aspectRatio = 1.f;
    if (_photo.height > 0 && _photo.width > 0) {
        aspectRatio = _photo.height/_photo.width;
    }
    ASRatioLayoutSpec *ratioSpec = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:(_asGallery) ? 1.f : aspectRatio child:_imageNode];
    ratioSpec.style.flexShrink = 1.0f;
    ratioSpec.style.flexGrow = 1.0f;
    ASLayoutSpec *controlsStack = [self controlsStack];
    if (controlsStack) {
        controlsStack.style.spacingBefore = 12.f;
        controlsStack.style.spacingAfter = 12.f;
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
