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

#define PostNodeDividerColor [UIColor lightGrayColor]

@interface WallPostNode() <A_SNetworkImageNodeDelegate, A_STextNodeDelegate>

@property (strong, nonatomic) WallPost *post;
@property (strong, nonatomic) A_SDisplayNode *divider;
@property (strong, nonatomic) A_STextNode *nameNode;
@property (strong, nonatomic) A_STextNode *usernameNode;
@property (strong, nonatomic) A_STextNode *timeNode;
@property (strong, nonatomic) A_STextNode *postNode;
@property (strong, nonatomic) A_SImageNode *viaNode;
@property (strong, nonatomic) A_SNetworkImageNode *avatarNode;
@property (strong, nonatomic) LikesNode *likesNode;
@property (strong, nonatomic) CommentsNode *commentsNode;
@property (strong, nonatomic) A_SImageNode *optionsNode;

@property (strong, nonatomic) A_SDisplayNode *verticalLineNode;
@property (strong, nonatomic) A_SDisplayNode *verticalRightNode;
@property (strong, nonatomic) A_SDisplayNode *historyNode;
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
        _nameNode = [[A_STextNode alloc] init];
        _nameNode.attributedText = [[NSAttributedString alloc] initWithString:_post.firstName ?: @"" attributes:[TextStyles nameStyle]];
        _nameNode.maximumNumberOfLines = 0;
        [self addSubnode:_nameNode];
        
        // Time node
        _timeNode = [[A_STextNode alloc] init];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:_post.date];
        NSString *dateString = [NSDateFormatter localizedStringFromDate:date
                                                              dateStyle:NSDateFormatterShortStyle
                                                              timeStyle:NSDateFormatterShortStyle];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:dateString attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        // Post node
        _postNode = [[A_STextNode alloc] init];
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
        
        _verticalRightNode = [A_SDisplayNode new];
        _verticalRightNode.style.preferredSize = CGSizeMake(2, 50);
        _verticalRightNode.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25f];
        [self addSubnode:_verticalRightNode];
        
        WallPost *history = _post.history.firstObject;
        if (history) {
            _historyNode = [_nodeFactory nodeForItem:history embedded:YES];
            [self addSubnode:_historyNode];
            
            _verticalLineNode = [A_SDisplayNode new];
            _verticalLineNode.style.preferredSize = CGSizeMake(2, 50);
            _verticalLineNode.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25f];
            [self addSubnode:_verticalLineNode];
            
            
        }
        
        // Media
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
        
        // User pic
        _avatarNode = [[A_SNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = A_SDimensionMakeWithPoints(44);
        _avatarNode.style.height = A_SDimensionMakeWithPoints(44);
        _avatarNode.cornerRadius = 22.0;
        _avatarNode.URL = [NSURL URLWithString:_post.avatarURLString];
        _avatarNode.imageModificationBlock = ^UIImage *(UIImage *image) {
            
            UIImage *modifiedImage;
            CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
            
            UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
            
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:44.0] addClip];
            [image drawInRect:rect];
            modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            return modifiedImage;
            
        };
        [self addSubnode:_avatarNode];
        
        // Hairline cell separator
        /*
        _divider = [[A_SDisplayNode alloc] init];
        [self updateDividerColor];
        [self addSubnode:_divider];
        */
        /*
        // Via
        if (_post.via != 0) {
            _viaNode = [[A_SImageNode alloc] init];
            _viaNode.image = (_post.via == 1) ? [UIImage imageNamed:@"icon_ios.png"] : [UIImage imageNamed:@"icon_android.png"];
            [self addSubnode:_viaNode];
        }
         */
        
        // Bottom controls
        if (!_embedded) {
            _likesNode = [[LikesNode alloc] initWithLikesCount:_post.likes.count];
            [self addSubnode:_likesNode];
            
            _commentsNode = [[CommentsNode alloc] initWithCommentsCount:_post.comments.count];
            [self addSubnode:_commentsNode];
            
            _optionsNode = [[A_SImageNode alloc] init];
            _optionsNode.image = [UIImage imageNamed:@"icon_more"];
            [self addSubnode:_optionsNode];
        }
        
        for (A_SDisplayNode *node in self.subnodes) {
            //node.layerBacked = YES;
        }
    }
    return self;
}

- (void)updateDividerColor
{
    /*
     * UITableViewCell traverses through all its descendant views and adjusts their background color accordingly
     * either to [UIColor clearColor], although potentially it could use the same color as the selection highlight itself.
     * After selection, the same trick is performed again in reverse, putting all the backgrounds back as they used to be.
     * But in our case, we don't want to have the background color disappearing so we reset it after highlighting or
     * selection is done.
     */
    _divider.backgroundColor = PostNodeDividerColor;
}

#pragma mark - A_SDisplayNode

- (void)didLoad
{
    // enable highlighting now that self.layer has loaded -- see A_SHighlightOverlayLayer.h
    self.layer.as_allowsHighlightDrawing = YES;
    
    [super didLoad];
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    // Horizontal stack for name, username, via icon and time
    
    A_SStackLayoutSpec *nameVerticalStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:5.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[_nameNode, _timeNode]];
    nameVerticalStack.style.flexShrink = 1.0f;
    
    NSMutableArray *layoutSpecChildren = [@[_nameNode] mutableCopy];
    [layoutSpecChildren addObject:_timeNode];
    
    A_SStackLayoutSpec *nameStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsCenter
     children:layoutSpecChildren];
    nameStack.style.alignSelf = A_SStackLayoutAlignSelfStretch;
    
    // bottom controls horizontal stack
    A_SStackLayoutSpec *controlsStack = nil;
    if (!_embedded) {
        controlsStack = [A_SStackLayoutSpec
         stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
         spacing:10
         justifyContent:A_SStackLayoutJustifyContentStart
         alignItems:A_SStackLayoutAlignItemsCenter
         children:@[_likesNode, _commentsNode, _optionsNode]];
        // Add more gaps for control line
        controlsStack.style.spacingAfter = 3.0;
        controlsStack.style.spacingBefore = 3.0;
    }
    
    NSMutableArray *mainStackContent = [[NSMutableArray alloc] init];
    
    if (_mediaNodes.count == 1) {
        [mainStackContent addObject:_mediaNodes.firstObject];
    }
    else {
        A_SStackLayoutSpec *mediaSpec = [A_SStackLayoutSpec
                                          stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                          spacing:8.0
                                          justifyContent:A_SStackLayoutJustifyContentStart
                                          alignItems:A_SStackLayoutAlignItemsStart
                                          children:_mediaNodes];
        [mainStackContent addObject:mediaSpec];
    }
    
    if (_verticalLineNode && _historyNode) {
        A_SInsetLayoutSpec *verticalLineSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_verticalLineNode];
        A_SInsetLayoutSpec *historySpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_historyNode];
        
        historySpec.style.flexShrink = 1.0;
        A_SStackLayoutSpec *historyHorizontalSpec =
        [A_SStackLayoutSpec
         stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
         spacing:8.0
         justifyContent:A_SStackLayoutJustifyContentStart
         alignItems:A_SStackLayoutAlignItemsStretch
         children:@[verticalLineSpec, historySpec]];
        historyHorizontalSpec.style.flexShrink = 1.0;
        [mainStackContent addObject:historyHorizontalSpec];
    }
    
    // Vertical spec of cell main content
    A_SStackLayoutSpec *contentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStretch
     children:mainStackContent];
    contentSpec.style.flexShrink = 1.0;
    
    A_SInsetLayoutSpec *rightSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_verticalRightNode];
    
    A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    // Horizontal spec for avatar
    A_SStackLayoutSpec *avatarContentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[_avatarNode, nameVerticalStack, spacer, rightSpec]];
    
    NSMutableArray *verticalContentSpecArray = [@[avatarContentSpec, _postNode, contentSpec] mutableCopy];
    if (controlsStack) {
        [verticalContentSpecArray addObject:controlsStack];
    }
    A_SStackLayoutSpec *verticalContentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStretch
     children:verticalContentSpecArray];
    verticalContentSpec.style.flexShrink = 1.0;
    
    return [A_SInsetLayoutSpec
            insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
            child:verticalContentSpec];
    
}

- (void)layout
{
    [super layout];
    
    // Manually layout the divider.
    CGFloat pixelHeight = 1.0f / [[UIScreen mainScreen] scale];
    _divider.frame = CGRectMake(0.0f, 0.0f, self.calculatedSize.width, pixelHeight);
}

#pragma mark - A_SCellNode

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    [self updateDividerColor];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self updateDividerColor];
}

#pragma mark - <A_STextNodeDelegate>

- (BOOL)textNode:(A_STextNode *)richTextNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
    // Opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
    return YES;
}

- (void)textNode:(A_STextNode *)richTextNode tappedLinkAttribute:(NSString *)attribute value:(NSURL *)URL atPoint:(CGPoint)point textRange:(NSRange)textRange
{
    // The node tapped a link, open it
    [[UIApplication sharedApplication] openURL:URL];
}

- (void)textNodeTappedTruncationToken:(A_STextNode *)textNode {
    _postNode.maximumNumberOfLines = 0.f;
    [self setNeedsLayout];
}

#pragma mark - A_SNetworkImageNodeDelegate methods.

- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}


@end
