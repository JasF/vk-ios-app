//
//  A_STipsController.m
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

#import "A_STipsController.h"

#if A_S_ENABLE_TIPS

#import <Async_DisplayKit/A_SDisplayNodeTipState.h>
#import <Async_DisplayKit/Async_DisplayKit+Tips.h>
#import <Async_DisplayKit/A_STipNode.h>
#import <Async_DisplayKit/A_STipProvider.h>
#import <Async_DisplayKit/A_STipsWindow.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>

@interface A_STipsController ()

/// Nil on init, updates to most recent visible window.
@property (nonatomic, strong) UIWindow *appVisibleWindow;

/// Nil until an application window has become visible.
@property (nonatomic, strong) A_STipsWindow *tipWindow;

/// Main-thread-only.
@property (nonatomic, strong, readonly) NSMapTable<A_SDisplayNode *, A_SDisplayNodeTipState *> *nodeToTipStates;

@property (nonatomic, strong) NSMutableArray<A_SDisplayNode *> *nodesThatAppearedDuringRunLoop;

@end

@implementation A_STipsController

#pragma mark - Singleton

+ (void)load
{
  [NSNotificationCenter.defaultCenter addObserver:self.shared
                                         selector:@selector(windowDidBecomeVisibleWithNotification:)
                                             name:UIWindowDidBecomeVisibleNotification
                                           object:nil];
}

+ (A_STipsController *)shared
{
  static A_STipsController *ctrl;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    ctrl = [[A_STipsController alloc] init];
  });
  return ctrl;
}

#pragma mark - Lifecycle

- (instancetype)init
{
  A_SDisplayNodeAssertMainThread();
  if (self = [super init]) {
    _nodeToTipStates = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality) valueOptions:NSPointerFunctionsStrongMemory];
    _nodesThatAppearedDuringRunLoop = [NSMutableArray array];
  }
  return self;
}

#pragma mark - Event Handling

- (void)nodeDidAppear:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertMainThread();
  // If they disabled tips on this class, bail.
  if (![[node class] enableTips]) {
    return;
  }

  // If this node appeared in some other window (like our tips window) ignore it.
  if (A_SFindWindowOfLayer(node.layer) != self.appVisibleWindow) {
    return;
  }

  [_nodesThatAppearedDuringRunLoop addObject:node];
}

// If this is a main window, start watching it and clear out our tip window.
- (void)windowDidBecomeVisibleWithNotification:(NSNotification *)notification
{
  A_SDisplayNodeAssertMainThread();
  UIWindow *window = notification.object;

  // If this is the same window we're already watching, bail.
  if (window == self.appVisibleWindow) {
    return;
  }

  // Ignore windows that are not at the normal level or have empty bounds
  if (window.windowLevel != UIWindowLevelNormal || CGRectIsEmpty(window.bounds)) {
    return;
  }

  self.appVisibleWindow = window;

  // Create the tip window if needed.
  [self createTipWindowIfNeededWithFrame:window.bounds];

  // Clear out our tip window and reset our states.
  self.tipWindow.mainWindow = window;
  [_nodeToTipStates removeAllObjects];
}

- (void)runLoopDidTick
{
  NSArray *nodes = [_nodesThatAppearedDuringRunLoop copy];
  [_nodesThatAppearedDuringRunLoop removeAllObjects];

  // Go through the old array, removing any that have tips but aren't still visible.
  for (A_SDisplayNode *node in [_nodeToTipStates copy]) {
    if (!node.visible) {
      [_nodeToTipStates removeObjectForKey:node];
    }
  }

  for (A_SDisplayNode *node in nodes) {
    // Get the tip state for the node.
    A_SDisplayNodeTipState *tipState = [_nodeToTipStates objectForKey:node];

    // If the node already has a tip, bail. This could change.
    if (tipState.tipNode != nil) {
      return;
    }

    for (A_STipProvider *provider in A_STipProvider.all) {
      A_STip *tip = [provider tipForNode:node];
      if (!tip) { continue; }

      if (!tipState) {
        tipState = [self createTipStateForNode:node];
      }
      tipState.tipNode = [[A_STipNode alloc] initWithTip:tip];
    }
  }
  self.tipWindow.nodeToTipStates = _nodeToTipStates;
  [self.tipWindow setNeedsLayout];
}

#pragma mark - Internal

- (void)createTipWindowIfNeededWithFrame:(CGRect)tipWindowFrame
{
  // Lots of property accesses, but simple safe code, only run once.
  if (self.tipWindow == nil) {
    self.tipWindow = [[A_STipsWindow alloc] initWithFrame:tipWindowFrame];
    self.tipWindow.hidden = NO;
    [self setupRunLoopObserver];
  }
}

/**
 * In order to keep the UI updated, the tips controller registers a run loop observer.
 * Before the transaction commit happens, the tips controller calls -setNeedsLayout
 * on the view controller's view. It will then layout the main window, and then update the frames
 * for tip nodes accordingly.
 */
- (void)setupRunLoopObserver
{
  CFRunLoopObserverRef o = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
    [self runLoopDidTick];
  });
  CFRunLoopAddObserver(CFRunLoopGetMain(), o, kCFRunLoopCommonModes);
}

- (A_SDisplayNodeTipState *)createTipStateForNode:(A_SDisplayNode *)node
{
  A_SDisplayNodeAssertMainThread();
  A_SDisplayNodeTipState *tipState = [[A_SDisplayNodeTipState alloc] initWithNode:node];
  [_nodeToTipStates setObject:tipState forKey:node];
  return tipState;
}

@end

#endif // A_S_ENABLE_TIPS
