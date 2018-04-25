//
//  AnswerNode.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AnswerNode.h"
#import "TextStyles.h"

@interface AnswerNode ()
@property ASTextNode *textNode;
@property ASTextNode *usernameNode;
@property ASTextNode *timeNode;
@property ASNetworkImageNode *avatarNode;
@end

@implementation AnswerNode

- (id)initWithAnswer:(Answer *)answer {
    if (self = [super init]) {
        
        _usernameNode = [[ASTextNode alloc] init];
        //_usernameNode.attributedText = [[NSAttributedString alloc] initWithString:@"TBD" attributes:[TextStyles nameStyle]];
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _textNode = [[ASTextNode alloc] init];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
        
        
        _timeNode = [[ASTextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:answer.date];
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
        [self addSubnode:_avatarNode];
        
        NSString *text = nil;
        if ([answer.type isEqualToString:@"like_post"]) {
            text = L(@"like_post");
        }
        else if ([answer.type isEqualToString:@"like_photo"]) {
            text = L(@"like_photo");
        }
        else if ([answer.type isEqualToString:@"comment_post"]) {
            text = L(@"comment_post");
        }
        else if ([answer.type isEqualToString:@"reply_comment"]) {
            text = L(@"reply_comment");
        }
        else if ([answer.type isEqualToString:@"like_comment"]) {
            text = L(@"like_comment");
        }
        if (text) {
            _textNode.attributedText = [[NSAttributedString alloc] initWithString:text attributes:[TextStyles titleStyle]];
        }
        User *user = answer.users.firstObject;
        NSString *name = user.nameString;
        if (answer.users.count > 1) {
            name = [NSString stringWithFormat:@"%@ + %@", name, @(answer.users.count-1)];
        }
        if (name) {
            _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:name attributes:[TextStyles nameStyle]];
        }
        _avatarNode.URL = [NSURL URLWithString:user.avatarURLString];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_usernameNode, spacer, _timeNode]];
    topLineStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[topLineStack, _textNode]];
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_avatarNode, nameVerticalStack]];
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:avatarContentSpec];
    spec.style.flexShrink = 1.0f;
    return spec;
}

@end
