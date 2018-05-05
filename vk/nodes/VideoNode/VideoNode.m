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
#import "vk-Swift.h"

static CGFloat const kMargin = 8.f;
static CGFloat const kSpacing = 0;
static CGFloat const kImageWidth = 120.f;
static CGFloat const kImageHeight = 90.f;


@interface VideoNode ()
@property ASTextNode *titleNode;
@property ASNetworkImageNode *imageNode;
@property ASTextNode *timeNode;
@property ASTextNode *viewsNode;
@end

@implementation VideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super init]) {
        _titleNode = [[ASTextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:video.title attributes:[TextStyles nameStyle]];
        _titleNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_titleNode];
        
        _imageNode = [[ASNetworkImageNode alloc] init];
        _imageNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _imageNode.URL = [NSURL URLWithString:video.imageURL];
        _imageNode.style.width = ASDimensionMake(kImageWidth);
        _imageNode.style.height = ASDimensionMake(kImageHeight);
        [self addSubnode:_imageNode];
        
        _timeNode = [[ASTextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:video.date];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:[date utils_longDayDifferenceFromNow] attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        _viewsNode = [[ASTextNode alloc] init];
        _viewsNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@", L(@"video_views"), @(video.views)]
                                                                    attributes:[TextStyles timeStyle]];
        [self addSubnode:_viewsNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *titleSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kSpacing
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[_titleNode]];
    
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:kSpacing
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[titleSpec, _timeNode, _viewsNode]];
    _titleNode.style.flexShrink = 1.f;
    nameVerticalStack.style.flexShrink = 1.f;
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kMargin
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_imageNode, nameVerticalStack]];
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin) child:avatarContentSpec];
    return spec;
}

@end
