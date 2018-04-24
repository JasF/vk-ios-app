//
//  AudioNode.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextStyles.h"
#import "AudioNode.h"

@interface AudioNode ()
@property ASTextNode *usernameNode;
@property ASTextNode *textNode;
@end

@implementation AudioNode

- (id)initWithAudio:(Audio *)audio {
    if (self = [super init]) {
        _usernameNode = [[ASTextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"Audio: %@", audio.title]
                                                                       attributes:[TextStyles nameStyle]];
        _usernameNode.maximumNumberOfLines = 1;
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _textNode = [[ASTextNode alloc] init];
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:audio.artist attributes:[TextStyles titleStyle]];
        _textNode.maximumNumberOfLines = 1;
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *topLineStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_usernameNode]];
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
     children:@[nameVerticalStack]];
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:avatarContentSpec];
    spec.style.flexShrink = 1.0f;
    return spec;
}

@end
