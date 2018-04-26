//
//  A_SNavigationController.m
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

#import <Async_DisplayKit/A_SNavigationController.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

@implementation A_SNavigationController
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
  
  if (viewControllerIndex == self.viewControllers.count - 1) {
    //view controller is at the top, just return our own visibility depth.
    return [self visibilityDepth];
  } else if (viewControllerIndex == 0) {
    //view controller is the root view controller. Can be accessed by holding the back button.
    return [self visibilityDepth] + 1;
  }
  
  return [self visibilityDepth] + self.viewControllers.count - 1 - viewControllerIndex;
}

#pragma mark - UIKit overrides

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  as_activity_create_for_scope("Pop multiple from A_SNavigationController");
  NSArray *viewControllers = [super popToViewController:viewController animated:animated];
  as_log_info(A_SNodeLog(), "Popped %@ to %@, removing %@", self, viewController, A_SGetDescriptionValueString(viewControllers));

  [self visibilityDepthDidChange];
  return viewControllers;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated
{
  as_activity_create_for_scope("Pop to root of A_SNavigationController");
  NSArray *viewControllers = [super popToRootViewControllerAnimated:animated];
  as_log_info(A_SNodeLog(), "Popped view controllers %@ from %@", A_SGetDescriptionValueString(viewControllers), self);

  [self visibilityDepthDidChange];
  return viewControllers;
}

- (void)setViewControllers:(NSArray *)viewControllers
{
  // NOTE: As of now this method calls through to setViewControllers:animated: so no need to log/activity here.
  
  [super setViewControllers:viewControllers];
  [self visibilityDepthDidChange];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated
{
  as_activity_create_for_scope("Set view controllers of A_SNavigationController");
  as_log_info(A_SNodeLog(), "Set view controllers of %@ to %@ animated: %d", self, A_SGetDescriptionValueString(viewControllers), animated);
  [super setViewControllers:viewControllers animated:animated];
  [self visibilityDepthDidChange];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
  as_activity_create_for_scope("Push view controller on A_SNavigationController");
  as_log_info(A_SNodeLog(), "Pushing %@ onto %@", viewController, self);
  [super pushViewController:viewController animated:animated];
  [self visibilityDepthDidChange];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
  as_activity_create_for_scope("Pop view controller from A_SNavigationController");
  UIViewController *viewController = [super popViewControllerAnimated:animated];
  as_log_info(A_SNodeLog(), "Popped %@ from %@", viewController, self);
  [self visibilityDepthDidChange];
  return viewController;
}

@end
