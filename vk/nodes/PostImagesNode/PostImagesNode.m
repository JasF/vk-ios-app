//
//  PostImagesNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostImagesNode.h"
#import "Attachments.h"
#import "ASNetworkImageNode.h"
#import "ASDisplayNodeExtras.h"

static CGFloat const kPhotoMargin = 1.f;

@interface PostImagesChildNode : ASNetworkImageNode
@property (nonatomic) Photo *photo;
@end

@implementation PostImagesChildNode
@end

@interface PostImagesNode () <ASNetworkImageNodeDelegate>
@end

@implementation PostImagesNode {
    NSMutableArray *_nodes;
    
}

- (id)initWithAttachments:(NSArray *)attachments {
    NSMutableArray *array = [NSMutableArray new];
    for (Attachments *attachment in attachments) {
        if (attachment.photo) {
            [array addObject:attachment.photo];
        }
    }
    return [self initWithPhotos:array];
}

- (id)initWithPhotos:(NSArray *)photos {
    NSCParameterAssert(photos);
    if (self = [super init]) {
        _nodes = [NSMutableArray new];
        for (Photo *photo in photos) {
            PostImagesChildNode *node = [PostImagesChildNode new];
            node.photo = photo;
            node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
            node.cornerRadius = 4.0;
            node.URL = [NSURL URLWithString:photo.photo_604];
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

NSArray *getPhotoSizes(NSArray *photos) {
    NSMutableArray *result = [NSMutableArray new];
    for (Photo *photo in photos) {
        [result addObject:[NSValue valueWithCGSize:CGSizeMake(photo.width, photo.height)]];
    }
    return result;
}

NSArray *getNormalized(NSArray *sizes) {
    if (!sizes.count) {
        return @[];
    }
    CGSize first = [sizes.firstObject CGSizeValue];
    NSMutableArray *result = [NSMutableArray new];
    for (NSValue *v in sizes) {
        CGSize size = v.CGSizeValue;
        CGFloat f = first.width/size.height;
        [result addObject:[NSValue valueWithCGSize:CGSizeMake(size.width * f, size.height * f)]];
    }
    return result;
}

CGFloat getWsum(NSArray *sizes) {
    CGFloat result = 0.f;
    for (NSValue *v in sizes) {
        CGSize size = v.CGSizeValue;
        result += size.width;
    }
    return result;
}

NSArray *getFactors(NSArray *sizes, CGFloat wsum) {
    NSMutableArray *result = [NSMutableArray new];
    for (NSValue *v in sizes) {
        CGSize size = v.CGSizeValue;
        CGFloat f = size.width/wsum;
        [result addObject:@(f)];
    }
    return result;
}

NSArray *getRects(NSArray *factors, CGFloat csw, CGFloat dh) {
    CGFloat sumX = 0;
    NSMutableArray *result = [NSMutableArray new];
    for (int i=0;i<factors.count;++i) {
        CGFloat f = [factors[i] floatValue];
        CGFloat dw = csw * f;
        [result addObject:[NSValue valueWithCGRect:CGRectMake(sumX, 0, dw, dh)]];
        sumX += dw;
    }
    return result;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    //constrainedSize = ASSizeRangeMake(CGSizeMake(414, CGFLOAT_MAX));
    NSMutableArray *specs = [NSMutableArray new];
    ASRatioLayoutSpec *(^ratioSpecBlock)(PostImagesChildNode *) = ^ASRatioLayoutSpec *(PostImagesChildNode *node) {
        Photo *photo = node.photo;
        CGFloat ratio = photo.height/photo.width;
        if (ratio == 1) {
            ratio = 2;
        }
        ASRatioLayoutSpec *ratioSpec = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:ratio
                                                                             child:node];
        ratioSpec.style.spacingAfter = kPhotoMargin;
        ratioSpec.style.spacingBefore = kPhotoMargin;
        return ratioSpec;
    };
    NSMutableArray *nodes = [_nodes mutableCopy];
    while (nodes.count) {
        PostImagesChildNode *node = nodes.firstObject;
        [nodes removeObjectAtIndex:0];
        if (nodes.count) {
            PostImagesChildNode *second = nodes.firstObject;
            [nodes removeObjectAtIndex:0];
            Photo *p1 = node.photo;
            Photo *p2 = second.photo;
            NSArray *localNodes = @[node, second];
            NSArray *photos = @[p1, p2];
            NSArray *sizes = getPhotoSizes(photos);
            NSArray *normalized = getNormalized(sizes);
            CGFloat wsum = getWsum(normalized);
            NSArray *factors = getFactors(normalized, wsum);
            //CGFloat csw = constrainedSize.max.width;
            //CGFloat photosHeight = p1.height * (csw / wsum);
            //NSArray *rects = getRects(factors, csw, photosHeight);
            for (int i=0; i < localNodes.count; ++i) {
                PostImagesChildNode *node = localNodes[i];
                //CGRect frame = [rects[i] CGRectValue];
                CGFloat factor = [factors[i] floatValue];
                node.style.flexBasis = ASDimensionMake(ASDimensionUnitFraction, factor); // ASRelativeDimensionMakeWithPercent(factor);
                //node.style.layoutPosition = frame.origin;
                //node.style.preferredSize = frame.size;
            }
            //ASAbsoluteLayoutSpec *spec = [ASAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:localNodes];
            
            ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                              stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                              spacing:0
                                              justifyContent:ASStackLayoutJustifyContentStart
                                              alignItems:ASStackLayoutAlignItemsStart
                                              children:localNodes];
            
            ASRatioLayoutSpec *ratio = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:p1.width/wsum
                                                                             child:contentSpec];
            //contentSpec.style.preferredSize = CGSizeMake(constrainedSize.max.width, photosHeight);
            [specs addObject:ratio];
        }
        else {
            ASRatioLayoutSpec *ratioSpec = ratioSpecBlock(node);
            [specs addObject:ratioSpec];
        }
    }
    ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:kPhotoMargin
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStart
                                      children:specs];
    //contentSpec.style.flexShrink = 1.0;
    return contentSpec;
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
