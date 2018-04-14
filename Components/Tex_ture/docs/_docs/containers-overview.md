---
title: Node Containers
layout: docs
permalink: /docs/containers-overview.html
prevPage: intelligent-preloading.html
nextPage: node-overview.html
---

### Use Nodes in Node Containers
It is highly recommended that you use Tex_ture's nodes within a node container. Tex_ture offers the following node containers.

<table style="width:100%" class = "paddingBetweenCols">
  <tr>
    <th>Tex_ture Node Container</th>
    <th>UIKit Equivalent</th> 
  </tr>
  <tr>
    <td><a href = "containers-ascollectionnode.html">`A_SCollectionNode`</a></td>
    <td>in place of UIKit's `UICollectionView`</td>
  </tr>
  <tr>
    <td><a href = "containers-aspagernode.html">`A_SPagerNode`</a></td>
    <td>in place of UIKit's `UIPageViewController`</td>
  </tr>
  <tr>
    <td><a href = "containers-astablenode.html">`A_STableNode`</a></td>
    <td>in place of UIKit's `UITableView`</td>
  </tr>
  <tr>
    <td><a href = "containers-asviewcontroller.html">`A_SViewController`</a></td>
    <td>in place of UIKit's `UIViewController`</td>
  </tr>
  <tr>
    <td>`A_SNavigationController`</td>
    <td>in place of UIKit's `UINavigationController`. Implements the <a href = "asvisibility.html">`A_SVisibility`</a> protocol.</td>
  </tr>
  <tr>
    <td>`A_STabBarController`</td>
    <td>in place of UIKit's `UITabBarController`. Implements the <a href = "asvisibility.html">`A_SVisibility`</a> protocol.</td>
  </tr>
</table>

<br>
Example code and specific sample projects are highlighted in the documentation for each node container. 

<!-- For a detailed description on porting an existing UIKit app to Tex_ture, read the <a href = "porting-guide.html">porting guide</a>. -->

### What do I Gain by Using a Node Container?

A node container automatically manages the <a href = "intelligent-preloading.html">intelligent preloading</a> of its nodes. This means that all of the node's layout measurement, data fetching, decoding and rendering will be done asynchronously. Among other conveniences, this is why it is recommended to use nodes within a container node.

Note that while it _is_ possible to use nodes directly (without an Tex_ture node container), unless you add additional calls, they will only start displaying once they come onscreen (as UIKit does). This can lead to performance degredation and flashing of content.
