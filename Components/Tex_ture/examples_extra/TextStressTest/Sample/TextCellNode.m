//
//  TextCellNode.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "TextCellNode.h"
#import <Async_DisplayKit/Async_DisplayKit.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>

#ifndef USE_A_STEXTNODE_2
#define USE_A_STEXTNODE_2 1
#endif

@interface TextCellNode()
{
#if USE_A_STEXTNODE_2
  A_STextNode2 *_label1;
  A_STextNode2 *_label2;
#else
  A_STextNode *_label1;
  A_STextNode *_label2;
#endif
}
@end

@implementation TextCellNode

- (instancetype)initWithText1:(NSString *)text1 text2:(NSString *)text2
{
  self = [super init];
  if (self) {
    self.automaticallyManagesSubnodes = YES;
    self.clipsToBounds = YES;
#if USE_A_STEXTNODE_2
    _label1 = [[A_STextNode2 alloc] init];
    _label2 = [[A_STextNode2 alloc] init];
#else 
    _label1 = [[A_STextNode alloc] init];
    _label2 = [[A_STextNode alloc] init];
#endif

    _label1.attributedText = [[NSAttributedString alloc] initWithString:text1];
    _label2.attributedText = [[NSAttributedString alloc] initWithString:text2];

    _label1.maximumNumberOfLines = 1;
    _label1.truncationMode = NSLineBreakByTruncatingTail;
    _label2.maximumNumberOfLines = 1;
    _label2.truncationMode = NSLineBreakByTruncatingTail;

    [self simpleSetupYogaLayout];
  }
  return self;
}

/** 
  This is to text a row with two labels, the first should be truncated with "...".
  Layout is like: [l1Container[_label1], label2].
  This shows a bug of A_STextNode2.
 */
- (void)simpleSetupYogaLayout
{
  [self.style yogaNodeCreateIfNeeded];
  [_label1.style yogaNodeCreateIfNeeded];
  [_label2.style yogaNodeCreateIfNeeded];

  _label1.style.flexGrow = 0;
  _label1.style.flexShrink = 1;
  _label1.backgroundColor = [UIColor lightGrayColor];

  _label2.style.flexGrow = 0;
  _label2.style.flexShrink = 0;
  _label2.backgroundColor = [UIColor greenColor];

  A_SDisplayNode *l1Container = [A_SDisplayNode yogaVerticalStack];

  // TODO(fix A_STextNode2): next two line will show the bug of TextNode2
  // which works for A_STextNode though
  // see discussion here: https://github.com/Tex_tureGroup/Tex_ture/pull/553
  l1Container.style.alignItems = A_SStackLayoutAlignItemsCenter;
  _label1.style.alignSelf = A_SStackLayoutAlignSelfStart;

  l1Container.style.flexGrow = 0;
  l1Container.style.flexShrink = 1;

  l1Container.yogaChildren = @[_label1];

  self.style.justifyContent = A_SStackLayoutJustifyContentSpaceBetween;
  self.style.alignItems = A_SStackLayoutAlignItemsStart;
  self.style.flexDirection = A_SStackLayoutDirectionHorizontal;
  self.yogaChildren = @[l1Container, _label2];
}

@end
