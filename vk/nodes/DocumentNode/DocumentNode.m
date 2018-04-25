//
//  DocumentNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DocumentNode.h"
#import "TextStyles.h"
#import "UserNode.h"
#import "User.h"

@interface DocumentNode ()
@property ASTextNode *titleNode;
@property ASNetworkImageNode *imageNode;
@end

@implementation DocumentNode

- (id)initWithDocument:(Document *)document {
    if (self = [super init]) {
        _titleNode = [[ASTextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:document.title attributes:[TextStyles nameStyle]];
        _titleNode.maximumNumberOfLines = 1;
        _titleNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_titleNode];
        
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.style.width = ASDimensionMakeWithPoints(44);
        _imageNode.style.height = ASDimensionMakeWithPoints(44);
        _imageNode.cornerRadius = 22.0;
        _imageNode.URL = [NSURL URLWithString:document.imageURL];
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
    return spec;
}

@end
