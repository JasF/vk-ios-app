//
//  PostVideoNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostVideoNode.h"
#import "TextStyles.h"

extern CGFloat const kMargin;
/*
@interface VideoNetworkImageNode : ASNetworkImageNode
@end

@implementation VideoNetworkImageNode
- (id)init {
    if (self = [super init]) {
    }
    return self;
}
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    ASCenterLayoutSpec *spec = [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:0 sizingOptions:0 child:_videoPlayNode];
    return spec;
}
@end
*/

@interface PostVideoNode () <ASNetworkImageNodeDelegate>
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
@property (strong, nonatomic) ASTextNode *titleNode;
@property (strong, nonatomic) ASTextNode *viewsNode;
@property (strong, nonatomic) ASImageNode *videoPlayNode;
@property Video *video;
@end

@implementation PostVideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super init]) {
        _video = video;
        _titleNode = [[ASTextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:video.title ?: @"" attributes:[TextStyles titleStyle]];
        _titleNode.maximumNumberOfLines = 0;
        [self addSubnode:_titleNode];
        
        _viewsNode = [[ASTextNode alloc] init];
        _viewsNode.attributedText = [[NSAttributedString alloc] initWithString:[self viewsStringWithCount:video.views] attributes:[TextStyles descriptionStyle]];
        _viewsNode.maximumNumberOfLines = 0;
        [self addSubnode:_viewsNode];
        
        _videoPlayNode = [ASImageNode new];
        _videoPlayNode.image = [UIImage imageNamed:@"video_play"];
        
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        node.URL = [NSURL URLWithString:video.imageURL];
        node.delegate = self;
        [node addTarget:self action:@selector(tappedOnVideo:) forControlEvents:ASControlNodeEventTouchUpInside];
        [self addSubnode:node];
        [self addSubnode:_videoPlayNode];
        _mediaNode = node;
    }
    return self;
}

- (NSString *)viewsStringWithCount:(NSInteger)count {
    NSString *key = nil;
    int part = count % 10;
    if ((count && part == 0) || (count >= 5 && count <= 20) || (part >= 5 && part <= 9)) {
        key = L(@"views_ov");
    }
    else if (part == 1) {
        key = L(@"views_");
    }
    else if (part >= 2 && part <= 4) {
        key = L(@"views_a");
    }
    else {
        NSCParameterAssert(false);
    }
    return [NSString stringWithFormat:@"%@ %@", @(count), key];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    CGFloat ratio = 240.f/320.f;
    if (_video.width > 0 && _video.height > 0) {
        ratio = (CGFloat)_video.height/(CGFloat)_video.width;
    }
    ASRatioLayoutSpec *imagePlace =
    [ASRatioLayoutSpec
     ratioLayoutSpecWithRatio:ratio
     child:_mediaNode];
    imagePlace.style.spacingAfter = 8.0;
    imagePlace.style.spacingBefore = 3.0;
    _viewsNode.style.spacingAfter = 8.0;
    
    ASCenterLayoutSpec *centerSpec = [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:0
                                                                                sizingOptions:0
                                                                                        child:_videoPlayNode];
    _videoPlayNode.contentMode = UIViewContentModeCenter;
    ASOverlayLayoutSpec *overlay = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:imagePlace
                                                                           overlay:centerSpec];
    
    ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:0.0
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStart
                                      children:@[overlay, _titleNode, _viewsNode]];
    ASStackLayoutSpec *spec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal spacing:0 justifyContent:ASStackLayoutJustifyContentStart alignItems:ASStackLayoutAlignItemsStart children:@[contentSpec]];
    spec.style.spacingBefore = kMargin;
    spec.style.spacingAfter = kMargin;
    return contentSpec;
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

#pragma mark - Observers
- (void)tappedOnVideo:(id)sender {
    if (_tappedOnVideoHandler) {
        _tappedOnVideoHandler(_video);
    }
}

@end
