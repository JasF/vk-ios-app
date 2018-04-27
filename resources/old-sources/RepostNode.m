//
//  RepostNode.m
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "RepostNode.h"
#import "TextStyles.h"

@interface RepostNode ()
@property (nonatomic, strong) ASImageNode *iconNode;
@property (nonatomic, strong) ASTextNode *countNode;
@property (nonatomic, assign) NSInteger repostsCount;
@property (nonatomic, assign) BOOL reposted;
@end

@implementation RepostNode

- (instancetype)initWithRepostsCount:(NSInteger)repostsCount
                            reposted:(BOOL)reposted;
{
    self = [super init];
    if (self) {
        _repostsCount = repostsCount;
        _reposted = (_repostsCount > 0) ? reposted : NO;
        _iconNode = [[ASImageNode alloc] init];
        _iconNode.image = (_reposted) ? [UIImage imageNamed:@"reposted.png"] : [UIImage imageNamed:@"repost.png"];
        [self addSubnode:_iconNode];
        _countNode = [[ASTextNode alloc] init];
        if (_repostsCount > 0) {
            NSDictionary *attributes = _reposted ? [TextStyles cellControlColoredStyle] : [TextStyles cellControlStyle];
            _countNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", @(repostsCount)] attributes:attributes];
            
        }
        [self addSubnode:_countNode];
    }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *mainStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:6.0
     justifyContent:ASStackLayoutJustifyContentCenter
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_iconNode, _countNode]];
    return mainStack;
}

@end
