//
//  VideoNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "VideoNode.h"
#import "TextStyles.h"
#import "UserNode.h"
#import "User.h"

extern CGFloat const kMargin;

@interface VideoNode ()
@property ASTextNode *titleNode;
@property ASNetworkImageNode *imageNode;
@end

@implementation VideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super initWithEmbedded:NO likesCount:video.likes.count liked:video.likes.user_likes repostsCount:video.reposts.count reposted:video.reposts.user_reposted commentsCount:video.comments]) {
        self.item = video;
        _titleNode = [[ASTextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:video.title attributes:[TextStyles nameStyle]];
        _titleNode.maximumNumberOfLines = 1;
        _titleNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_titleNode];
        
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.style.width = ASDimensionMakeWithPoints(44);
        _imageNode.style.height = ASDimensionMakeWithPoints(44);
        _imageNode.cornerRadius = 22.0;
        _imageNode.URL = [NSURL URLWithString:video.imageURL];
        [self addSubnode:_imageNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_titleNode]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[topLineStack]];
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_imageNode, nameVerticalStack]];
    
    
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
