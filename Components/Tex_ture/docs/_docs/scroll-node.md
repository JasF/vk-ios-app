---
title: A_SScrollNode
layout: docs
permalink: /docs/scroll-node.html
prevPage: control-node.html
nextPage: editable-text-node.html
---

`A_SScrollNode` is an `A_SDisplayNode` whose underlying view is an `UIScrollView`. This class offers the ability to automatically adopt its `A_SLayoutSpec`'s size as the scrollable `contentSize`. 

### automaticallyManagesContentSize

When enabled, the size calculated by the `A_SScrolNode`'s layout spec defines the `.contentSize` of the scroll view. This is in contrast to most nodes, where the `layoutSpec` size is applied to the bounds (and in turn, frame). In this mode, the bounds of the scroll view always fills the parent's size. 

`automaticallyManagesContentSize` is useful both for subclasses of `A_SScrollNode` implementing `layoutSpecThatFits:` or may also be used as the base class with `.layoutSpecBlock` set. In both cases, it is common use `.automaticallyManagesSubnodes` so that the nodes in the layout spec are added to the scrollable area automatically. 

With this approach there is no need to capture the layout size, use an absolute layout spec as a wrapper, or set `contentSize` anywhere in the code and it will update as the layout changes! Instead, it is very common and useful to simply return an `A_SStackLayoutSpec` and the scrollable area will allow you to see all of it. 

### scrollableDirections 

This option is useful when using `automaticallyManagesContentSize`, <b>especially if you want horizontal content (because the default is vertical)</b>.

This property controls how the `constrainedSize` is interpreted when sizing the content. Options include:

<table style="width:100%" class = "paddingBetweenCols">
  <tr>
    <td><b>Vertical</b></td>
    <td>The `constrainedSize` is interpreted as having unbounded `.height` (`CGFLOAT_MAX`), allowing stacks and other content in the layout spec to expand and result in scrollable content.</td> 
  </tr>
  <tr>
    <td><b>Horizontal</b></td>
    <td>The `constrainedSize` is interpreted as having unbounded `.width` (`CGFLOAT_MAX`).</td> 
  </tr>
  <tr>
    <td><b>Vertical & Horizontal</b></td>
    <td>The `constrainedSize` is interpreted as unbounded in both directions.</td>
  </tr>
</table>

### Example

In case you're not familiar with scroll views, they are basically windows into content that would take up more space than can fit in that area.

Say you have a giant image, but you only want to take up 200x200 pts on the screen.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// NOTE: If you are using a horizontal stack, set scrollNode.scrollableDirections.
A_SScrollNode *scrollNode = [[A_SScrollNode alloc] init];
scrollNode.automaticallyManagesSubnodes = YES;
scrollNode.automaticallyManagesContentSize = YES;

scrollNode.layoutSpecBlock = ^(A_SDisplayNode *node, A_SSizeRange constrainedSize){
  A_SStackLayoutSpec *stack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  // Add children to the stack.
  return stack;
};

</pre>
<pre lang="swift" class = "swiftCode hidden">
// NOTE: If you are using a horizontal stack, set scrollNode.scrollableDirections.

let scrollNode = A_SScrollNode()
scrollNode.automaticallyManagesSubnodes = true
scrollNode.automaticallyManagesContentSize = true

scrollNode.layoutSpecBlock = { node, constrainedSize in
  let stack = A_SStackLayoutSpec.vertical()
  // Add children to the stack.
  return stack
}

</pre>
</div>
</div>
