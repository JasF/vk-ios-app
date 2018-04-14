//
//  BlurbNode.m
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) through the present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "BlurbNode.h"

#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SHighlightOverlayLayer.h>

#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_SCenterLayoutSpec.h>

static CGFloat kTextPadding = 10.0f;

@interface BlurbNode () <A_STextNodeDelegate>
{
  A_STextNode *_textNode;
}

@end


@implementation BlurbNode

#pragma mark -
#pragma mark A_SCellNode.

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  self.backgroundColor = [UIColor lightGrayColor];
  // create a text node
  _textNode = [[A_STextNode alloc] init];
  _textNode.maximumNumberOfLines = 2;

  // configure the node to support tappable links
  _textNode.delegate = self;
  _textNode.userInteractionEnabled = YES;

  // generate an attributed string using the custom link attribute specified above
  NSString *blurb = @"Kittens courtesy lorempixel.com \U0001F638 \nTitles courtesy of catipsum.com";
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:blurb];
  [string addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f] range:NSMakeRange(0, blurb.length)];
  [string addAttributes:@{
    NSLinkAttributeName: [NSURL URLWithString:@"http://lorempixel.com/"],
    NSForegroundColorAttributeName: [UIColor blueColor],
    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternDot),
  } range:[blurb rangeOfString:@"lorempixel.com"]];
  [string addAttributes:@{
    NSLinkAttributeName: [NSURL URLWithString:@"http://www.catipsum.com/"],
    NSForegroundColorAttributeName: [UIColor blueColor],
    NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternDot),
  } range:[blurb rangeOfString:@"catipsum.com"]];
  _textNode.attributedText = string;

  // add it as a subnode, and we're done
  [self addSubnode:_textNode];

  return self;
}

- (void)didLoad
{
  // enable highlighting now that self.layer has loaded -- see A_SHighlightOverlayLayer.h
  self.layer.as_allowsHighlightDrawing = YES;

  [super didLoad];
}

- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SCenterLayoutSpec *centerSpec = [[A_SCenterLayoutSpec alloc] init];
  centerSpec.centeringOptions = A_SCenterLayoutSpecCenteringX;
  centerSpec.sizingOptions = A_SCenterLayoutSpecSizingOptionMinimumY;
  centerSpec.child = _textNode;
  
  UIEdgeInsets padding = UIEdgeInsetsMake(kTextPadding, kTextPadding, kTextPadding, kTextPadding);
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:padding child:centerSpec];
}


#pragma mark -
#pragma mark A_STextNodeDelegate methods.

- (BOOL)textNode:(A_STextNode *)richTextNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
  // opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
  return YES;
}

- (void)textNode:(A_STextNode *)richTextNode tappedLinkAttribute:(NSString *)attribute value:(NSURL *)URL atPoint:(CGPoint)point textRange:(NSRange)textRange
{
  // the node tapped a link, open it
  [[UIApplication sharedApplication] openURL:URL];
}

@end
