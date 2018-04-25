//
//  PostVideoNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostVideoNode.h"
#import "TextStyles.h"

@interface PostVideoNode () <ASNetworkImageNodeDelegate>
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
@property (strong, nonatomic) ASTextNode *titleNode;
@property (strong, nonatomic) ASTextNode *viewsNode;
@end

@implementation PostVideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super init]) {
        
        _titleNode = [[ASTextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:video.title ?: @"" attributes:[TextStyles titleStyle]];
        _titleNode.maximumNumberOfLines = 0;
        [self addSubnode:_titleNode];
        
        _viewsNode = [[ASTextNode alloc] init];
        _viewsNode.attributedText = [[NSAttributedString alloc] initWithString:[self viewsStringWithCount:video.views] attributes:[TextStyles descriptionStyle]];
        _viewsNode.maximumNumberOfLines = 0;
        [self addSubnode:_viewsNode];
        
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        node.cornerRadius = 4.0;
        node.URL = [NSURL URLWithString:video.imageURL];
        node.delegate = self;
        node.imageModificationBlock = ^UIImage *(UIImage *image) {
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.0] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            return modifiedImage;
            
        };
        [self addSubnode:node];
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
        key = L(@"views_ov");
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
    ASRatioLayoutSpec *imagePlace =
    [ASRatioLayoutSpec
     ratioLayoutSpecWithRatio:0.5f
     child:_mediaNode];
    imagePlace.style.spacingAfter = 8.0;
    imagePlace.style.spacingBefore = 3.0;
    
    _viewsNode.style.spacingAfter = 8.0;
    
    ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:0.0
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStart
                                      children:@[imagePlace, _titleNode, _viewsNode]];
    
    return contentSpec;
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
