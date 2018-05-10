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
#import "vk-Swift.h"

static CGFloat const kMargin = 6.f;
static CGFloat const kTextCornerRadius = 3.f;

@interface DialogNode ()
@property ASTextNode *textNode;
@property ASTextNode *usernameNode;
@property ASTextNode *timeNode;
@property ASNetworkImageNode *avatarNode;
@property User *user;
@end

@implementation DialogNode

- (instancetype)initWithDialog:(Dialog *)dialog
{   
    NSCParameterAssert(dialog);
    self = [super init];
    if (self) {
        _user = dialog.user;
        _usernameNode = [[ASTextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:dialog.username ?: @"" attributes:[TextStyles nameStyle]];
        _usernameNode.maximumNumberOfLines = 1;
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _textNode = [[ASTextNode alloc] init];
        NSString *body = dialog.message.body ?: @"";
        if (!body.length) {
            if (dialog.message.attachments.count || dialog.message.photoAttachments.count) {
                body = L(@"dialog_attachments");
            }
        }
        if (dialog.message.isTyping) {
            body = [NSString stringWithFormat:@"%@: %@", L(@"typing"), body];
        }
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:body attributes:[TextStyles titleStyle]];
        _textNode.maximumNumberOfLines = 2;
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        _textNode.cornerRadius = kTextCornerRadius;
        _textNode.backgroundColor = (dialog.message.read_state == 0) ? RGB(240, 242, 245) : [UIColor clearColor];
        [self addSubnode:_textNode];
        
        
        _timeNode = [[ASTextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:dialog.message.date];
        
        NSString *dateString = [date utils_dayDifferenceFromNow];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:dateString attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        _avatarNode = [[ASNetworkImageNode alloc] init];
        [_avatarNode addTarget:self action:@selector(didTappedOnAvatar:) forControlEvents:ASControlNodeEventTouchUpInside];
        _avatarNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = ASDimensionMakeWithPoints(60);
        _avatarNode.style.height = ASDimensionMakeWithPoints(60);
        _avatarNode.cornerRadius = _avatarNode.style.height.value/2;
        _avatarNode.URL = [NSURL URLWithString:dialog.avatarURLString];
        [self addSubnode:_avatarNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    _usernameNode.style.flexShrink = 1.f;
    _usernameNode.style.flexGrow = 1.f;
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_usernameNode, _timeNode]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    ASLayoutSpec *prespacer = [ASLayoutSpec new];
    prespacer.style.flexGrow = 1.f;
    ASLayoutSpec *spacer = [ASLayoutSpec new];
    spacer.style.flexGrow = 1.f;
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:0.0
     justifyContent:ASStackLayoutJustifyContentSpaceBetween
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[topLineStack, prespacer, _textNode, spacer]];
    nameVerticalStack.style.flexShrink = 1.f;
    nameVerticalStack.style.flexGrow = 1.f;
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kMargin
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[_avatarNode, nameVerticalStack]];
    avatarContentSpec.style.flexShrink = 1.f;
    avatarContentSpec.style.flexGrow = 1.f;
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin) child:avatarContentSpec];
    return spec;
}

- (void)didTappedOnAvatar:(id)sender {
    if (!_user) {
        return;
    }
    if ([_delegate respondsToSelector:@selector(dialogNode:tappedWithUser:)]) {
        [_delegate dialogNode:self tappedWithUser:self.user];
    }
}
@end
