---
title: Layout API Sizing
layout: docs
permalink: /docs/layout-api-sizing.html
prevPage: layout-api-debugging.html
nextPage: layout-transition-api.html
---

The easiest way to understand the compound dimension types in the Layout API is to see all the units in relation to one another.

<img src="/static/images/layout-api-sizing-1.png">

## Values  (CGFloat, A_SRelativeDimension)
<br>
`A_SRelativeDimension` is essentially a normal **CGFloat with support for representing either a point value, or a % value**.  It allows the same API to take in both fixed values, as well as relative ones.  

A_SRelativeDimension is used to set the `flexBasis` property on a child of an `A_SStackLayoutSpec`.  The flexBasis property specifies the initial size in the stack dimension for this object, where the stack dimension is whether it is a horizontal or vertical stack.  

When a relative (%) value is used, it is resolved against the size of the parent.  For example, an item with 50% flexBasis will ultimately have a point value set on it at the time that the stack achieves a concrete size.

<div class = "note">
Note that .flexBasis can be set on any &ltA_SLayoutable&gt (a node, or a layout spec), but will only take effect if that element is added as a child of a <i>stack</i> layout spec. This container-dependence of layoutable properties is a key area we’re working on clarifying.
</div>

#### Constructing A_SRelativeDimensions
<br>
`A_SDimension.h` contains 3 convenience functions to construct an `A_SRelativeDimension`.  It is easiest to use function that corresponds to the type (top 2 functions).

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
A_SRelativeDimensionMakeWithPoints(CGFloat points);
A_SRelativeDimensionMakeWithPercent(CGFloat percent);
A_SRelativeDimensionMake(A_SRelativeDimensionType type, CGFloat value);
</pre>
<pre lang="swift" class = "swiftCode hidden">
public func A_SDimensionMake(_ points: CGFloat) -> A_SDimension
public func A_SDimensionMakeWithFraction(_ fraction: CGFloat) -> A_SDimension
public func A_SDimensionMake(_ unit: A_SDimensionUnit, _ value: CGFloat)
</pre>
</div>
</div>

#### A_SRelativeDimension Example
<br>
`PIPlaceSingleDetailNode` uses flexBasis to set 2 child nodes of a horizontal stack to share the width 40 / 60:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
leftSideStack.flexBasis = A_SRelativeDimensionMakeWithPercent(0.4f);
self.detailLabel.flexBasis  = A_SRelativeDimensionMakeWithPercent(0.6f);
[horizontalStack setChildren:@[leftSideStack, self.detailLabel]];
</pre>
<pre lang="swift" class = "swiftCode hidden">
leftSideStack.style.flexBasis = A_SDimensionMake("40%")
detailsLabel.style.flexBasis = A_SDimensionMake("60%")
horizontalStack.children = [leftSideStack, detailsLabel]
</pre>
</div>
</div>

<img src="/static/images/flexbasis.png" width="40%" height="40%">

## Sizes (CGSize,  A_SRelativeSize)
<br>
`A_SRelativeSize` is **similar to a CGSize, but its width and height may represent either a point or percent value.**  In fact, their unit type may even be different from one another. `A_SRelativeSize` doesn't have a direct use in the Layout API, except to construct an `A_SRelativeSizeRange`.

- an `A_SRelativeSize` consists of a `.width` and `.height` that are each `A_SRelativeDimensions`. 

- the type of the width and height are independent; either one individually, or both, may be a point or percent value. (e.g. you could specify that an A_SRelativeSize that has a height in points, but a variable % width)

#### Constructing A_SRelativeSizes
<br>
`A_SRelativeSize.h` contains 2 convenience functions to construct an `A_SRelativeSize`.  **If you don't need to support relative (%) values, you can construct an `A_SRelativeSize` with just a CGSize.**

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
A_SRelativeSizeMake(A_SRelativeDimension width, A_SRelativeDimension height);
A_SRelativeSizeMakeWithCGSize(CGSize size);
</pre>
<pre lang="swift" class = "swiftCode hidden">
A_SLayoutSize(width: A_SDimension, height: A_SDimension)
// A_SRelativeSizeMakeWithCGSize deprecated in swift
</pre>
</div>
</div>

## Size Ranges (A_SSizeRange, A_SRelativeSizeRange)

Because the layout spec system allows flexibility with elements growing and shrinking, we sometimes need to provide limits / boundaries to its flexibility.

There are two size range types, but in essence, both contain a minimum and maximum size and that are used to influence the result of layout measurements.

In the Pinterest code base, the **minimum size seems to be only necessary for stack specs in order to determine how much space to fill in between the children.**  For example, with buttons in a nav bar, we don’t want them to stack as closely together as they can fit — rather a minimum width, as wide as the screen, is specified and causes the stack to add spacing to satisfy that constraint.

**It’s much more common that the “max” constraint is what matters, though.**  This is the case when text is wrapping or truncating - it’s encountering the maximum allowed width.  Setting a minimum width for text doesn’t actually do anything—the text can’t be made longer—unless it’s in a stack, and spacing is added around it.

#### A_SSizeRange
<br>
UIKit doesn't provide a structure to bundle a minimum and maximum CGSize.  So `A_SSizeRange` was created to support **a minimum and maximum CGSize pair**. 

The `constrainedSize` that is passed as an input to `layoutSpecThatFits:` is an `A_SSizeRange`. 

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize;
</pre>
<pre lang="swift" class = "swiftCode hidden">
open func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
</pre>
</div>
</div>

#### A_SRelativeSizeRange
<br>
`A_SRelativeSizeRange` is essentially **a minimum and maximum size pair, that are used to constrain the size of a layout object.**  The minimum and maximum sizes must **support both point and relative sizes**, which is where our friend the A_SRelativeSize comes in.  Hence, an A_SRelativeSizeRange consists of a minimum and maximum `A_SRelativeSize`. 

A_SRelativeSizeRange is used to set the `sizeRange` property on a child of an `A_SStaticLayoutSpec`.  If specified, the child's size is restricted according to this size.  

<div class = "note">
Note that .sizeRange can be set on any &ltA_SLayoutable&gt (a node, or a layout spec), but will only take effect if that element is added as a child of a <i>static</i> layout spec. This container-dependence of layoutable properties is a key area we’re working on clarifying.
</div>

#### A_SSizeRange vs. A_SRelativeSizeRange
<br>
Why do we pass a `A_SSizeRange *constrainedSize` to a node's `layoutSpecThatFits:` function, but a `A_SRelativeSizeRange` for the `.sizeRange` property on an element provided as a child of a layout spec?

 It’s pretty rare that you need the percent feature for a .sizeRange feature, but it’s there to make the API as flexible as possible. The input value of the constrainedSize that comes into the argument, has already been resolved by the parent’s size. It may have been influenced by a percent type, but has always be converted by that point into points. 

#### Constructing A_SRelativeSizeRange
<br>
`A_SRelativeSize.h` contains 4 convenience functions to construct an `A_SRelativeSizeRange` from the various smaller units.  

- Percentage and point values can be combined. E.g. you could specify that an object is a certain height in points, but a variable percentage width. 

- If you only care to constrain the min / max or width / height, you can pass in `CGFLOAT_MIN`, `CGFLOAT_MAX`, `constrainedSize.max.width`, etc

Most of the time, relative values are not needed for a size range _and_ the design requires an object to be forced to a particular size (min size = max size = no range). In this common case, you can use:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
A_SRelativeSizeRangeMakeWithExactCGSize(CGSize exact);
</pre>
<pre lang="swift" class = "swiftCode hidden">
public func A_SSizeRangeMake(_ exactSize: CGSize) -> A_SSizeRange
</pre>
</div>
</div>

### Sizing Conclusion
<br>
Here we have our original table, which has been annotated to show the uses of the various units in the Layout API.

<img src="/static/images/layout-api-sizing-2.png">

It’s worth noting that that there’s a certain flexibility to be able to use so many powerful options with a single API - flexBasis and sizeRange can be used to set points and percentages in different directions. However, since the majority of do not use the full set of options, we should adjust the API so that the powerful capabilities are a slightly more hidden.

