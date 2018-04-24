//
//  FriendsNode.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "FriendsNode.h"
#import "TextStyles.h"
#import "User.h"

@interface FriendsNode ()
@property ASTextNode *textNode;
@end

@implementation FriendsNode

- (id)initWithFriends:(NSArray *)friends {
    if (self = [super init]) {
        _textNode = [[ASTextNode alloc] init];
        NSMutableString *string = [@"Friends: " mutableCopy];
        for(User *user in friends) {
            [string appendFormat:@"%@\n", user.nameString];
        }
        _textNode.attributedText = [[NSAttributedString alloc] initWithString:string
                                                                   attributes:[TextStyles titleStyle]];
        _textNode.truncationMode = NSLineBreakByTruncatingTail;
        [self addSubnode:_textNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_textNode];
}

@end
