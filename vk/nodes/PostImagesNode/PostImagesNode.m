//
//  PostImagesNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "PostImagesNode.h"
#import "Attachments.h"
#import "ASNetworkImageNode.h"
#import "ASDisplayNodeExtras.h"

@interface PostImagesNode () <ASNetworkImageNodeDelegate>
@end

@implementation PostImagesNode {
    NSMutableArray *_nodes;
    
}

- (id)initWithAttachments:(NSArray *)attachments {
    NSCParameterAssert(attachments);
    if (self = [super init]) {
        _nodes = [NSMutableArray new];
        for (Attachments *attachment in attachments) {
            ASNetworkImageNode *node = [[ASNetworkImageNode alloc] init];
            node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
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

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    NSMutableArray *specs = [NSMutableArray new];
    for (ASDisplayNode *node in _nodes) {
        ASRatioLayoutSpec *imagePlace =
        [ASRatioLayoutSpec
         ratioLayoutSpecWithRatio:0.5f
         child:node];
        imagePlace.style.spacingAfter = 3.0;
        imagePlace.style.spacingBefore = 3.0;
        [specs addObject:imagePlace];
    }
    ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:8.0
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStart
                                      children:specs];
    contentSpec.style.flexShrink = 1.0;
    
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:contentSpec];
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
