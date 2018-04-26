//
//  A_STipsWindow.m
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

#import "A_STipsWindow.h"
#if A_S_ENABLE_TIPS

#import <Async_DisplayKit/A_SDisplayNodeTipState.h>
#import <Async_DisplayKit/A_STipNode.h>
#import <Async_DisplayKit/A_STip.h>
#import <Async_DisplayKit/Async_DisplayKit+Tips.h>

@interface A_STipsWindow ()
@property (nonatomic, strong, readonly) A_SDisplayNode *node;
@end

@implementation A_STipsWindow

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    /**
     * UIKit throws an exception if you don't add a root view controller to a window,
     * but if the window isn't key, then it doesn't manage the root view controller correctly!
     *
     * So we set a dummy root view controller and hide it.
     */
    self.rootViewController = [UIViewController new];
    self.rootViewController.view.hidden = YES;

    _node = [[A_SDisplayNode alloc] init];
    [self addSubnode:_node];

    self.windowLevel = UIWindowLevelNormal + 1;
    self.opaque = NO;
  }
  return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView *result = [super hitTest:point withEvent:event];
  // Ignore touches unless they hit one of my node's subnodes
  if (result == _node.view) {
    return nil;
  }
  return result;
}

- (void)setMainWindow:(UIWindow *)mainWindow
{
  _mainWindow = mainWindow;
  for (A_SDisplayNode *node in _node.subnodes) {
    [node removeFromSupernode];
  }
}

- (void)didTapTipNode:(A_STipNode *)tipNode
{
  A_SDisplayNode.tipDisplayBlock(tipNode.tip.node, tipNode.tip.text);
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  _node.frame = self.bounds;
  
  // Ensure the main window is laid out first.
  [self.mainWindow layoutIfNeeded];
  
  NSMutableSet *tipNodesToRemove = [NSMutableSet setWithArray:_node.subnodes];
  for (A_SDisplayNodeTipState *tipState in [_nodeToTipStates objectEnumerator]) {
    A_SDisplayNode *node = tipState.node;
    A_STipNode *tipNode = tipState.tipNode;
    [tipNodesToRemove removeObject:tipNode];
    CGRect rect = node.bounds;
    rect = [node.view convertRect:rect toView:nil];
    rect = [self convertRect:rect fromView:nil];
    tipNode.frame = rect;
    if (tipNode.supernode != _node) {
      [_node addSubnode:tipNode];
    }
  }
  
  // Clean up any tip nodes whose target nodes have disappeared.
  for (A_STipNode *tipNode in tipNodesToRemove) {
    [tipNode removeFromSupernode];
  }
}

@end

#endif // A_S_ENABLE_TIPS
