//
//  DialogNode.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogNode.h"
#import "Dialog.h"
#import "TextStyles.h"

@interface DialogNode ()
@property A_STextNode *textNode;
@property A_STextNode *usernameNode;
@property A_STextNode *timeNode;
@property A_SNetworkImageNode *avatarNode;
@end

@implementation DialogNode

- (instancetype)initWithDialog:(Dialog *)dialog
{
    NSCParameterAssert(dialog);
    self = [super init];
    if (self) {
        _usernameNode = [[A_STextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:dialog.username ?: @"" attributes:[TextStyles nameStyle]];
        _usernameNode.maximumNumberOfLines = 1;
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _textNode = [[A_STextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:dialog.message.body ?: @"" attributes:[TextStyles titleStyle]];
        _textNode.maximumNumberOfLines = 1;
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        
        
        _timeNode = [[A_STextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:dialog.message.date];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:dateString attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        _avatarNode = [[A_SNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = A_SDimensionMakeWithPoints(44);
        _avatarNode.style.height = A_SDimensionMakeWithPoints(44);
        _avatarNode.cornerRadius = 22.0;
        _avatarNode.URL = [NSURL URLWithString:dialog.avatarURLString];
        [self addSubnode:_avatarNode];
    }
    return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    A_SStackLayoutSpec *topLineStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsCenter
     children:@[_usernameNode, spacer, _timeNode]];
    topLineStack.style.alignSelf = A_SStackLayoutAlignSelfStretch;
    
    A_SStackLayoutSpec *nameVerticalStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:5.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[topLineStack, _textNode]];
    
    A_SStackLayoutSpec *avatarContentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[_avatarNode, nameVerticalStack]];
    
    A_SLayoutSpec *spec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:avatarContentSpec];
    spec.style.flexShrink = 1.0f;
    return spec;
}

@end
