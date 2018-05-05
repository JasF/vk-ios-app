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

static CGFloat const kPhotoMargin = 2.f;
static CGFloat const kNodesMargin = 2.f;

@interface PostImagesChildNode : ASNetworkImageNode
@property (nonatomic) Photo *photo;
@end

@implementation PostImagesChildNode
@end

@interface PostImagesNode () <ASNetworkImageNodeDelegate>
@property (nonatomic) NSArray *photos;
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
        _photos = photos;
        _nodes = [NSMutableArray new];
        for (Photo *photo in photos) {
            PostImagesChildNode *node = [PostImagesChildNode new];
            [node addTarget:self action:@selector(didTapOnPhoto:) forControlEvents:ASControlNodeEventTouchUpInside];
            node.photo = photo;
            node.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
            node.URL = [NSURL URLWithString:photo.photo_604];
            node.delegate = self;
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

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    NSMutableArray *specs = [NSMutableArray new];
    ASRatioLayoutSpec *(^ratioSpecBlock)(PostImagesChildNode *) = ^ASRatioLayoutSpec *(PostImagesChildNode *node) {
        Photo *photo = node.photo;
        ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                          stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                          spacing:kPhotoMargin
                                          justifyContent:ASStackLayoutJustifyContentStart
                                          alignItems:ASStackLayoutAlignItemsStart
                                          children:@[node]];
        node.style.flexBasis = ASDimensionMake(ASDimensionUnitFraction, 1);
        node.style.flexShrink = 1;
        ASRatioLayoutSpec *ratio = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:photo.height/photo.width
                                                                         child:contentSpec];
        return ratio;
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
            for (int i=0; i < localNodes.count; ++i) {
                PostImagesChildNode *node = localNodes[i];
                CGFloat factor = [factors[i] floatValue];
                node.style.flexBasis = ASDimensionMake(ASDimensionUnitFraction, factor);
                node.style.flexShrink = 1;
            }
            ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                              stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                              spacing:kPhotoMargin
                                              justifyContent:ASStackLayoutJustifyContentStart
                                              alignItems:ASStackLayoutAlignItemsStart
                                              children:localNodes];
            ASRatioLayoutSpec *ratio = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:p1.width/wsum
                                                                             child:contentSpec];
            [specs addObject:ratio];
        }
        else {
            ASRatioLayoutSpec *ratioSpec = ratioSpecBlock(node);
            [specs addObject:ratioSpec];
        }
    }
    ASStackLayoutSpec *contentSpec = [ASStackLayoutSpec
                                      stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                      spacing:kNodesMargin
                                      justifyContent:ASStackLayoutJustifyContentStart
                                      alignItems:ASStackLayoutAlignItemsStart
                                      children:specs];
    return contentSpec;
}

#pragma mark - ASNetworkImageNodeDelegate methods.
- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

#pragma mark - Observers
- (void)didTapOnPhoto:(PostImagesChildNode *)node {
    NSInteger index = [_photos indexOfObject:node.photo];
    if (index == NSNotFound) {
        NSCAssert(false, @"something went wrong");
        return;
    }
    if (_tappedOnPhotoHandler) {
        _tappedOnPhotoHandler(index);
    }
}
@end
