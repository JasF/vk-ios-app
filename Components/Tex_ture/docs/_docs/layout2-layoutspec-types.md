---
title: Layout Specs
layout: docs
permalink: /docs/layout2-layoutspec-types.html
prevPage: automatic-layout-examples-2.html
nextPage: layout2-layout-element-properties.html
---

The following `A_SLayoutSpec` subclasses can be used to compose simple or very complex layouts. 

<ul>
<li><a href="layout2-layoutspec-types.html#aswrapperlayoutspec"><code>A_S<b>Wrapper</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asstacklayoutspec-flexbox-container"><code>A_S<b>Stack</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asinsetlayoutspec"><code>A_S<b>Inset</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asoverlaylayoutspec"><code>A_S<b>Overlay</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asbackgroundlayoutspec"><code>A_S<b>Background</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#ascenterlayoutspec"><code>A_S<b>Center</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asratiolayoutspec"><code>A_S<b>Ratio</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asrelativelayoutspec"><code>A_S<b>Relative</b>LayoutSpec</code></a></li>
<li><a href="layout2-layoutspec-types.html#asabsolutelayoutspec"><code>A_S<b>Absolute</b>LayoutSpec</code></a></li>
</ul>

You may also subclass <a href="layout2-layoutspec-types.html#aslayoutspec">`A_SLayoutSpec`</a> in order to make your own, custom layout specs. 

## A_SWrapperLayoutSpec

`A_SWrapperLayoutSpec` is a simple `A_SLayoutSpec` subclass that can wrap a `A_SLayoutElement` and calculate the layout of the child based on the size set on the layout element. 

`A_SWrapperLayoutSpec` is ideal for easily returning a single subnode from `-layoutSpecThatFits:`. Optionally, this subnode can have sizing information set on it. However, if you need to set a position in addition to a size, use `A_SAbsoluteLayoutSpec` instead.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
// return a single subnode from layoutSpecThatFits: 
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SWrapperLayoutSpec wrapperWithLayoutElement:_subnode];
}

// set a size (but not position)
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _subnode.style.preferredSize = CGSizeMake(constrainedSize.max.width,
                                            constrainedSize.max.height / 2.0);
  return [A_SWrapperLayoutSpec wrapperWithLayoutElement:subnode];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
// return a single subnode from layoutSpecThatFits:
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec 
{
  return A_SWrapperLayoutSpec(layoutElement: _subnode)
}

// set a size (but not position)
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec 
{
  _subnode.style.preferredSize = CGSize(width: constrainedSize.max.width,
                                        height: constrainedSize.max.height / 2.0)
  return A_SWrapperLayoutSpec(layoutElement: _subnode)
}
</pre>
</div>
</div>

## A_SStackLayoutSpec (Flexbox Container)
Of all the layoutSpecs in Tex_ture, `A_SStackLayoutSpec` is the most useful and powerful. `A_SStackLayoutSpec` uses the flexbox algorithm to determine the position and size of its children. Flexbox is designed to provide a consistent layout on different screen sizes. In a stack layout you align items in either a vertical or horizontal stack. A stack layout can be a child of another stack layout, which makes it possible to create almost any layout using a stack layout spec. 

`A_SStackLayoutSpec` has 7 properties in addition to its `<A_SLayoutElement>` properties:

- `direction`. Specifies the direction children are stacked in. If horizontalAlignment and verticalAlignment were set, 
they will be resolved again, causing justifyContent and alignItems to be updated accordingly.
- `spacing`. The amount of space between each child.
- `horizontalAlignment`. Specifies how children are aligned horizontally. Depends on the stack direction, setting the alignment causes either
 justifyContent or alignItems to be updated. The alignment will remain valid after future direction changes.
 Thus, it is preferred to those properties.
- `verticalAlignment`. Specifies how children are aligned vertically. Depends on the stack direction, setting the alignment causes either
 justifyContent or alignItems to be updated. The alignment will remain valid after future direction changes.
 Thus, it is preferred to those properties.
- `justifyContent`. The amount of space between each child.
- `alignItems`. Orientation of children along cross axis.
- `flexWrap`. Whether children are stacked into a single or multiple lines. Defaults to single line.
- `alignContent`. Orientation of lines along cross axis if there are multiple lines.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SStackLayoutSpec *mainStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                       spacing:6.0
                justifyContent:A_SStackLayoutJustifyContentStart
                    alignItems:A_SStackLayoutAlignItemsCenter
                      children:@[_iconNode, _countNode]];

  // Set some constrained size to the stack
  mainStack.style.minWidth = A_SDimensionMakeWithPoints(60.0);
  mainStack.style.maxHeight = A_SDimensionMakeWithPoints(40.0);

  return mainStack;
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec 
{
  let mainStack = A_SStackLayoutSpec(direction: .horizontal,
                                    spacing: 6.0,
                                    justifyContent: .start,
                                    alignItems: .center,
                                    children: [titleNode, subtitleNode])

  // Set some constrained size to the stack
  mainStack.style.minWidth = A_SDimensionMakeWithPoints(60.0)
  mainStack.style.maxHeight = A_SDimensionMakeWithPoints(40.0)

  return mainStack
}
</pre>
</div>
</div>

Flexbox works the same way in Tex_ture as it does in CSS on the web, with a few exceptions. For example, the defaults are different and there is no `flex` parameter. See <a href = "layout2-web-flexbox-differences.html">Web Flexbox Differences</a> for more information.

<br>

## A_SInsetLayoutSpec
During the layout pass, the `A_SInsetLayoutSpec` passes its `constrainedSize.max` `CGSize` to its child, after subtracting its insets. Once the child determines it's final size, the inset spec passes its final size up as the size of its child plus its inset margin. Since the inset layout spec is sized based on the size of it's child, the child **must** have an instrinsic size or explicitly set its size. 

<img src="/static/images/layoutSpec-types/A_SInsetLayoutSpec-diagram.png" width="75%">

If you set `INFINITY` as a value in the `UIEdgeInsets`, the inset spec will just use the intrinisic size of the child. See an <a href="automatic-layout-examples-2.html#photo-with-inset-text-overlay">example</a> of this.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  ...
  UIEdgeInsets *insets = UIEdgeInsetsMake(10, 10, 10, 10);
  A_SInsetLayoutSpec *headerWithInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:textNode];
  ...
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  ...
  let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
  let headerWithInset = A_SInsetLayoutSpec(insets: insets, child: textNode)
  ...
}
</pre>
</div>
</div>

## A_SOverlayLayoutSpec
`A_SOverlayLayoutSpec` lays out its child (blue), stretching another component on top of it as an overlay (red). 

<img src="/static/images/layoutSpec-types/A_SOverlayLayouSpec-diagram.png" width="65%">

The overlay spec's size is calculated from the child's size. In the diagram below, the child is the blue layer. The child's size is then passed as the `constrainedSize` to the overlay layout element (red layer). Thus, it is important that the child (blue layer) **must** have an intrinsic size or a size set on it. 

<div class = "note">
When using Automatic Subnode Management with the <code>A_SOverlayLayoutSpec</code>, the nodes may sometimes appear in the wrong order. This is a known issue that will be fixed soon. The current workaround is to add the nodes manually, with the overlay layout element (red) must added as a subnode to the parent node after the child layout element (blue).
</div>

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor blueColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:backgroundNode overlay:foregroundNode];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  let backgroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.blue)
  let foregroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.red)
  return A_SOverlayLayoutSpec(child: backgroundNode, overlay: foregroundNode)
}
</pre>
</div>
</div>

## A_SBackgroundLayoutSpec
`A_SBackgroundLayoutSpec` lays out a component (blue), stretching another component behind it as a backdrop (red). 

<img src="/static/images/layoutSpec-types/A_SBackgroundLayoutSpec-diagram.png" width="65%">

The background spec's size is calculated from the child's size. In the diagram below, the child is the blue layer. The child's size is then passed as the `constrainedSize` to the background layout element (red layer). Thus, it is important that the child (blue layer) **must** have an intrinsic size or a size set on it. 

<div class = "note">
When using Automatic Subnode Management with the <code>A_SOverlayLayoutSpec</code>, the nodes may sometimes appear in the wrong order. This is a known issue that will be fixed soon. The current workaround is to add the nodes manually, with the child layout element (blue) must added as a subnode to the parent node after the child background element (red).
</div>

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor blueColor]);

  return [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:foregroundNode background:backgroundNode];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  let backgroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.red)
  let foregroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.blue)

  return A_SBackgroundLayoutSpec(child: foregroundNode, background: backgroundNode)
}
</pre>
</div>
</div>

Note: The order in which subnodes are added matters for this layout spec; the background object must be added as a subnode to the parent node before the foreground object. Using A_SM does not currently guarantee this order!

## A_SCenterLayoutSpec
`A_SCenterLayoutSpec` centers its child within its max `constrainedSize`. 

<img src="/static/images/layoutSpec-types/A_SCenterLayoutSpec-diagram.png" width="65%">

If the center spec's width or height is unconstrained, it shrinks to the size of the child.

`A_SCenterLayoutSpec` has two properties:

- `centeringOptions`. Determines how the child is centered within the center spec. Options include: None, X, Y, XY.
- `sizingOptions`. Determines how much space the center spec will take up. Options include: Default, minimum X, minimum Y, minimum XY.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SStaticSizeDisplayNode *subnode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], CGSizeMake(70, 100));
  return [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY
                                                    sizingOptions:A_SCenterLayoutSpecSizingOptionDefault
                                                            child:subnode]
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  let subnode = A_SDisplayNodeWithBackgroundColor(UIColor.green, CGSize(width: 60.0, height: 100.0))
  let centerSpec = A_SCenterLayoutSpec(centeringOptions: .XY, sizingOptions: [], child: subnode)
  return centerSpec
}
</pre>
</div>
</div>

## A_SRatioLayoutSpec
`A_SRatioLayoutSpec` lays out a component at a fixed aspect ratio which can scale. This spec **must** have a width or a height passed to it as a constrainedSize as it uses this value to scale itself. 

<img src="/static/images/layoutSpec-types/A_SRatioLayoutSpec-diagram.png" width="65%">

It is very common to use a ratio spec to provide an intrinsic size for `A_SNetworkImageNode` or `A_SVideoNode`, as both do not have an intrinsic size until the content returns from the server. 

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  // Half Ratio
  A_SStaticSizeDisplayNode *subnode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], CGSizeMake(100, 100));
  return [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:0.5 child:subnode];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  // Half Ratio
  let subnode = A_SDisplayNodeWithBackgroundColor(UIColor.green, CGSize(width: 100, height: 100.0))
  let ratioSpec = A_SRatioLayoutSpec(ratio: 0.5, child: subnode)
  return ratioSpec
}
</pre>
</div>
</div>

## A_SRelativeLayoutSpec
Lays out a component and positions it within the layout bounds according to vertical and horizontal positional specifiers. Similar to the “9-part” image areas, a child can be positioned at any of the 4 corners, or the middle of any of the 4 edges, as well as the center.

This is a very powerful class, but too complex to cover in this overview. For more information, look into `A_SRelativeLayoutSpec`'s `-calculateLayoutThatFits:` method + properties.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  ...
  A_SDisplayNode *backgroundNode = A_SDisplayNodeWithBackgroundColor([UIColor redColor]);
  A_SStaticSizeDisplayNode *foregroundNode = A_SDisplayNodeWithBackgroundColor([UIColor greenColor], CGSizeMake(70, 100));

  A_SRelativeLayoutSpec *relativeSpec = [A_SRelativeLayoutSpec relativePositionLayoutSpecWithHorizontalPosition:A_SRelativeLayoutSpecPositionStart
                                  verticalPosition:A_SRelativeLayoutSpecPositionStart
                                      sizingOption:A_SRelativeLayoutSpecSizingOptionDefault
                                             child:foregroundNode]

  A_SBackgroundLayoutSpec *backgroundSpec = [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:relativeSpec background:backgroundNode];
  ...
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  ...
  let backgroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.blue)
  let foregroundNode = A_SDisplayNodeWithBackgroundColor(UIColor.red, CGSize(width: 70.0, height: 100.0))

  let relativeSpec = A_SRelativeLayoutSpec(horizontalPosition: .start,
                                          verticalPosition: .start,
                                          sizingOption: [],
                                          child: foregroundNode)

  let backgroundSpec = A_SBackgroundLayoutSpec(child: relativeSpec, background: backgroundNode)
  ...
}
</pre>
</div>
</div>

## A_SAbsoluteLayoutSpec
Within `A_SAbsoluteLayoutSpec` you can specify exact locations (x/y coordinates) of its children by setting their `layoutPosition` property. Absolute layouts are less flexible and harder to maintain than other types of layouts.

`A_SAbsoluteLayoutSpec` has one property:

- `sizing`. Determines how much space the absolute spec will take up. Options include: Default, and Size to Fit. *Note* that the Size to Fit option will replicate the behavior of the old `A_SStaticLayoutSpec`.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  CGSize maxConstrainedSize = constrainedSize.max;

  // Layout all nodes absolute in a static layout spec
  guitarVideoNode.layoutPosition = CGPointMake(0, 0);
  guitarVideoNode.size = A_SSizeMakeFromCGSize(CGSizeMake(maxConstrainedSize.width, maxConstrainedSize.height / 3.0));

  nicCageVideoNode.layoutPosition = CGPointMake(maxConstrainedSize.width / 2.0, maxConstrainedSize.height / 3.0);
  nicCageVideoNode.size = A_SSizeMakeFromCGSize(CGSizeMake(maxConstrainedSize.width / 2.0, maxConstrainedSize.height / 3.0));

  simonVideoNode.layoutPosition = CGPointMake(0.0, maxConstrainedSize.height - (maxConstrainedSize.height / 3.0));
  simonVideoNode.size = A_SSizeMakeFromCGSize(CGSizeMake(maxConstrainedSize.width/2, maxConstrainedSize.height / 3.0));

  hlsVideoNode.layoutPosition = CGPointMake(0.0, maxConstrainedSize.height / 3.0);
  hlsVideoNode.size = A_SSizeMakeFromCGSize(CGSizeMake(maxConstrainedSize.width / 2.0, maxConstrainedSize.height / 3.0));

  return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[guitarVideoNode, nicCageVideoNode, simonVideoNode, hlsVideoNode]];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  let maxConstrainedSize = constrainedSize.max

  // Layout all nodes absolute in a static layout spec
  guitarVideoNode.style.layoutPosition = CGPoint.zero
  guitarVideoNode.style.preferredSize = CGSize(width: maxConstrainedSize.width, height: maxConstrainedSize.height / 3.0)

  nicCageVideoNode.style.layoutPosition = CGPoint(x: maxConstrainedSize.width / 2.0, y: maxConstrainedSize.height / 3.0)
  nicCageVideoNode.style.preferredSize = CGSize(width: maxConstrainedSize.width / 2.0, height: maxConstrainedSize.height / 3.0)

  simonVideoNode.style.layoutPosition = CGPoint(x: 0.0, y: maxConstrainedSize.height - (maxConstrainedSize.height / 3.0))
  simonVideoNode.style.preferredSize = CGSize(width: maxConstrainedSize.width / 2.0, height: maxConstrainedSize.height / 3.0)

  hlsVideoNode.style.layoutPosition = CGPoint(x: 0.0, y: maxConstrainedSize.height / 3.0)
  hlsVideoNode.style.preferredSize = CGSize(width: maxConstrainedSize.width / 2.0, height: maxConstrainedSize.height / 3.0)

  return A_SAbsoluteLayoutSpec(children: [guitarVideoNode, nicCageVideoNode, simonVideoNode, hlsVideoNode])
}
</pre>
</div>
</div>

## A_SLayoutSpec
`A_SLayoutSpec` is the main class from that all layout spec's are subclassed. It's main job is to handle all the children management, but it also can be used to create custom layout specs. Only the super advanced should want / need to create a custom subclasses of `A_SLayoutSpec` though. Instead try to use provided layout specs and compose them together to create more advanced layouts.

Another use of `A_SLayoutSpec` is to be used as a spacer in a `A_SStackLayoutSpec` with other children, when `.flexGrow` and/or `.flexShrink` is applied.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  ...
  // A_SLayoutSpec as spacer
  A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
  spacer.style.flexGrow = true;

  stack.children = @[imageNode, spacer, textNode];
  ...
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
{
  ...
  let spacer = A_SLayoutSpec()
  spacer.style.flexGrow = 1.0

  stack.children = [imageNode, spacer, textNode]
  ...
}
</pre>
</div>
</div>
