//
//  PhotoAlbumNode.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumNode.h"
#import "TextStyles.h"

@interface PhotoAlbumNode ()
@property ASTextNode *textNode;
@property ASTextNode *sizeNode;
@property ASNetworkImageNode *imageNode;
@end

@implementation PhotoAlbumNode

- (id)initWithPhotoAlbum:(PhotoAlbum *)photoAlbum {
    NSCParameterAssert(photoAlbum);
    if (self = [super init]) {
        
        _sizeNode = [[ASTextNode alloc] init];
        _sizeNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ photos", @(photoAlbum.size)] attributes:[TextStyles nameStyle]];
        _sizeNode.maximumNumberOfLines = 1;
        _sizeNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_sizeNode];
        
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:photoAlbum.title attributes:[TextStyles titleStyle]];
        _textNode.maximumNumberOfLines = 1;
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.style.width = ASDimensionMakeWithPoints(44);
        _imageNode.style.height = ASDimensionMakeWithPoints(44);
        _imageNode.cornerRadius = 22.0;
        _imageNode.URL = [NSURL URLWithString:photoAlbum.thumb_src];
        [self addSubnode:_imageNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_sizeNode, spacer]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[topLineStack, _textNode]];
    
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
