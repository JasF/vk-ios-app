//
//  PostVideoNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostVideoNode.h"
#import "TextStyles.h"

@interface PostVideoNode () <A_SNetworkImageNodeDelegate>
@property (strong, nonatomic) A_SNetworkImageNode *mediaNode;
@property (strong, nonatomic) A_STextNode *titleNode;
@property (strong, nonatomic) A_STextNode *viewsNode;
@end

@implementation PostVideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super init]) {
        
        _titleNode = [[A_STextNode alloc] init];
        _titleNode.attributedText = [[NSAttributedString alloc] initWithString:video.title ?: @"" attributes:[TextStyles titleStyle]];
        _titleNode.maximumNumberOfLines = 0;
        [self addSubnode:_titleNode];
        
        _viewsNode = [[A_STextNode alloc] init];
        _viewsNode.attributedText = [[NSAttributedString alloc] initWithString:[self viewsStringWithCount:video.views] attributes:[TextStyles descriptionStyle]];
        _viewsNode.maximumNumberOfLines = 0;
        [self addSubnode:_viewsNode];
        
        A_SNetworkImageNode *node = [[A_SNetworkImageNode alloc] init];
        node.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
        node.cornerRadius = 4.0;
        node.URL = [NSURL URLWithString:video.photo_640];
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

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    A_SRatioLayoutSpec *imagePlace =
    [A_SRatioLayoutSpec
     ratioLayoutSpecWithRatio:0.5f
     child:_mediaNode];
    imagePlace.style.spacingAfter = 8.0;
    imagePlace.style.spacingBefore = 3.0;
    
    _viewsNode.style.spacingAfter = 8.0;
    
    A_SStackLayoutSpec *contentSpec = [A_SStackLayoutSpec
                                      stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                      spacing:0.0
                                      justifyContent:A_SStackLayoutJustifyContentStart
                                      alignItems:A_SStackLayoutAlignItemsStart
                                      children:@[imagePlace, _titleNode, _viewsNode]];
    
    return contentSpec;
}

#pragma mark - A_SNetworkImageNodeDelegate methods.
- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
