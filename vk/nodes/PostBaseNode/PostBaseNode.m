//
//  PostBaseNode.m
//  vk
//
//  Created by Jasf on 28.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostBaseNode.h"

#import "WallPostNode.h"
#import "WallPost.h"
#import "TextStyles.h"
#import "LikesNode.h"
#import "CommentsNode.h"
#import "AvatarNode.h"
#import "RepostNode.h"

static CGFloat const kMargin = 12.f;
static CGFloat const kNameNodeMargin = 5.f;
static CGFloat const kBottomSeparatorHeight = 8.f;
static CGFloat const kControlsSize = 40.f;

@interface PostBaseNode ()
@property BOOL embedded;
@end

@implementation PostBaseNode

- (id)initWithEmbedded:(BOOL)embedded likesCount:(NSInteger)likesCount liked:(BOOL)liked repostsCount:(NSInteger)repostsCount reposted:(BOOL)reposted commentsCount:(NSInteger)commentsCount {
    if (self = [super init]) {
        _embedded = embedded;
        
        // Bottom controls
        if (!_embedded) {
            
            
            _likesNode = [[LikesNode alloc] initWithLikesCount:likesCount liked:liked];
            [_likesNode addTarget:self action:@selector(likesTapped:) forControlEvents:ASControlNodeEventTouchUpInside];
            [self addSubnode:_likesNode];
            
            _commentsNode = [[CommentsNode alloc] initWithCommentsCount:commentsCount];
            [self addSubnode:_commentsNode];
            
            _repostNode = [[RepostNode alloc] initWithRepostsCount:repostsCount reposted:reposted];
            [_repostNode addTarget:self action:@selector(repostTapped:) forControlEvents:ASControlNodeEventTouchUpInside];
            [self addSubnode:_repostNode];
        }
    }
    return self;
}

- (void)likesTapped:(id)sender {
    
}
- (void)repostTapped:(id)sender {
    
}
- (ASLayoutSpec *)controlsStack {
    
    if (!_embedded) {
        NSArray *array = @[_likesNode,
                           _commentsNode,
                           _repostNode];
        for (id<ASLayoutElement> el in array) {
            el.style.flexGrow = 1.f;
            el.style.height = ASDimensionMake(kControlsSize);
        }
        
        ASStackLayoutSpec *controlsStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                spacing:0
                                                         justifyContent:ASStackLayoutJustifyContentStart
                                                             alignItems:ASStackLayoutAlignItemsCenter
                                                               children:array];
        controlsStack = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(-kMargin, 0, -kMargin, 0)
                                                               child:controlsStack];
        /*
         _likesNode.backgroundColor = [UIColor redColor];
         _commentsNode.backgroundColor = [UIColor greenColor];
         _optionsNode.backgroundColor = [UIColor blueColor];
         _postNode.backgroundColor = [UIColor orangeColor];
         
         NSArray *colors = @[[UIColor greenColor], [UIColor redColor], [UIColor brownColor], [UIColor cyanColor], [UIColor yellowColor], [UIColor orangeColor]];
         self.backgroundColor = [colors[arc4random()%6] colorWithAlphaComponent:0.1];
         */
        return controlsStack;
    }
    return [ASInsetLayoutSpec utils_with:self];
}
@end

