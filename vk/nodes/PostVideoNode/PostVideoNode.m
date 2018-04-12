//
//  PostVideoNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "PostVideoNode.h"

@interface PostVideoNode () <ASNetworkImageNodeDelegate>
@property (strong, nonatomic) ASNetworkImageNode *mediaNode;
@end

@implementation PostVideoNode

- (id)initWithVideo:(Video *)video {
    if (self = [super init]) {
        ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
        node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
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

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASRatioLayoutSpec *imagePlace =
    [ASRatioLayoutSpec
     ratioLayoutSpecWithRatio:0.5f
     child:_mediaNode];
    imagePlace.style.spacingAfter = 3.0;
    imagePlace.style.spacingBefore = 3.0;
    return imagePlace;
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
