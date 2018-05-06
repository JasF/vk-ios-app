//
//  TextNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextNode.h"
#import "TextStyles.h"

static CGFloat const kPadding = 16.f;

@interface TextNode ()
@property ASTextNode *textNode;
@end

@implementation TextNode
- (id)initWithText:(NSString *)text {
    return [self initWithText:text color:nil];
}

- (id)initWithText:(NSString *)text color:(UIColor *)color {
    if (self = [super init]) {
        _textNode = [[ASTextNode alloc] init];
        NSMutableDictionary *attributes = [[TextStyles textNodeStyle] mutableCopy];
        if (color) {
            attributes[NSForegroundColorAttributeName] = color;
        }
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:text
                                                                   attributes:attributes];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        //_textNode.style.height = ASDimensionMake(kButtonHeight);
        [self addSubnode:_textNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    ASLayoutSpec *leftSpacing = [ASLayoutSpec new];
    ASLayoutSpec *rightSpacing = [ASLayoutSpec new];
    leftSpacing.style.flexGrow = 1;
    rightSpacing.style.flexGrow = 1;
    ASStackLayoutSpec *spec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal spacing:0 justifyContent:ASStackLayoutJustifyContentStart alignItems:ASStackLayoutAlignItemsCenter children:@[leftSpacing, _textNode, rightSpacing]];
    spec.style.alignSelf = ASStackLayoutAlignSelfStretch;
    //spec.style.flexGrow = 1;
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(kPadding, 0, kPadding, 0) child:spec];
}
@end
