---
title: Node Subclasses
layout: docs
permalink: /docs/node-overview.html
prevPage: containers-overview.html
nextPage: subclassing.html
---

Tex_ture offers the following nodes.  

A key advantage of using nodes over UIKit components is that **all nodes preform layout and display off of the main thread**, so that the main thread is available to immediately respond to user interaction events.  

<table style="width:100%" class = "paddingBetweenCols">
  <tr>
    <th>Tex_ture Node</th>
    <th>UIKit Equivalent</th> 
  </tr>
  <tr>
    <td><a href = "display-node.html"><code>A_SDisplayNode</code></a></td>
    <td>in place of UIKit's <code>UIView</code><br> 
        <i>The root Tex_ture node, from which all other nodes inherit.</i></td> 
  </tr>
  <tr>
    <td><a href = "cell-node.html"><code>A_SCellNode</code></a></td>
    <td>in place of UIKit's <code>UITableViewCell</code> & <code>UICollectionViewCell</code><br>
        <i><code>A_SCellNode</code>s are used in <code>A_STableNode</code>, <code>A_SCollectionNode</code> and <code>A_SPagerNode</code>.</i></td> 
  </tr>
  <tr>
    <td><a href = "scroll-node.html"><code>A_SScrollNode</code></a></td>
    <td>in place of UIKit's <code>UIScrollView</code>
        <p><i>This node is useful for creating a customized scrollable region that contains other nodes.</i></p></td> 
  </tr>
  <tr>
    <td><a href = "editable-text-node.html"><code>A_SEditableTextNode</code></a><br>
        <a href = "text-node.html"><code>A_STextNode</code></a></td>
    <td>in place of UIKit's <code>UITextView</code><br>
        in place of UIKit's <code>UILabel</code></td> 
  </tr>
  <tr>
    <td><a href = "image-node.html"><code>A_SImageNode</code></a><br>
        <a href = "network-image-node.html"><code>A_SNetworkImageNode</code></a><br>
        <a href = "multiplex-image-node.html"><code>A_SMultiplexImageNode</code></a></td>
    <td>in place of UIKit's <code>UIImage</code></td> 
  </tr>
  <tr>
    <td><a href = "video-node.html"><code>A_SVideoNode</code></a><br>
        <code>A_SVideoPlayerNode</code></td>
    <td>in place of UIKit's <code>AVPlayerLayer</code><br>
        in place of UIKit's <code>UIMoviePlayer</code></td> 
  </tr>
  <tr>
    <td><a href = "control-node.html"><code>A_SControlNode</code></a></td>
    <td>in place of UIKit's <code>UIControl</code></td>
  </tr>
  <tr>
    <td><a href = "button-node.html"><code>A_SButtonNode</code></a></td>
    <td>in place of UIKit's <code>UIButton</code></td>
  </tr>
  <tr>
    <td><a href = "map-node.html"><code>A_SMapNode</code></a></td>
    <td>in place of UIKit's <code>MKMapView</code></td>
  </tr>
</table>

<br>
Despite having rough equivalencies to UIKit components, in general, Tex_ture nodes offer more advanced features and conveniences. For example, an `A_SNetworkImageNode` does automatic loading and cache management, and even supports progressive jpeg and animated gifs. 

The <a href = "https://github.com/texturegroup/texture/tree/master/examples/Async_DisplayKitOverview">`Async_DisplayKitOverview`</a> example app gives basic implementations of each of the nodes listed above. 
 

# Node Inheritance Hierarchy 

All Tex_ture nodes inherit from `A_SDisplayNode`. 

<img src="/static/images/node-hierarchy.png" alt="node inheritance flowchart">

The nodes highlighted in blue are synchronous wrappers of UIKit elements.  For example, `A_SScrollNode` wraps a `UIScrollView`, and `A_SCollectionNode` wraps a `UICollectionView`.  An `A_SMapNode` in `liveMapMode` is a synchronous wrapper of `UIMapView`.


 
 
