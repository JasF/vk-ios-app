---
title: Layout Engine 
layout: docs
permalink: /docs/layout-engine.html
prevPage: subclassing.html
nextPage: containers-overview.html
---

Tex_ture's layout engine is based on the CSS Box Model.  While it is the feature of the framework that bears the weakest resemblance to the UIKit equivalent (AutoLayout), it is also among the most useful features once you've gotten used to it.  With enough practice, you may just come to prefer creating declarative layouts to the constraint based approach. ;]

The main way you participate in this system is by implementing `-layoutSpecThatFits:` in a node subclass.  Here, you declaratively build up layout specs from the inside out, returning the final spec which will contain the rest.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SStackLayoutSpec *verticalStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.direction          = A_SStackLayoutDirectionVertical;
  verticalStack.spacing            = 4.0;
  [verticalStack setChildren:_commentNodes];

  return verticalStack;
}
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(constrainedSize: A_SSizeRange) {
  let verticalStack = A_SStackLayoutSpec()
  verticalStack.direction = .Vertical
  verticalStack.spacing   = 4.0
  verticalStack.setChildren(_commentNodes)

  return verticalStack
}
  </pre>
</div>
</div>

Whle this example is extremely simple, it gives you an idea of how to use a layout spec.  A stack layout spec, for instance, defines a layout of nodes in which the chlidren will be laid out adjacently, in the direction specified, with the spacing specified.  It is very similar to `UIStackView` but with the added benefit of backwards compatibility.

### A_SLayoutable

Layout spec's children can be any object whose class conforms to the `<A_SLayoutable>` protocol.  All nodes, as well as all layout specs conform to the `<A_SLayoutable>` protocol.  This means that your layout can be built up in composable chunks until you have what you want.

Say you wanted to add 8 pts of padding to the stack you've already set up:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">

  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SStackLayoutSpec *verticalStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.direction          = A_SStackLayoutDirectionVertical;
  verticalStack.spacing            = 4.0;
  [verticalStack setChildren:_commentNodes];
  
  UIEdgeInsets insets = UIEdgeInsetsMake(8, 8, 8, 8);
  A_SInsetLayoutSpec *insetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets 
                                      child:verticalStack];
  
  return insetSpec;
}
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(constrainedSize: A_SSizeRange) {
  let verticalStack = A_SStackLayoutSpec()
  verticalStack.direction = .Vertical
  verticalStack.spacing   = 4.0
  verticalStack.setChildren(_commentNodes)

  let insets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
  let insetSpec = A_SInsetLayoutSpec(insets: insets, child: verticalStack)

  return insetSpec
}
  </pre>
</div>
</div>

You can easily do that by making that stack the child of an inset layout spec.

Naturally, using layout specs takes a bit of practice so to learn more, check out the <a href = "automatic-layout-basics.html">layout section</a>.
