//
//  DialogNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "DialogNode.h"
#import "Dialog.h"
#import "TextStyles.h"

@interface DialogNode ()
@property ASTextNode *textNode;
@end

@implementation DialogNode

- (instancetype)initWithDialog:(Dialog *)dialog
{
    NSCParameterAssert(dialog);
    self = [super init];
    if (self) {
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:dialog.message.body ?: @"" attributes:[TextStyles nameStyle]];
        _textNode.maximumNumberOfLines = 0;
        [self addSubnode:_textNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_textNode];
}

@end
