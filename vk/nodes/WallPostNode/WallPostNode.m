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

static CGFloat const kMargin = 12.f;
static CGFloat const kNameNodeMargin = 5.f;
static CGFloat const kBottomSeparatorHeight = 4.f;

@interface WallPostNode() <ASNetworkImageNodeDelegate, ASTextNodeDelegate>

@property (strong, nonatomic) WallPost *post;
@property (strong, nonatomic) ASTextNode *nameNode;
@property (strong, nonatomic) ASTextNode *usernameNode;
@property (strong, nonatomic) ASTextNode *timeNode;
@property (strong, nonatomic) ASTextNode *postNode;
@property (strong, nonatomic) ASImageNode *viaNode;
@property (strong, nonatomic) AvatarNode *avatarNode;
@property (strong, nonatomic) LikesNode *likesNode;
@property (strong, nonatomic) CommentsNode *commentsNode;
@property (strong, nonatomic) ASImageNode *optionsNode;
@property ASDisplayNode *bottomSeparator;

@property (strong, nonatomic) ASDisplayNode *verticalLineNode;
@property (strong, nonatomic) ASDisplayNode *verticalRightNode;
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
    self = [super init];
    if (self) {
        _mediaNodes = [NSMutableArray new];
        _nodeFactory = nodeFactory;
        _embedded = embedded.boolValue;
        _post = post;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Name node
        _nameNode = [[ASTextNode alloc] init];
        _nameNode.attributedText = [[NSAttributedString alloc] initWithString:[_post.user nameString] ?: @"" attributes:[TextStyles nameStyle]];
        _nameNode.maximumNumberOfLines = 0;
        [self addSubnode:_nameNode];
        
        // Time node
        _timeNode = [[ASTextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:_post.date];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:dateString attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        // Post node
        _postNode = [[ASTextNode alloc] init];
        _postNode.maximumNumberOfLines = 12;
        _postNode.truncationMode = NSLineBreakByTruncatingTail;
        _postNode.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"\n"];
        _postNode.additionalTruncationMessage = [[NSAttributedString alloc] initWithString:L(@"show_fully")
                                                                                attributes:[TextStyles truncationStyle]];
        // Processing URLs in post
        NSString *kLinkAttributeName = @"TextLinkAttributeName";
        
        NSString *text = _post.text;
        if (text.length) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:text attributes:[TextStyles postStyle]];
            NSDataDetector *urlDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
            [urlDetector enumerateMatchesInString:attrString.string options:kNilOptions range:NSMakeRange(0, attrString.string.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
                if (result.resultType == NSTextCheckingTypeLink) {
                    NSMutableDictionary *linkAttributes = [[NSMutableDictionary alloc] initWithDictionary:[TextStyles postLinkStyle]];
                    linkAttributes[kLinkAttributeName] = [NSURL URLWithString:result.URL.absoluteString];
                    [attrString addAttributes:linkAttributes range:result.range];
                }
                
            }];
            // Configure node to support tappable links
            _postNode.delegate = self;
            _postNode.userInteractionEnabled = YES;
            _postNode.linkAttributeNames = @[ kLinkAttributeName ];
            _postNode.attributedText = attrString;
            _postNode.passthroughNonlinkTouches = YES;   // passes touches through when they aren't on a link
            
        }
        [self addSubnode:_postNode];
        
        WallPost *history = _post.history.firstObject;
        if (history) {
            _historyNode = [_nodeFactory nodeForItem:history embedded:YES];
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
            id node = [_nodeFactory nodeForItem:_post.photoAttachments];
            [self addSubnode:node];
            [_mediaNodes addObject:node];
        }
        for (Attachments *attachment in _post.attachments) {
            id node = [_nodeFactory nodeForItem:attachment];
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
            _likesNode = [[LikesNode alloc] initWithLikesCount:_post.likes.count];
            [self addSubnode:_likesNode];
            
            _commentsNode = [[CommentsNode alloc] initWithCommentsCount:_post.comments.count];
            [self addSubnode:_commentsNode];
            
            _optionsNode = [[ASImageNode alloc] init];
            _optionsNode.image = [UIImage imageNamed:@"icon_more"];
            [self addSubnode:_optionsNode];
            
            _bottomSeparator = [ASDisplayNode new];
            _bottomSeparator.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
            NSArray *colors = @[[UIColor greenColor], [UIColor redColor], [UIColor brownColor], [UIColor cyanColor]];
            self.backgroundColor = [colors[arc4random()%3] colorWithAlphaComponent:0.1];
            [self addSubnode:_bottomSeparator];
        }
        
        for (ASDisplayNode *node in self.subnodes) {
            // ASTextNode with embedded links doesn't support layer backing
            if (node.supportsLayerBacking) {
                node.layerBacked = YES;
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
    ASStackLayoutSpec *nameVerticalStack =
    [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                            spacing:kNameNodeMargin
                                     justifyContent:ASStackLayoutJustifyContentStart
                                         alignItems:ASStackLayoutAlignItemsStart
                                           children:@[_nameNode, _timeNode]];
    nameVerticalStack.style.flexShrink = 1.f;
    nameVerticalStack.style.flexGrow = 1.f;
    
    ASStackLayoutSpec *controlsStack = nil;
    if (!_embedded) {
        controlsStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                spacing:0
                                                         justifyContent:ASStackLayoutJustifyContentStart
                                                             alignItems:ASStackLayoutAlignItemsCenter
                                                               children:@[_likesNode, _commentsNode, _optionsNode]];
        _likesNode.backgroundColor = [UIColor redColor];
        _commentsNode.backgroundColor = [UIColor greenColor];
        _optionsNode.backgroundColor = [UIColor blueColor];
        _postNode.backgroundColor = [UIColor orangeColor];
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
        ASInsetLayoutSpec *verticalLineSpec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_verticalLineNode];
        ASStackLayoutSpec *historyHorizontalSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                                           spacing:kMargin
                                                                                    justifyContent:ASStackLayoutJustifyContentStart
                                                                                        alignItems:ASStackLayoutAlignItemsStretch
                                                                                          children:@[verticalLineSpec, _historyNode]];
        _historyNode.style.flexShrink = 1.f;
        _historyNode.style.flexGrow = 1.f;
        [mainStackContent addObject:historyHorizontalSpec];
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
    
    _avatarNode.style.spacingBefore = kMargin;
    ASStackLayoutSpec *avatarContentSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                                   spacing:kMargin
                                                                            justifyContent:ASStackLayoutJustifyContentStart
                                                                                alignItems:ASStackLayoutAlignItemsCenter
                                                                                  children:@[_avatarNode, nameVerticalStack]];
    avatarContentSpec.style.spacingBefore = kMargin;
    
    NSMutableArray *verticalContentSpecArray = [@[avatarContentSpec,
                                                  [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, kMargin, 0, kMargin)
                                                                                         child:_postNode]] mutableCopy];
    if (contentSpec) {
        [verticalContentSpecArray addObject:contentSpec];
    }
    if (controlsStack) {
        [verticalContentSpecArray addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, kMargin, 0, kMargin)
                                                                                   child:controlsStack]];
    }
    if (_bottomSeparator) {
        [verticalContentSpecArray addObject:[ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_bottomSeparator]];
        _bottomSeparator.style.height = ASDimensionMakeWithPoints(kBottomSeparatorHeight);
        _bottomSeparator.style.width = ASDimensionMakeWithPoints(40);
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

#pragma mark - <ASTextNodeDelegate>

- (BOOL)textNode:(ASTextNode *)richTextNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
    // Opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
    return YES;
}

- (void)textNode:(ASTextNode *)richTextNode tappedLinkAttribute:(NSString *)attribute value:(NSURL *)URL atPoint:(CGPoint)point textRange:(NSRange)textRange
{
    // The node tapped a link, open it
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)textNodeTappedTruncationToken:(ASTextNode *)textNode {
    _postNode.maximumNumberOfLines = 0.f;
    [self setNeedsLayout];
}

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}


@end
