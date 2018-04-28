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
    if (self = [super initWithEmbedded:NO likesCount:photo.likes.count liked:photo.likes.user_likes repostsCount:photo.reposts.count reposted:photo.reposts.user_reposted commentsCount:photo.comments.count]) {
        self.item = photo;
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.style.width = ASDimensionMakeWithPoints(66);
        _imageNode.style.height = ASDimensionMakeWithPoints(66);
        _imageNode.URL = [NSURL URLWithString:photo.photo_130];
        [self addSubnode:_imageNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_imageNode]];
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:avatarContentSpec];
    spec.style.flexShrink = 1.0f;
    spec.style.flexGrow = 1.0f;
    
    ASLayoutSpec *controlsStack = [self controlsStack];
    if (controlsStack) {
        ASStackLayoutSpec *subnodesStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                                                   spacing:0.0
                                                                            justifyContent:ASStackLayoutJustifyContentStart
                                                                                alignItems:ASStackLayoutAlignItemsStretch
                                                                                  children:@[spec, controlsStack]];
        subnodesStack.style.flexGrow = 1;
        
        return subnodesStack;
    }
    return spec;
}

@end
