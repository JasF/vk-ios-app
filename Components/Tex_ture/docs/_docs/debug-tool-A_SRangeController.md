---
title: Range Visualization
layout: docs
permalink: /docs/debug-tool-A_SRangeController.html
prevPage: debug-tool-pixel-scaling.html
nextPage: asvisibility.html
---

## Visualize A_SRangeController tuning parameters <a href="https://github.com/facebook/Async_DisplayKit/pull/1390">(PR #1390)</a> 
<br>
This debug feature adds a semi-transparent subview in the bottom right hand corner of the sharedApplication keyWindow that visualizes the A_SRangeTuningParameters per each A_SLayoutRangeType for each visible (on-screen) instance of A_SRangeController. 

- The instances of A_SRangeController are represented as bars
- As you scroll around within A_STable/CollectionViews you can see the parameters (green = Visible, yellow = Display, and red = FetchData) move relative to each other. 
- White arrows on the L and R sides of the individual RangeController bar views indicate the scrolling direction so that you can determine the leading / trailing tuning parameters (especially useful for vertically-oriented rangeControllers whose leading edge might be unclear within the horizontally-oriented bar view). 
- The white debug label above the RangeController bar displays the RangeController dataSource’s class name to differentiate between nested views.
- The overlay can be moved with a panning gesture in order to see content under it.

This debug feature is useful for highly optimized Tex_ture apps that require tuning of any A_SRangeController. Or for anyone who is curious about how A_SRangeControllers work. 

The <a href="https://github.com/texturegroup/texture/tree/master/examples/VerticalWithinHorizontalScrolling">VerticalWithinHorizontal example app</a> contains an A_SPagerNode with embedded A_STableViews. In the screenshot with this feature enabled, you can see the two range controllers - A_STableView and A_SCollectionView (A_SPagerNode) - in the overlay. 

- The white arrows to the right of the rangeController bars indicate that the user is currently scrolling down through the table and right through the A_SCollectionView/PagerNode. 
- The A_STableView rangeController bar indicates that the range parameters are tuned to both fetch and decode more data in the downward table direction rather than in the reverse direction (which makes sense as the user is scrolling down). 
- Since it’s less obvious whether or not the user will page to the right or left next, the A_SCollectionView is tuned to fetch and decode equal amounts of data in each direction. 
- In the <a href="https://drive.google.com/file/d/0B1BArZ05bNhzVy1jSW9FeEVXUjg/view">video demo</a>, you can see as the user scrolls between pages, that new A_STableView rangeControllers are created and removed in the overlay view. 
![bc0b98f0-ebb8-11e5-8f50-421cb0f320c2](https://cloud.githubusercontent.com/assets/3419380/14057072/ef7f63a0-f2b2-11e5-92a5-f65b2d207e63.png)

## Limitations
<ul>
  <li>only shows onscreen A_SRangeControllers</li>
  <li>currently the ratio of red (fetch data), yellow (display) and green (visible) are relative to each other, but not between each bar view. So you cannot compare individual bars to eachother</li>
</ul>

## Usage
In your `AppDelegate.m` file, 
<ul>
  <li>import <code>Async_DisplayKit+Debug.h</code></li>
  <li>add <code>[A_SDisplayNode setShouldShowRangeDebugOverlay:YES]</code> at the top of your AppDelegate's <code>didFinishLaunchingWithOptions:</code> method</li>
</ul>

**Make sure to call this method before initializing any component that uses an A_SRangeControllers (A_STableView, A_SCollectionView).**
