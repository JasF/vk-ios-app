//
//  PostImagesNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostImagesNode.h"
#import "Attachments.h"
#import "A_SNetworkImageNode.h"
#import "A_SDisplayNodeExtras.h"

@interface PostImagesNode () <A_SNetworkImageNodeDelegate>
@end

@implementation PostImagesNode {
    NSMutableArray *_nodes;
    
}

- (id)initWithAttachments:(NSArray *)attachments {
    NSCParameterAssert(attachments);
    if (self = [super init]) {
        _nodes = [NSMutableArray new];
        for (Attachments *attachment in attachments) {
            A_SNetworkImageNode *node = [[A_SNetworkImageNode alloc] init];
            node.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
            node.cornerRadius = 4.0;
            node.URL = [NSURL URLWithString:attachment.photo.photo604];
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
            [_nodes addObject:node];
        }
    }
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    NSMutableArray *specs = [NSMutableArray new];
    for (A_SDisplayNode *node in _nodes) {
        A_SRatioLayoutSpec *imagePlace =
        [A_SRatioLayoutSpec
         ratioLayoutSpecWithRatio:0.5f
         child:node];
        imagePlace.style.spacingAfter = 3.0;
        imagePlace.style.spacingBefore = 3.0;
        [specs addObject:imagePlace];
    }
    A_SStackLayoutSpec *contentSpec = [A_SStackLayoutSpec
                                      stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                      spacing:8.0
                                      justifyContent:A_SStackLayoutJustifyContentStart
                                      alignItems:A_SStackLayoutAlignItemsStart
                                      children:specs];
    contentSpec.style.flexShrink = 1.0;
    return contentSpec;
}

#pragma mark - A_SNetworkImageNodeDelegate methods.
- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
