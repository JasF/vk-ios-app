//
//  UserNode.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "TextStyles.h"
#import "UserNode.h"
#import "User.h"

static CGFloat const kMargin = 6.f;

@interface UserNode ()
@property ASTextNode *usernameNode;
@property ASNetworkImageNode *avatarNode;
@end

@implementation UserNode

- (id)initWithUser:(User *)user {
    if (self = [super init]) {
        _usernameNode = [[ASTextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:user.nameString ?: @"" attributes:[TextStyles titleStyle]];
        _usernameNode.maximumNumberOfLines = 1;
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_usernameNode];
        
        _avatarNode = [[ASNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = ASDimensionMakeWithPoints(44);
        _avatarNode.style.height = ASDimensionMakeWithPoints(44);
        _avatarNode.cornerRadius = 22.0;
        _avatarNode.URL = [NSURL URLWithString:user.avatarURLString];
        [self addSubnode:_avatarNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    _usernameNode.style.flexShrink = 1.f;
    
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:kMargin * 2
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_avatarNode, _usernameNode]];
    
    ASLayoutSpec *spec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(kMargin, kMargin, kMargin, kMargin) child:avatarContentSpec];
    return spec;
}

@end
