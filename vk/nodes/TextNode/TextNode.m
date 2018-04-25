//
//  TextNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextNode.h"
#import "TextStyles.h"

@interface TextNode ()
@property ASTextNode *textNode;
@end

@implementation TextNode
- (id)initWithText:(NSString *)text {
    if (self = [super init]) {
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:text attributes:[TextStyles nameStyle]];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_textNode];
}
@end
