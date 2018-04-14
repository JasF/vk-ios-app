//
//  A_STabBarController.m
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

#import <Async_DisplayKit/A_STabBarController.h>
#import <Async_DisplayKit/A_SLog.h>

@implementation A_STabBarController
{
  BOOL _parentManagesVisibilityDepth;
  NSInteger _visibilityDepth;
}

A_SVisibilityDidMoveToParentViewController;

A_SVisibilityViewWillAppear;

A_SVisibilityViewDidDisappearImplementation;

A_SVisibilitySetVisibilityDepth;

A_SVisibilityDepthImplementation;

- (void)visibilityDepthDidChange
{
  for (UIViewController *viewController in self.viewControllers) {
    if ([viewController conformsToProtocol:@protocol(A_SVisibilityDepth)]) {
      [(id <A_SVisibilityDepth>)viewController visibilityDepthDidChange];
    }
  }
}

- (NSInteger)visibilityDepthOfChildViewController:(UIViewController *)childViewController
{
  NSUInteger viewControllerIndex = [self.viewControllers indexOfObjectIdenticalTo:childViewController];
  if (viewControllerIndex == NSNotFound) {
    //If childViewController is not actually a child, return NSNotFound which is also a really large number.
    return NSNotFound;
  }
  
  if (self.selectedViewController == childViewController) {
    return [self visibilityDepth];
  }
  return [self visibilityDepth] + 1;
}

#pragma mark - UIKit overrides

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers
{
  [super setViewControllers:viewControllers];
  [self visibilityDepthDidChange];
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers animated:(BOOL)animated
{
  [super setViewControllers:viewControllers animated:animated];
  [self visibilityDepthDidChange];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
  as_activity_create_for_scope("Set selected index of A_STabBarController");
  as_log_info(A_SNodeLog(), "Selected tab %tu of %@", selectedIndex, self);

  [super setSelectedIndex:selectedIndex];
  [self visibilityDepthDidChange];
}

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController
{
  as_activity_create_for_scope("Set selected view controller of A_STabBarController");
  as_log_info(A_SNodeLog(), "Selected view controller %@ of %@", selectedViewController, self);

  [super setSelectedViewController:selectedViewController];
  [self visibilityDepthDidChange];
}

@end
