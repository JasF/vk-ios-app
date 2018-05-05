//
//  WallPostNode.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostNode.h"
#import "WallPost.h"
#import "TextStyles.h"
#import "LikesNode.h"
#import "CommentsNode.h"
#import "AvatarNode.h"
#import "RepostNode.h"
#import "vk-Swift.h"
#import "PostImagesNode.h"
#import "PostVideoNode.h"
#import "PostTextNode.h"

extern CGFloat const kMargin;
extern CGFloat const kNameNodeMargin;
extern CGFloat const kBottomSeparatorHeight;
extern CGFloat const kControlsSize;

@interface WallPostNode() <ASNetworkImageNodeDelegate, WallPostNodeDelegate>

@property (strong, nonatomic) ASTextNode *nameNode;
@property (strong, nonatomic) ASTextNode *usernameNode;
@property (strong, nonatomic) ASTextNode *timeNode;
@property (strong, nonatomic) PostTextNode *postNode;
@property (strong, nonatomic) ASImageNode *viaNode;
@property (strong, nonatomic) AvatarNode *avatarNode;
@property (strong, nonatomic) ASImageNode *optionsNode;
@property (strong, nonatomic) NameTimeNode *titleNode;
@property ASDisplayNode *bottomSeparator;

@property (strong, nonatomic) ASDisplayNode *verticalLineNode;
@property (strong, nonatomic) ASDisplayNode *historyNode;
@property (assign, nonatomic) BOOL embedded;
@property (strong, nonatomic) id<NodeFactory> nodeFactory;
@property (strong, nonatomic) NSMutableArray *mediaNodes;

@end


@implementation WallPostNode {
    NSIndexPath *_indexPath;
}

#pragma mark - Lifecycle

- (instancetype)initWithPost:(WallPost *)post
                 nodeFactory:(id<NodeFactory>)nodeFactory
                    embedded:(NSNumber *)embedded
{
    NSCParameterAssert(post);
    NSCParameterAssert(nodeFactory);
    
    self = [super initWithEmbedded:embedded.boolValue likesCount:post.likes.count liked:post.likes.user_likes repostsCount:post.reposts.count reposted:post.reposts.user_reposted commentsCount:post.comments.count];
    if (self) {
        self.item = post;
        _mediaNodes = [NSMutableArray new];
        _nodeFactory = nodeFactory;
        _embedded = embedded.boolValue;
        _post = post;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:_post.date];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        _titleNode = [[NameTimeNode alloc] init:[_post.user nameString] ?: @"" time:dateString];
        [_titleNode addTarget:self action:@selector(titleNodeClicked:) forControlEvents:ASControlNodeEventTouchUpInside];
        [self addSubnode:_titleNode];
        
        // Post node
        // Processing URLs in post
        
        NSString *text = _post.text;
        if (text.length) {
            _postNode = [PostTextNode new];
            [self addSubnode:_postNode];
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text attributes:[TextStyles postStyle]];
            
            // Configure node to support tappable links
            _postNode.attributedText = attrString;
        }
        
        WallPost *history = _post.history.firstObject;
        if (history) {
            _historyNode = [_nodeFactory nodeForItem:history embedded:YES];
            if ([_historyNode isKindOfClass:[WallPostNode class]]) {
                WallPostNode *postNode = (WallPostNode *)_historyNode;
                postNode.delegate = self;
            }
            [self addSubnode:_historyNode];
            _verticalLineNode = [ASDisplayNode new];
            _verticalLineNode.style.preferredSize = CGSizeMake(2, 50);
            _verticalLineNode.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25f];
            [self addSubnode:_verticalLineNode];
        }
        
        // Media
        if (_post.photos) {
            id node = [_nodeFactory nodeForItem:_post.photos];
            [self addSubnode:node];
            [_mediaNodes addObject:node];
        }
        if (_post.photoAttachments.count) {
            PostImagesNode *node =(PostImagesNode *)[_nodeFactory nodeForItem:_post.photoAttachments];
            NSCParameterAssert([node isKindOfClass:[PostImagesNode class]]);
            if ([node isKindOfClass:[PostImagesNode class]]) {
                @weakify(self);
                node.tappedOnPhotoHandler = ^(NSInteger index) {
                    @strongify(self);
                    if ([self.delegate respondsToSelector:@selector(postNode:tappedOnPhotoWithIndex:withPost:)]) {
                        [self.delegate postNode:self tappedOnPhotoWithIndex:index withPost:_post];
                    }
                };
            }
            [self addSubnode:node];
            [_mediaNodes addObject:node];
        }
        for (Attachments *attachment in _post.attachments) {
            id node = [_nodeFactory nodeForItem:attachment];
            if ([node isKindOfClass:[PostVideoNode class]]) {
                PostVideoNode *videoNode = (PostVideoNode *)node;
                @weakify(self);
                videoNode.tappedOnVideoHandler = ^(Video *video) {
                    @strongify(self)
                    if ([self.delegate respondsToSelector:@selector(postNode:tappedOnVideo:)]) {
                        [self.delegate postNode:self tappedOnVideo:video];
                    }
                };
            }
            if (node) {
                [self addSubnode:node];
                [_mediaNodes addObject:node];
            }
        }
        for (Audio *audio in _post.audio) {
            id node = [_nodeFactory nodeForItem:audio];
            if (node) {
                [self addSubnode:node];
                [_mediaNodes addObject:node];
            }
        }
        if (_post.friends.count) {
            id node = [_nodeFactory friendsNodeWithArray:_post.friends];
            if (node) {
                [self addSubnode:node];
                [_mediaNodes addObject:node];
            }
        }
        
        // User pic
        _avatarNode = [[AvatarNode alloc] initWithUser:_post.user];
        [self addSubnode:_avatarNode];
        
        // Bottom controls
        if (!_embedded) {
            
            /*
            _optionsNode = [[ASImageNode alloc] init];
            _optionsNode.image = [UIImage imageNamed:@"icon_more"];
            _optionsNode.contentMode = UIViewContentModeCenter;
            [_optionsNode addTarget:self action:@selector(optionsTapped:) forControlEvents:ASControlNodeEventTouchUpInside];
            [self addSubnode:_optionsNode];
            */
            
            _bottomSeparator = [ASDisplayNode new];
            _bottomSeparator.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
            [self addSubnode:_bottomSeparator];
        }
        
        for (ASDisplayNode *node in self.subnodes) {
            // ASTextNode with embedded links doesn't support layer backing
            if (node.supportsLayerBacking) {
                //node.layerBacked = YES;
            }
        }
    }
    return self;
}

#pragma mark - ASDisplayNode

- (void)didLoad
{
    // enable highlighting now that self.layer has loaded -- see ASHighlightOverlayLayer.h
    self.layer.as_allowsHighlightDrawing = YES;
    
    [super didLoad];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    _titleNode.style.flexShrink = 1.f;
    _titleNode.style.flexGrow = 1.f;
    
    ASLayoutSpec *controlsStack = nil;
    if (!_embedded) {
        controlsStack = [self controlsStack];
        _optionsNode.style.width = ASDimensionMake(kControlsSize);
        _optionsNode.style.height = ASDimensionMake(kControlsSize);
    }
    
    NSMutableArray *mainStackContent = [[NSMutableArray alloc] init];
    if (_mediaNodes.count == 1) {
        [mainStackContent addObject:_mediaNodes.firstObject];
    }
    else if (_mediaNodes.count > 1) {
        ASStackLayoutSpec *mediaSpec = [ASStackLayoutSpec
                                          stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                          spacing:kMargin
                                          justifyContent:ASStackLayoutJustifyContentStart
                                          alignItems:ASStackLayoutAlignItemsStart
                                          children:_mediaNodes];
        [mainStackContent addObject:mediaSpec];
    }
    
    if (_verticalLineNode && _historyNode) {
        NSArray *childs = @[[ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero
                                                                   child:_verticalLineNode], _historyNode];
        ASStackLayoutSpec *historyHorizontalSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                                           spacing:kMargin
                                                                                    justifyContent:ASStackLayoutJustifyContentStart
                                                                                        alignItems:ASStackLayoutAlignItemsStretch
                                                                                          children:childs];
        _historyNode.style.flexShrink = 1.f;
        _historyNode.style.flexGrow = 1.f;
        [mainStackContent addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:_embedded ? UIEdgeInsetsZero : UIEdgeInsetsMake(0, kMargin, 0, kMargin)
                                                                           child:historyHorizontalSpec]];
    }
    
    
    ASStackLayoutSpec *contentSpec = nil;
    if (mainStackContent.count) {
        contentSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                              spacing:kMargin
                                                       justifyContent:ASStackLayoutJustifyContentStart
                                                           alignItems:ASStackLayoutAlignItemsStretch
                                                             children:mainStackContent];
        contentSpec.style.flexShrink = 1.0;
    }
    
    if (!_embedded) {
        _avatarNode.style.spacingBefore = kMargin;
    }
    NSMutableArray *avatarSpecChilds = [@[_avatarNode, _titleNode] mutableCopy];
    if (_optionsNode) {
        [avatarSpecChilds addObject:_optionsNode];
    }
    ASStackLayoutSpec *avatarContentSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                                   spacing:kMargin
                                                                            justifyContent:ASStackLayoutJustifyContentStart
                                                                                alignItems:ASStackLayoutAlignItemsCenter
                                                                                  children:avatarSpecChilds];
    avatarContentSpec.style.spacingBefore = kMargin;
    
    NSMutableArray *verticalContentSpecArray = [@[avatarContentSpec] mutableCopy];
    if (_postNode) {
        [verticalContentSpecArray addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:_embedded ? UIEdgeInsetsZero : UIEdgeInsetsMake(0, kMargin, 0, kMargin)
                                                                                   child:_postNode]];
    }
    if (contentSpec) {
        [verticalContentSpecArray addObject:contentSpec];
    }
    if (controlsStack) {
        [verticalContentSpecArray addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:_embedded ? UIEdgeInsetsZero : UIEdgeInsetsMake(0, kMargin, 0, kMargin)
                                                                                   child:controlsStack]];
    }
    if (_bottomSeparator) {
        [verticalContentSpecArray addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_bottomSeparator]];
        _bottomSeparator.style.height = ASDimensionMakeWithPoints(kBottomSeparatorHeight);
    }
    ASStackLayoutSpec *verticalContentSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                                                     spacing:kMargin
                                                                              justifyContent:ASStackLayoutJustifyContentStart
                                                                                  alignItems:ASStackLayoutAlignItemsStretch
                                                                                    children:verticalContentSpecArray];
    verticalContentSpec.style.flexShrink = 1.0;
    return verticalContentSpec;
}

- (void)layout
{
    [super layout];
}

#pragma mark - ASCellNode

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

- (void)optionsTapped:(id)sender {
    
}

- (void)titleNodeClicked:(id)sender {
    [self.delegate titleNodeTapped:self.post];
}

#pragma mark - WallPostNodeDelegate
- (void)titleNodeTapped:(WallPost *)post {
    [self.delegate titleNodeTapped:post];
}

- (void)postNode:(WallPostNode *)node tappedOnPhotoWithIndex:(NSInteger)index withPost:(WallPost *)post {
    [self.delegate postNode:node tappedOnPhotoWithIndex:index withPost:post];
}

- (void)postNode:(WallPostNode *)node tappedOnVideo:(Video *)video {
    [self.delegate postNode:node tappedOnVideo:video];
}

@end
