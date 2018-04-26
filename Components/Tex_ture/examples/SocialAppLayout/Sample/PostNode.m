//
//  PostNode.m
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "PostNode.h"
#import "Post.h"
#import "TextStyles.h"
#import "LikesNode.h"
#import "CommentsNode.h"

#define PostNodeDividerColor [UIColor lightGrayColor]

@interface PostNode() <A_SNetworkImageNodeDelegate, A_STextNodeDelegate>

@property (strong, nonatomic) Post *post;
@property (strong, nonatomic) A_SDisplayNode *divider;
@property (strong, nonatomic) A_STextNode *nameNode;
@property (strong, nonatomic) A_STextNode *usernameNode;
@property (strong, nonatomic) A_STextNode *timeNode;
@property (strong, nonatomic) A_STextNode *postNode;
@property (strong, nonatomic) A_SImageNode *viaNode;
@property (strong, nonatomic) A_SNetworkImageNode *avatarNode;
@property (strong, nonatomic) A_SNetworkImageNode *mediaNode;
@property (strong, nonatomic) LikesNode *likesNode;
@property (strong, nonatomic) CommentsNode *commentsNode;
@property (strong, nonatomic) A_SImageNode *optionsNode;

@end

@implementation PostNode

#pragma mark - Lifecycle

- (instancetype)initWithPost:(Post *)post
{
    self = [super init];
    if (self) {
        _post = post;
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        // Name node
        _nameNode = [[A_STextNode alloc] init];
        _nameNode.attributedText = [[NSAttributedString alloc] initWithString:_post.name attributes:[TextStyles nameStyle]];
        _nameNode.maximumNumberOfLines = 1;
        [self addSubnode:_nameNode];
        
        // Username node
        _usernameNode = [[A_STextNode alloc] init];
        _usernameNode.attributedText = [[NSAttributedString alloc] initWithString:_post.username attributes:[TextStyles usernameStyle]];
        _usernameNode.style.flexShrink = 1.0; //if name and username don't fit to cell width, allow username shrink
        _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
        _usernameNode.maximumNumberOfLines = 1;
        [self addSubnode:_usernameNode];
        
        // Time node
        _timeNode = [[A_STextNode alloc] init];
        _timeNode.attributedText = [[NSAttributedString alloc] initWithString:_post.time attributes:[TextStyles timeStyle]];
        [self addSubnode:_timeNode];
        
        // Post node
        _postNode = [[A_STextNode alloc] init];

        // Processing URLs in post
        NSString *kLinkAttributeName = @"TextLinkAttributeName";
        
        if (![_post.post isEqualToString:@""]) {
            
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:_post.post attributes:[TextStyles postStyle]];
            
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
        
        
        // Media
        if (![_post.media isEqualToString:@""]) {
            
            _mediaNode = [[A_SNetworkImageNode alloc] init];
            _mediaNode.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
            _mediaNode.cornerRadius = 4.0;
            _mediaNode.URL = [NSURL URLWithString:_post.media];
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
        
        // User pic
        _avatarNode = [[A_SNetworkImageNode alloc] init];
        _avatarNode.backgroundColor = A_SDisplayNodeDefaultPlaceholderColor();
        _avatarNode.style.width = A_SDimensionMakeWithPoints(44);
        _avatarNode.style.height = A_SDimensionMakeWithPoints(44);
        _avatarNode.cornerRadius = 22.0;
        _avatarNode.URL = [NSURL URLWithString:_post.photo];
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
        _divider = [[A_SDisplayNode alloc] init];
        [self updateDividerColor];
        [self addSubnode:_divider];
        
        // Via
        if (_post.via != 0) {
            _viaNode = [[A_SImageNode alloc] init];
            _viaNode.image = (_post.via == 1) ? [UIImage imageNamed:@"icon_ios.png"] : [UIImage imageNamed:@"icon_android.png"];
            [self addSubnode:_viaNode];
        }
        
        // Bottom controls
        _likesNode = [[LikesNode alloc] initWithLikesCount:_post.likes];
        [self addSubnode:_likesNode];
        
        _commentsNode = [[CommentsNode alloc] initWithCommentsCount:_post.comments];
        [self addSubnode:_commentsNode];
        
        _optionsNode = [[A_SImageNode alloc] init];
        _optionsNode.image = [UIImage imageNamed:@"icon_more"];
        [self addSubnode:_optionsNode];

        for (A_SDisplayNode *node in self.subnodes) {
            // A_STextNode with embedded links doesn't support layer backing
            if (node.supportsLayerBacking) {
                node.layerBacked = YES;
            }
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
    // Flexible spacer between username and time
    A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
    spacer.style.flexGrow = 1.0;
  
    // Horizontal stack for name, username, via icon and time
    NSMutableArray *layoutSpecChildren = [@[_nameNode, _usernameNode, spacer] mutableCopy];
    if (_post.via != 0) {
        [layoutSpecChildren addObject:_viaNode];
    }
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
    A_SStackLayoutSpec *controlsStack =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:10
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsCenter
     children:@[_likesNode, _commentsNode, _optionsNode]];
    
    // Add more gaps for control line
    controlsStack.style.spacingAfter = 3.0;
    controlsStack.style.spacingBefore = 3.0;
    
    NSMutableArray *mainStackContent = [[NSMutableArray alloc] init];
    [mainStackContent addObject:nameStack];
    [mainStackContent addObject:_postNode];
    
    
    if (![_post.media isEqualToString:@""]){
        
        // Only add the media node if an image is present
        if (_mediaNode.image != nil) {
            A_SRatioLayoutSpec *imagePlace =
            [A_SRatioLayoutSpec
             ratioLayoutSpecWithRatio:0.5
             child:_mediaNode];
            imagePlace.style.spacingAfter = 3.0;
            imagePlace.style.spacingBefore = 3.0;
            
            [mainStackContent addObject:imagePlace];
        }
    }
    [mainStackContent addObject:controlsStack];
    
    // Vertical spec of cell main content
    A_SStackLayoutSpec *contentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStretch
     children:mainStackContent];
    contentSpec.style.flexShrink = 1.0;
    
    // Horizontal spec for avatar
    A_SStackLayoutSpec *avatarContentSpec =
    [A_SStackLayoutSpec
     stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
     spacing:8.0
     justifyContent:A_SStackLayoutJustifyContentStart
     alignItems:A_SStackLayoutAlignItemsStart
     children:@[_avatarNode, contentSpec]];
    
    return [A_SInsetLayoutSpec
            insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 10, 10, 10)
            child:avatarContentSpec];
    
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

#pragma mark - A_SNetworkImageNodeDelegate methods.

- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image
{
    [self setNeedsLayout];
}

@end
