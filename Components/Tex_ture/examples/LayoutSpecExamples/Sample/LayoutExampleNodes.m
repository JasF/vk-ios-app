//
//  LayoutExampleNodes.m
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

#import "LayoutExampleNodes.h"

#import <Async_DisplayKit/UIImage+A_SConvenience.h>

#import "Utilities.h"

@interface HeaderWithRightAndLeftItems ()
@property (nonatomic, strong) A_STextNode *usernameNode;
@property (nonatomic, strong) A_STextNode *postLocationNode;
@property (nonatomic, strong) A_STextNode *postTimeNode;
@end

@interface PhotoWithInsetTextOverlay ()
@property (nonatomic, strong) A_SNetworkImageNode *photoNode;
@property (nonatomic, strong) A_STextNode *titleNode;
@end

@interface PhotoWithOutsetIconOverlay ()
@property (nonatomic, strong) A_SNetworkImageNode *photoNode;
@property (nonatomic, strong) A_SNetworkImageNode *iconNode;
@end

@interface FlexibleSeparatorSurroundingContent ()
@property (nonatomic, strong) A_SImageNode *topSeparator;
@property (nonatomic, strong) A_SImageNode *bottomSeparator;
@property (nonatomic, strong) A_STextNode *textNode;
@end

@implementation HeaderWithRightAndLeftItems

+ (NSString *)title
{
  return @"Header with left and right justified text";
}

+ (NSString *)descriptionTitle
{
  return @"try rotating me!";
}

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _usernameNode = [[A_STextNode alloc] init];
    _usernameNode.attributedText = [NSAttributedString attributedStringWithString:@"hannahmbanana"
                                                                         fontSize:20
                                                                            color:[UIColor darkBlueColor]];
    _usernameNode.maximumNumberOfLines = 1;
    _usernameNode.truncationMode = NSLineBreakByTruncatingTail;
    
    _postLocationNode = [[A_STextNode alloc] init];
    _postLocationNode.maximumNumberOfLines = 1;
    _postLocationNode.attributedText = [NSAttributedString attributedStringWithString:@"Sunset Beach, San Fransisco, CA"
                                                                             fontSize:20
                                                                                color:[UIColor lightBlueColor]];
    _postLocationNode.maximumNumberOfLines = 1;
    _postLocationNode.truncationMode = NSLineBreakByTruncatingTail;
    
    _postTimeNode = [[A_STextNode alloc] init];
    _postTimeNode.attributedText = [NSAttributedString attributedStringWithString:@"30m"
                                                                         fontSize:20
                                                                            color:[UIColor lightGrayColor]];
    _postLocationNode.maximumNumberOfLines = 1;
    _postLocationNode.truncationMode = NSLineBreakByTruncatingTail;
  }
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{

  A_SStackLayoutSpec *nameLocationStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  nameLocationStack.style.flexShrink = 1.0;
  nameLocationStack.style.flexGrow = 1.0;
  
  if (_postLocationNode.attributedText) {
    nameLocationStack.children = @[_usernameNode, _postLocationNode];
  } else {
    nameLocationStack.children = @[_usernameNode];
  }
  
  A_SStackLayoutSpec *headerStackSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                               spacing:40
                                                                        justifyContent:A_SStackLayoutJustifyContentStart
                                                                            alignItems:A_SStackLayoutAlignItemsCenter
                                                                              children:@[nameLocationStack, _postTimeNode]];
  
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, 10, 0, 10) child:headerStackSpec];
}

@end


@implementation PhotoWithInsetTextOverlay

+ (NSString *)title
{
  return @"Photo with inset text overlay";
}

+ (NSString *)descriptionTitle
{
  return @"try rotating me!";
}

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    self.backgroundColor = [UIColor clearColor];
    
    _photoNode = [[A_SNetworkImageNode alloc] init];
    _photoNode.URL = [NSURL URLWithString:@"http://texturegroup.org/static/images/layout-examples-photo-with-inset-text-overlay-photo.png"];
    _photoNode.willDisplayNodeContentWithRenderingContext = ^(CGContextRef context, id drawParameters) {
      CGRect bounds = CGContextGetClipBoundingBox(context);
      [[UIBezierPath bezierPathWithRoundedRect:bounds cornerRadius:10] addClip];
    };
    
    _titleNode = [[A_STextNode alloc] init];
    _titleNode.maximumNumberOfLines = 2;
    _titleNode.truncationMode = NSLineBreakByTruncatingTail;
    _titleNode.truncationAttributedText = [NSAttributedString attributedStringWithString:@"..." fontSize:16 color:[UIColor whiteColor]];
    _titleNode.attributedText = [NSAttributedString attributedStringWithString:@"family fall hikes" fontSize:16 color:[UIColor whiteColor]];
  }
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  CGFloat photoDimension = constrainedSize.max.width / 4.0;
  _photoNode.style.preferredSize = CGSizeMake(photoDimension, photoDimension);

  // INFINITY is used to make the inset unbounded
  UIEdgeInsets insets = UIEdgeInsetsMake(INFINITY, 12, 12, 12);
  A_SInsetLayoutSpec *textInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:_titleNode];
  
  return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:_photoNode overlay:textInsetSpec];;
}

@end


@implementation PhotoWithOutsetIconOverlay

+ (NSString *)title
{
  return @"Photo with outset icon overlay";
}

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _photoNode = [[A_SNetworkImageNode alloc] init];
    _photoNode.URL = [NSURL URLWithString:@"http://texturegroup.org/static/images/layout-examples-photo-with-outset-icon-overlay-photo.png"];
    
    _iconNode = [[A_SNetworkImageNode alloc] init];
    _iconNode.URL = [NSURL URLWithString:@"http://texturegroup.org/static/images/layout-examples-photo-with-outset-icon-overlay-icon.png"];
    
    [_iconNode setImageModificationBlock:^UIImage *(UIImage *image) {   // FIXME: in framework autocomplete for setImageModificationBlock line seems broken
      CGSize profileImageSize = CGSizeMake(60, 60);
      return [image makeCircularImageWithSize:profileImageSize withBorderWidth:10];
    }];
  }
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _iconNode.style.preferredSize = CGSizeMake(40, 40);
  _iconNode.style.layoutPosition = CGPointMake(150, 0);
  
  _photoNode.style.preferredSize = CGSizeMake(150, 150);
  _photoNode.style.layoutPosition = CGPointMake(40 / 2.0, 40 / 2.0);
  
  A_SAbsoluteLayoutSpec *absoluteSpec = [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[_photoNode, _iconNode]];
  
  // A_SAbsoluteLayoutSpec's .sizing property recreates the behavior of A_SDK Layout API 1.0's "A_SStaticLayoutSpec"
  absoluteSpec.sizing = A_SAbsoluteLayoutSpecSizingSizeToFit;
  
  return absoluteSpec;
}



@end


@implementation FlexibleSeparatorSurroundingContent

+ (NSString *)title
{
  return @"Top and bottom cell separator lines";
}

+ (NSString *)descriptionTitle
{
  return @"try rotating me!";
}

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    self.backgroundColor = [UIColor whiteColor];

    _topSeparator = [[A_SImageNode alloc] init];
    _topSeparator.image = [UIImage as_resizableRoundedImageWithCornerRadius:1.0 cornerColor:[UIColor blackColor] fillColor:[UIColor blackColor]];
    
    _textNode = [[A_STextNode alloc] init];
    _textNode.attributedText = [NSAttributedString attributedStringWithString:@"this is a long text node"
                                                                     fontSize:16
                                                                        color:[UIColor blackColor]];
    
    _bottomSeparator = [[A_SImageNode alloc] init];
    _bottomSeparator.image = [UIImage as_resizableRoundedImageWithCornerRadius:1.0 cornerColor:[UIColor blackColor] fillColor:[UIColor blackColor]];
  }
  
  return self;
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _topSeparator.style.flexGrow = 1.0;
  _bottomSeparator.style.flexGrow = 1.0;
  _textNode.style.alignSelf = A_SStackLayoutAlignSelfCenter;
  
  A_SStackLayoutSpec *verticalStackSpec = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStackSpec.spacing = 20;
  verticalStackSpec.justifyContent = A_SStackLayoutJustifyContentCenter;
  verticalStackSpec.children = @[_topSeparator, _textNode, _bottomSeparator];

  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(60, 0, 60, 0) child:verticalStackSpec];
}

@end

@implementation LayoutExampleNode

+ (NSString *)title
{
  NSAssert(NO, @"All layout example nodes must provide a title!");
  return nil;
}

+ (NSString *)descriptionTitle
{
  return nil;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.automaticallyManagesSubnodes = YES;
    self.backgroundColor = [UIColor whiteColor];
  }
  return self;
}

@end

