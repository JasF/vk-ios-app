//
//  WallPostNode.m
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "WallPostNode.h"
#import "WallPost.h"
#import "TextStyles.h"
#import "LikesNode.h"
#import "CommentsNode.h"

#define PostNodeDividerColor [UIColor lightGrayColor]

@interface WallPostNode() <ASNetworkImageNodeDelegate, ASTextNodeDelegate>

@property (strong, nonatomic) WallPost *post;
@property (strong, nonatomic) ASDisplayNode *divider;
@property (strong, nonatomic) ASTextNode *nameNode;
@property (strong, nonatomic) ASTextNode *usernameNode;
@property (strong, nonatomic) ASTextNode *timeNode;
@property (strong, nonatomic) ASTextNode *postNode;
@property (strong, nonatomic) ASImageNode *viaNode;
@property (strong, nonatomic) ASNetworkImageNode *avatarNode;
@property (strong, nonatomic) LikesNode *likesNode;
@property (strong, nonatomic) CommentsNode *commentsNode;
@property (strong, nonatomic) ASImageNode *optionsNode;

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
    self = [super init];
    if (self) {
        _mediaNodes = [NSMutableArray new];
        _nodeFactory = nodeFactory;
        _embedded = embedded.boolValue;
        _post = post;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // Name node
        _nameNode = [[ASTextNode alloc] init];
        _nameNode.attributedText = [[NSAttributedString alloc] initWithString:_post.firstName ?: @"" attributes:[TextStyles nameStyle]];
        _nameNode.maximumNumberOfLines = 1;
        [self addSubnode:_nameNode];
        
        // Username node
        _usernameNode = [[ASTextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:@"" attributes:[TextStyles usernameStyle]];
        _usernameNode.style.flexShrink = 1.0; //if name and username don't fit to cell width, allow username shrink
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        _usernameNode.maximumNumberOfLines = 1;
        [self addSubnode:_usernameNode];
        
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
            _verticalLineNode = [ASDisplayNode new];
            _verticalLineNode.style.preferredSize = CGSizeMake(2, 50);
            _verticalLineNode.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25f];
            [self addSubnode:_verticalLineNode];
            [self addSubnode:_historyNode];
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
        /*
        Attachments *attachment = _post.attachments.firstObject;
        if (![attachment.photo.photo604 isEqualToString:@""]) {
            
            _mediaNode = [[ASNetworkImageNode alloc] init];
            _mediaNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
            _mediaNode.cornerRadius = 4.0;
            _mediaNode.URL = [NSURL URLWithString:attachment.photo.photo604];
            _mediaNode.delegate = self;
            _mediaNode.imageModificationBlock = ^UIImage *(UIImage *image) {
                
                UIImage *modifiedImage;
                CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
                
                UIGraphicsBeginImageContextWithOptions(image.size, false, [[UIScreen mainScreen] scale]);
                
                [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:8.0] addClip];
                [image drawInRect:rect];
                modifiedImage = UIGraphicsGetImageFromCurrentImageContext();
                
                UIGraphicsEndImageContext();
                
                return modifiedImage;
                
            };
            [self addSubnode:_mediaNode];
        }
         */
        
        // User pic
        _avatarNode = [[ASNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = ASDimensionMakeWithPoints(44);
        _avatarNode.style.height = ASDimensionMakeWithPoints(44);
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
        _divider = [[ASDisplayNode alloc] init];
        [self updateDividerColor];
        [self addSubnode:_divider];
        */
        /*
        // Via
        if (_post.via != 0) {
            _viaNode = [[ASImageNode alloc] init];
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
            
            _optionsNode = [[ASImageNode alloc] init];
            _optionsNode.image = [UIImage imageNamed:@"icon_more"];
            [self addSubnode:_optionsNode];
        }
        
        for (ASDisplayNode *node in self.subnodes) {
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

#pragma mark - ASDisplayNode

- (void)didLoad
{
    // enable highlighting now that self.layer has loaded -- see ASHighlightOverlayLayer.h
    self.layer.as_allowsHighlightDrawing = YES;
    
    [super didLoad];
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    // Flexible spacer between username and time
    ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
    
    // Horizontal stack for name, username, via icon and time
    NSMutableArray *layoutSpecChildren = [@[_nameNode, _usernameNode, spacer] mutableCopy];
    /*
    if (_post.via != 0) {
        [layoutSpecChildren addObject:_viaNode];
    }
     */
    [layoutSpecChildren addObject:_timeNode];
    
    ASStackLayoutSpec *nameStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:5.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:layoutSpecChildren];
    nameStack.style.alignSelf = ASStackLayoutAlignSelfStretch;
    
    // bottom controls horizontal stack
    ASStackLayoutSpec *controlsStack = nil;
    if (!_embedded) {
        controlsStack = [ASStackLayoutSpec
         stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
         spacing:10
         justifyContent:ASStackLayoutJustifyContentStart
         alignItems:ASStackLayoutAlignItemsCenter
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
        
    }
    
    if (_verticalLineNode && _historyNode) {
        ASInsetLayoutSpec *verticalLineSpec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_verticalLineNode];
        ASInsetLayoutSpec *historySpec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:_historyNode];
        historySpec.style.flexShrink = 1.0;
        ASStackLayoutSpec *historyHorizontalSpec =
        [ASStackLayoutSpec
         stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
         spacing:8.0
         justifyContent:ASStackLayoutJustifyContentStart
         alignItems:ASStackLayoutAlignItemsStretch
         children:@[verticalLineSpec, historySpec]];
        historyHorizontalSpec.style.flexShrink = 1.0;
        [mainStackContent addObject:historyHorizontalSpec];
    }
    
    // Vertical spec of cell main content
    ASStackLayoutSpec *contentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:mainStackContent];
    contentSpec.style.flexShrink = 1.0;
    
    // Horizontal spec for avatar
    ASStackLayoutSpec *avatarContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStart
     children:@[_avatarNode, nameStack]];
    
    NSMutableArray *verticalContentSpecArray = [@[avatarContentSpec, _postNode, contentSpec] mutableCopy];
    if (controlsStack) {
        [verticalContentSpecArray addObject:controlsStack];
    }
    ASStackLayoutSpec *verticalContentSpec =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsStretch
     children:verticalContentSpecArray];
    verticalContentSpec.style.flexShrink = 1.0;
    
    return [ASInsetLayoutSpec
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

#pragma mark - ASCellNode

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

#pragma mark - ASNetworkImageNodeDelegate methods.

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}


@end
