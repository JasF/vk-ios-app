//
//  PhotoAlbumNode.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumNode.h"
#import "TextStyles.h"

static CGFloat const kTextMargin = 6.f;

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
        _sizeNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", @(photoAlbum.size), L(@"photoalbum_photos")] attributes:[TextStyles timeStyle]];
        _sizeNode.maximumNumberOfLines = 1;
        _sizeNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_sizeNode];
        
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:photoAlbum.title attributes:[TextStyles titleStyle]];
        //_textNode.maximumNumberOfLines = 1;
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.URL = [NSURL URLWithString:[SizedPhoto getWithType:@"x" array:photoAlbum.sizes].src];
        [self addSubnode:_imageNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *sizeSpec = [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:0.0
     justifyContent:ASStackLayoutJustifyContentCenter
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_sizeNode]];
    sizeSpec.style.spacingBefore = kTextMargin;
    
    ASRatioLayoutSpec *ratioSpec = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:1.f child:_imageNode];
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, kTextMargin, 0, kTextMargin) child:_textNode];
    spec.style.flexGrow = 1.f;
    _sizeNode.style.spacingBefore = kTextMargin;
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[sizeSpec, ratioSpec, spec]];
    _textNode.style.flexGrow = 1.f;
    avatarContentSpec.style.flexGrow = 1.f;
    
    return avatarContentSpec;
}

@end
