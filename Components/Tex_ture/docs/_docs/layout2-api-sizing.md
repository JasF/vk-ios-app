---
title: Layout API Sizing
layout: docs
permalink: /docs/layout2-api-sizing.html
nextPage: layout-transition-api.html
---

The easiest way to understand the compound dimension types in the Layout API is to see all the units in relation to one another.

<img src="/static/images/layout2-api-sizing.png">

## Values (`CGFloat`, `A_SDimension`)
<br>
`A_SDimension` is essentially a **normal CGFloat with support for representing either a point value, a relative percentage value, or an auto value**.  

This unit allows the same API to take in both fixed values, as well as relative ones.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
<b>// dimension returned is relative (%)</b>
A_SDimensionMake(@"50%");  
A_SDimensionMakeWithFraction(0.5);

<b>// dimension returned in points</b>
A_SDimensionMake(@"70pt");
A_SDimensionMake(70);      
A_SDimensionMakeWithPoints(70);
</pre>
<pre lang="swift" class = "swiftCode hidden">
<b>// dimension returned is relative (%)</b>
A_SDimensionMake("50%")
A_SDimensionMakeWithFraction(0.5)

<b>// dimension returned in points</b>
A_SDimensionMake("70pt")
A_SDimensionMake(70)
A_SDimensionMakeWithPoints(70)
</pre>

### Example using `A_SDimension`

`A_SDimension` is used to set the `flexBasis` property on a child of an `A_SStackLayoutSpec`.  The `flexBasis` property specifies an object's initial size in the stack dimension, where the stack dimension is whether it is a horizontal or vertical stack.

In the following view, we want the left stack to occupy `40%` of the horizontal width and the right stack to occupy `60%` of the width. 

<img src="/static/images/flexbasis.png" width="40%" height="40%">

We do this by setting the `.flexBasis` property on the two childen of the horizontal stack:

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
self.leftStack.style.flexBasis = A_SDimensionMake(@"40%");
self.rightStack.style.flexBasis = A_SDimensionMake(@"60%");

[horizontalStack setChildren:@[self.leftStack, self.rightStack]];
</pre>
<pre lang="swift" class = "swiftCode hidden">
self.leftStack.style.flexBasis = A_SDimensionMake("40%")
self.rightStack.style.flexBasis = A_SDimensionMake("60%")

horizontalStack.children = [self.leftStack, self.rightStack]]
</pre>

## Sizes (`CGSize`, `A_SLayoutSize`)

`A_SLayoutSize` is similar to a `CGSize`, but its **width and height values may represent either a point or percent value**. The type of the width and height are independent; either one may be a point or percent value.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
A_SLayoutSizeMake(A_SDimension width, A_SDimension height);
</pre>
<pre lang="swift" class = "swiftCode hidden">
A_SLayoutSizeMake(_ width: A_SDimension, _ height: A_SDimension)
</pre>
</div>
</div>

<br>
`A_SLayoutSize` is used for setting a layout element's `.preferredLayoutSize`, `.minLayoutSize` and `.maxLayoutSize` properties. It allows the same API to take in both fixed sizes, as well as relative ones.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
// Dimension type "Auto" indicates that the layout element may 
// be resolved in whatever way makes most sense given the circumstances
A_SDimension width = A_SDimensionMake(A_SDimensionUnitAuto, 0);  
A_SDimension height = A_SDimensionMake(@"50%");

layoutElement.style.preferredLayoutSize = A_SLayoutSizeMake(width, height);
</pre>
<pre lang="swift" class = "swiftCode hidden">
// Dimension type "Auto" indicates that the layout element may 
// be resolved in whatever way makes most sense given the circumstances
let width = A_SDimensionMake(.auto, 0)
let height = A_SDimensionMake("50%")
        
layoutElement.style.preferredLayoutSize = A_SLayoutSizeMake(width, height)
</pre>
</div>
</div>

<br>
If you do not need relative values, you can set the layout element's `.preferredSize`, `.minSize` and `.maxSize` properties. The properties take regular `CGSize` values. 

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
layoutElement.style.preferredSize = CGSizeMake(30, 160);
</pre>
<pre lang="swift" class = "swiftCode hidden">
layoutElement.style.preferredSize = CGSize(width: 30, height: 60)
</pre>
</div>
</div>

<br>
Most of the time, you won't want to constrain both width and height. In these cases, you can individually set a layout element's size properties using `A_SDimension` values.

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
layoutElement.style.width     = A_SDimensionMake(@"50%");
layoutElement.style.minWidth  = A_SDimensionMake(@"50%");
layoutElement.style.maxWidth  = A_SDimensionMake(@"50%");

layoutElement.style.height    = A_SDimensionMake(@"50%");
layoutElement.style.minHeight = A_SDimensionMake(@"50%");
layoutElement.style.maxHeight = A_SDimensionMake(@"50%");
</pre>
<pre lang="swift" class = "swiftCode hidden">
layoutElement.style.width     = A_SDimensionMake("50%")
layoutElement.style.minWidth  = A_SDimensionMake("50%")
layoutElement.style.maxWidth  = A_SDimensionMake("50%")

layoutElement.style.height    = A_SDimensionMake("50%")
layoutElement.style.minHeight = A_SDimensionMake("50%")
layoutElement.style.maxHeight = A_SDimensionMake("50%")
</pre>
</div>
</div>

## Size Range (`A_SSizeRange`)

`UIKit` doesn't provide a structure to bundle a minimum and maximum `CGSize`. So, `A_SSizeRange` was created to support **a minimum and maximum CGSize pair**. 

`A_SSizeRange` is used mostly in the internals of the layout API. However, the `constrainedSize` value passed as an input to `layoutSpecThatFits:` is an `A_SSizeRange`.  
   
<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize;
</pre>
<pre lang="swift" class = "swiftCode hidden">
func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec
</pre>
</div>
</div>

<br>
The `constrainedSize` passed to an `A_SDisplayNode` subclass' `layoutSpecThatFits:` method is the minimum and maximum sizes that the node should fit in. The minimum and maximum `CGSize`s contained in `constrainedSize` can be used to size the node's layout elements.
