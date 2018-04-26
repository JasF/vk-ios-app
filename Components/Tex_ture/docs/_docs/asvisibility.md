---
title: A_SVisibility
layout: docs
permalink: /docs/asvisibility.html
prevPage: debug-tool-A_SRangeController.html
nextPage: asenvironment.html
---

`A_SNavigationController` and `A_STabBarController` both implement the `A_SVisibility` protocol. These classes can be used even without `A_SDisplayNodes`, making them suitable base classes for your inheritance hierarchy. For any child view controllers that are <a href="containers-asviewcontroller.html">`A_SViewControllers`</a>, these classes know the exact number of user taps it would take to make the view controller visible (0 if currently visible).

Knowing a view controller’s visibility depth allows view controllers to automatically take appropriate actions as a user approaches or leaves them. Non-default tabs in an app might preload some of their data; a controller 3 levels deep in a navigation stack might progressively free memory for images, text, and fetched data as it gets deeper. 

Any container view controller can implement a simple protocol to integrate with the system. For example, `A_SNavigationController` will return a visibility depth of it's own `visibilityDepth` + 1 for a view controller that would be revealed by tapping the back button once.

You can opt into some of this behavior automatically by enabling `automaticallyAdjustRangeModeBasedOnViewEvents` on `A_SViewController`s. With this enabled, if either the view controller or its node conform to `A_SRangeControllerUpdateRangeProtocol` (`A_SCollectionNode` and `A_STableNode` do by default), the ranges will automatically be decreased as the visibility depth increases to save memory.
