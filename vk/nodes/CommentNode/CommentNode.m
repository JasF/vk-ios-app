//
//  CommentNode.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "CommentNode.h"
#import "TextStyles.h"
#import "Comment.h"

static CGFloat const kMargin = 6.f;

@interface CommentNode ()
@property ASTextNode *textNode;
@property ASTextNode *usernameNode;
@property ASTextNode *timeNode;
@property ASNetworkImageNode *avatarNode;
@end

@implementation CommentNode
- (id)initWithComment:(Comment *)comment {
    NSCParameterAssert(comment);
    self = [super init];
    if (self) {
        _comment = comment;
        _usernameNode = [[ASTextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:comment.user.nameString ?: @"" attributes:[TextStyles commentNameStyle]];
        [_usernameNode addTarget:self action:@selector(tappedOnUsername:) forControlEvents:ASControlNodeEventTouchUpInside];
        _usernameNode.maximumNumberOfLines = 1;
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:comment.text ?: @"" attributes:[TextStyles titleStyle]];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        
        
        _timeNode = [[ASTextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:comment.date];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:dateString attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        _avatarNode = [[ASNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = ASDimensionMakeWithPoints(44);
        _avatarNode.style.height = ASDimensionMakeWithPoints(44);
        _avatarNode.cornerRadius = 22.0;
        _avatarNode.URL = [NSURL URLWithString:comment.user.avatarURLString];
        [self addSubnode:_avatarNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    _usernameNode.style.flexShrink = 1.f;
    _usernameNode.style.flexGrow = 1.f;
    _textNode.style.flexShrink = 1.f;
    _textNode.style.flexGrow = 1.f;
    
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kMargin
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_usernameNode, _timeNode]];
    
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:kMargin
     justifyContent:ASStackLayoutJustifyContentSpaceBetween
     alignItems:ASStackLayoutAlignItemsStretch
     children:@[topLineStack, _textNode]];
    nameVerticalStack.style.flexShrink = 1.f;
    nameVerticalStack.style.flexGrow = 1.f;
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kMargin
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_avatarNode, nameVerticalStack]];
    avatarContentSpec.style.flexShrink = 1.f;
    avatarContentSpec.style.flexGrow = 1.f;
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin) child:avatarContentSpec];
    return spec;
}

#pragma mark - Observsers
- (void)tappedOnUsername:(id)sender {
    if ([_delegate respondsToSelector:@selector(commentNode:tappedOnUser:)]) {
        [_delegate commentNode:self tappedOnUser:self.comment.user];
    }
}

@end
