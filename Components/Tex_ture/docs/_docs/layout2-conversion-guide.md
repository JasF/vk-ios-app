---
title: Upgrading to Layout 2.0 <b><i>(Beta)</i></b>
layout: docs
permalink: /docs/layout2-conversion-guide.html
---

A list of the changes:

- Introduction of true flex factors
- `A_SStackLayoutSpec` `.alignItems` property default changed to `A_SStackLayoutAlignItemsStretch`
- Rename `A_SStaticLayoutSpec` to `A_SAbsoluteLayoutSpec`
- Rename `A_SLayoutable` to `A_SLayoutElement`
- Set `A_SLayoutElement` properties via `style` property
- Easier way to size of an `A_SLayoutElement`
- Deprecation of `-[A_SDisplayNode preferredFrameSize]`
- Deprecation of `-[A_SLayoutElement measureWithSizeRange:]`
- Deprecation of `-[A_SDisplayNode measure:]`
- Removal of `-[A_SAbsoluteLayoutElement sizeRange]`
- Rename `A_SRelativeDimension` to `A_SDimension`
- Introduction of `A_SDimensionUnitAuto`
 
In addition to the inline examples comparing **1.x** layout code vs **2.0** layout code, the [example projects](https://github.com/texturegroup/texture/tree/master/examples) and <a href = "layout2-quickstart.html">layout documentation</a> have been updated to use the new API.

All other **2.0** changes not related to the Layout API are documented <a href="adoption-guide-2-0-beta1.html">here</a>. 

## Introduction of true flex factors

With **1.x** the `flexGrow` and `flexShrink` properties were of type `BOOL`. 

With **2.0**, these properties are now type `CGFloat` with default values of `0.0`. 

This behavior is consistent with the Flexbox implementation for web. See [`flexGrow`](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-grow) and [`flexShrink`](https://developer.mozilla.org/en-US/docs/Web/CSS/flex-shrink) for further information.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
id&lt;A_SLayoutElement&gt; layoutElement = ...;

// 1.x:
layoutElement.flexGrow = YES;
layoutElement.flexShrink = YES;

// 2.0:
layoutElement.style.flexGrow = 1.0;
layoutElement.style.flexShrink = 1.0;
</pre>

<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

## `A_SStackLayoutSpec`'s `.alignItems` property default changed 

`A_SStackLayoutSpec`'s `.alignItems` property default changed to `A_SStackLayoutAlignItemsStretch` instead of `A_SStackLayoutAlignItemsStart` to align with the CSS align-items property.

## Rename `A_SStaticLayoutSpec` to `A_SAbsoluteLayoutSpec` & behavior change

`A_SStaticLayoutSpec` has been renamed to `A_SAbsoluteLayoutSpec`, to be consistent with web terminology and better represent the intended behavior.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x:
A_SStaticLayoutSpec *layoutSpec = [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[...]];

// 2.0:
A_SAbsoluteLayoutSpec *layoutSpec = [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[...]];
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

<br>
**Please note** that there has also been a behavior change introduced. The following text overlay layout was previously created using a `A_SStaticLayoutSpec`, `A_SInsetLayoutSpec` and `A_SOverlayLayoutSpec` as seen in the code below. 

<img src="/static/images/layout-examples-photo-with-inset-text-overlay-diagram.png">

<br>
Using `INFINITY` for the `top` value in the `UIEdgeInsets` property of the `A_SInsetLayoutSpec` allowed the text inset to start at the bottom. This was possible because it would adopt the size of the static layout spec's `_photoNode`.  

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _photoNode.preferredFrameSize = CGSizeMake(USER_IMAGE_HEIGHT*2, USER_IMAGE_HEIGHT*2);
  <b>A_SStaticLayoutSpec</b> *backgroundImageStaticSpec = [<b>A_SStaticLayoutSpec</b> staticLayoutSpecWithChildren:@[_photoNode]];

  UIEdgeInsets insets = UIEdgeInsetsMake(INFINITY, 12, 12, 12);
  <b>A_SInsetLayoutSpec</b> *textInsetSpec = [<b>A_SInsetLayoutSpec</b> insetLayoutSpecWithInsets:insets child:_titleNode];

  <b>A_SOverlayLayoutSpec</b> *textOverlaySpec = [<b>A_SOverlayLayoutSpec</b> overlayLayoutSpecWithChild:backgroundImageStaticSpec
                                                                                 overlay:textInsetSpec];
  
  return textOverlaySpec;
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
  </pre>
</div>
</div>

<br>
With the new `A_SAbsoluteLayoutSpec` and same code above, the layout would now look like the picture below. The text is still there, but at ~900 pts (offscreen).

<img src="/static/images/layout-examples-photo-with-inset-text-overlay-diagram.png">

## Rename `A_SLayoutable` to `A_SLayoutElement`

Remember that an `A_SLayoutSpec` contains children that conform to the `A_SLayoutElement` protocol. Both `A_SDisplayNodes` and `A_SLayoutSpecs` conform to this protocol. 

The protocol has remained the same as **1.x**, but the name has been changed to be more descriptive. 

## Set `A_SLayoutElement` properties via `A_SLayoutElementStyle`

An `A_SLayoutElement`'s properties are are now set via it's `A_SLayoutElementStyle` object.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
id&lt;A_SLayoutElement&gt; *layoutElement = ...;

// 1.x:
layoutElement.spacingBefore = 1.0;

// 2.0:
layoutElement.style.spacingBefore = 1.0;
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

However, the properties specific to an `A_SLayoutSpec` are still set directly on the layout spec.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x and 2.0
A_SStackLayoutSpec *stackLayoutSpec = ...;
stackLayoutSpec.direction = A_SStackLayoutDirectionVertical;
stackLayoutSpec.justifyContent = A_SStackLayoutJustifyContentStart;
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

## Setting the size of an `A_SLayoutElement`

With **2.0** we introduce a new, easier, way to set the size of an `A_SLayoutElement`. These methods replace the deprecated `-preferredFrameSize` and `-sizeRange` **1.x** methods.

The following **optional** properties are provided via the layout element's `style` property:

- `-[A_SLayoutElementStyle width]`: specifies the width of an A_SLayoutElement. The `minWidth` and `maxWidth` properties will override `width`. The height will be set to Auto unless provided. 

- `-[A_SLayoutElementStyle minWidth]`: specifies the minimum width of an A_SLayoutElement. This prevents the used value of the `width` property from becoming smaller than the specified for `minWidth`.

- `-[A_SLayoutElementStyle maxWidth]`: specifies the maximum width of an  A_SLayoutElement. It prevents the used value of the `width` property from becoming larger than the specified for `maxWidth`.

- `-[A_SLayoutElementStyle height]`: specifies the height of an A_SLayoutElement. The `minHeight` and `maxHeight` properties will override `height`. The width will be set to Auto unless provided. 

- `-[A_SLayoutElementStyle minHeight]`: specifies the minimum height of an A_SLayoutElement. It prevents the used value of the `height` property from becoming smaller than the specified for `minHeight`.

- `-[A_SLayoutElementStyle maxHeight]`: specifies the maximum height of an A_SLayoutElement. It prevents the used value of the `height` property from becoming larger than the specified for `maxHeight`.

To set both the width and height with a `CGSize` value:

- `-[A_SLayoutElementStyle preferredSize]`: Provides a suggested size for a layout element. If the optional minSize or maxSize are provided, and the preferredSize exceeds these, the minSize or maxSize will be enforced. If this optional value is not provided, the layout element’s size will default to it’s intrinsic content size provided calculateSizeThatFits:

- `-[A_SLayoutElementStyle minSize]`: An optional property that provides a minimum size bound for a layout element. If provided, this restriction will always be enforced. If a parent layout element’s minimum size is smaller than its child’s minimum size, the child’s minimum size will be enforced and its size will extend out of the layout spec’s.

- `-[A_SLayoutElementStyle maxSize]`: An optional property that provides a maximum size bound for a layout element. If provided, this restriction will always be enforced. If a child layout element’s maximum size is smaller than its parent, the child’s maximum size will be enforced and its size will extend out of the layout spec’s.
 
To set both the width and height with a relative (%) value (an `A_SRelativeSize`):

- `-[A_SLayoutElementStyle preferredRelativeSize]`: Provides a suggested RELATIVE size for a layout element. An A_SRelativeSize uses percentages rather than points to specify layout. E.g. width should be 50% of the parent’s width. If the optional minRelativeSize or maxRelativeSize are provided, and the preferredRelativeSize exceeds these, the minRelativeSize or maxRelativeSize will be enforced. If this optional value is not provided, the layout element’s size will default to its intrinsic content size provided calculateSizeThatFits:

- `-[A_SLayoutElementStyle minRelativeSize]`: An optional property that provides a minimum RELATIVE size bound for a layout element. If provided, this restriction will always be enforced. If a parent layout element’s minimum relative size is smaller than its child’s minimum relative size, the child’s minimum relative size will be enforced and its size will extend out of the layout spec’s.

- `-[A_SLayoutElementStyle maxRelativeSize]`: An optional property that provides a maximum RELATIVE size bound for a layout element. If provided, this restriction will always be enforced. If a parent layout element’s maximum relative size is smaller than its child’s maximum relative size, the child’s maximum relative size will be enforced and its size will extend out of the layout spec’s.

For example, if you want to set a `width` of an `A_SDisplayNode`:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x:
// no good way to set an intrinsic size

// 2.0:
A_SDisplayNode *A_SDisplayNode = ...;

// width 100 points, height: auto
displayNode.style.width = A_SDimensionMakeWithPoints(100);

// width 50%, height: auto
displayNode.style.width = A_SDimensionMakeWithFraction(0.5);

A_SLayoutSpec *layoutSpec = ...;

// width 100 points, height 100 points
layoutSpec.style.preferredSize = CGSizeMake(100, 100);
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

If you previously wrapped an `A_SLayoutElement` with an `A_SStaticLayoutSpec` just to give it a specific size (without setting the `layoutPosition` property on the element too), you don't have to do that anymore.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
A_SStackLayoutSpec *stackLayoutSpec = ...;
id&lt;A_SLayoutElement&gt; *layoutElement = ...;

// 1.x:
layoutElement.sizeRange = A_SRelativeSizeRangeMakeWithExactCGSize(CGSizeMake(50, 50));
A_SStaticLayoutSpec *staticLayoutSpec = [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[layoutElement]];
stackLayoutSpec.children = @[staticLayoutSpec];

// 2.0:
layoutElement.style.preferredSizeRange = A_SRelativeSizeRangeMakeWithExactCGSize(CGSizeMake(50, 50));
stackLayoutSpec.children = @[layoutElement];
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

If you previously wrapped a `A_SLayoutElement` within a `A_SStaticLayoutSpec` just to return any layout spec from within `layoutSpecThatFits:` there is a new layout spec now that is called `A_SWrapperLayoutSpec`. `A_SWrapperLayoutSpec` is an `A_SLayoutSpec` subclass that can wrap a `A_SLayoutElement` and calculates the layout of the child based on the size given to the `A_SLayoutElement`:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x - A_SStaticLayoutSpec used as a "wrapper" to return subnode from layoutSpecThatFits: 
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[subnode]];
}

// 2.0
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SWrapperLayoutSpec wrapperWithLayoutElement:subnode];
}

// 1.x - A_SStaticLayoutSpec used to set size (but not position) of subnode
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SDisplayNode *subnode = ...;
  subnode.preferredSize = ...;
  return [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[subnode]];
}

// 2.0
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  A_SDisplayNode *subnode = ...;
  subnode.style.preferredSize = CGSizeMake(constrainedSize.max.width, constrainedSize.max.height / 2.0);
  return [A_SWrapperLayoutSpec wrapperWithLayoutElement:subnode];
}
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

## Deprecation of `-[A_SDisplayNode preferredFrameSize]`

With the introduction of new sizing properties there is no need anymore for the `-[A_SDisplayNode preferredFrameSize]` property. Therefore it is deprecated in **2.0**. Instead, use the size values on the `style` object of an `A_SDisplayNode`:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode"> 
A_SDisplayNode *A_SDisplayNode = ...;

// 1.x:
displayNode.preferredFrameSize = CGSize(100, 100);

// 2.0
displayNode.style.preferredSize = CGSize(100, 100);
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

`-[A_SDisplayNode preferredFrameSize]` was not supported properly and was often more confusing than helpful. The new sizing methods should be easier and more clear to implment.

## Deprecation of `-[A_SLayoutElement measureWithSizeRange:]`

`-[A_SLayoutElement measureWithSizeRange:]` is deprecated in **2.0**.

#### Calling `measureWithSizeRange:`

If you previously called `-[A_SLayoutElement measureWithSizeRange:]` to receive an `A_SLayout`, call `-[A_SLayoutElement layoutThatFits:]` now instead.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x:
A_SLayout *layout = [layoutElement measureWithSizeRange:someSizeRange];

// 2.0:
A_SLayout *layout = [layoutElement layoutThatFits:someSizeRange];
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

#### Implementing `measureWithSizeRange:`

If you are implementing a custom `class` that conforms to `A_SLayoutElement` (e.g. creating a custom `A_SLayoutSpec`) , replace `-measureWithSizeRange:` with `-calculateLayoutThatFits:`

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x:
- (A_SLayout *)measureWithSizeRange:(A_SSizeRange)constrainedSize {}

// 2.0:
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize {}
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

`-calculateLayoutThatFits:` takes an `A_SSizeRange` that specifies a min size and a max size of type `CGSize`. Choose any size in the given range, to calculate the children's size and position and return a `A_SLayout` structure with the layout of child components.

Besides `-calculateLayoutThatFits:` there are two additional methods on `A_SLayoutElement` that you should know about if you are implementing classes that conform to `A_SLayoutElement`:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize;
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

In certain advanced cases, you may want to override this method. Overriding this method allows you to receive the `layoutElement`'s size, parent size, and constrained size. With these values you could calculate the final constrained size and call `-calculateLayoutThatFits:` with the result.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize
                  parentSize:(CGSize)parentSize;
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

Call this on children`layoutElements` to compute their layouts within your implementation of `-calculateLayoutThatFits:`.

For sample implementations of layout specs and the usage of the `calculateLayoutThatFits:` family of methods, check out the layout specs in Tex_ture itself!

## Deprecation of `-[A_SDisplayNode measure:]` 

Use `-[A_SDisplayNode layoutThatFits:]` instead to get an `A_SLayout` and call `size` on the returned `A_SLayout`:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 1.x:
CGSize size = [displayNode measure:CGSizeMake(100, 100)];

// 2.0:
// Creates an A_SSizeRange with min and max sizes.
A_SLayout *layout = [displayNode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))];
// Or an exact size
// A_SLayout *layout = [displayNode layoutThatFits:A_SSizeRangeMake(CGSizeMake(100, 100))];
CGSize size = layout.size;
</pre>
<pre lang="swift" class = "swiftCode hidden">
// 1.x
let size = displayNode.measure(CGSize(width: 100, height: 100))

// 2.0:
// Creates an A_SSizeRange with min and max sizes.
let layout = displayNode.layoutThatFits(A_SSizeRange(min: CGSizeZero, max: CGSize(width: 100, height: 100)))
// Or an exact size
// let layout = displayNode.layoutThatFits(A_SSizeRangeMake(CGSize(width: 100, height: 100)))
let size = layout.size
</pre>
</div>
</div>

## Remove of `-[A_SAbsoluteLayoutElement sizeRange]`

The `sizeRange` property was removed from the `A_SAbsoluteLayoutElement` protocol. Instead set the one of the following:

- `-[A_SLayoutElement width]`
- `-[A_SLayoutElement height]`
- `-[A_SLayoutElement minWidth]`
- `-[A_SLayoutElement minHeight]`
- `-[A_SLayoutElement maxWidth]`
- `-[A_SLayoutElement maxHeight]`
 
<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
id&lt;A_SLayoutElement&gt; layoutElement = ...;

// 1.x:
layoutElement.sizeRange = A_SRelativeSizeRangeMakeWithExactCGSize(CGSizeMake(50, 50));

// 2.0:
layoutElement.style.preferredSizeRange = A_SRelativeSizeRangeMakeWithExactCGSize(CGSizeMake(50, 50));
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

Due to the removal of `-[A_SAbsoluteLayoutElement sizeRange]`, we also removed the `A_SRelativeSizeRange`, as the type was no longer needed.

## Rename `A_SRelativeDimension` to `A_SDimension`

To simplify the naming and support the fact that dimensions are widely used in Tex_ture now, `A_SRelativeDimension` was renamed to `A_SDimension`. Having a shorter name and handy functions to create it was an important goal for us.

`A_SRelativeDimensionTypePercent` and associated functions were renamed to use `Fraction` to be consistent with Apple terminology.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 2.0:
// Handy functions to create A_SDimensions
A_SDimension dimensionInPoints;
dimensionInPoints = A_SDimensionMake(A_SDimensionTypePoints, 5.0)
dimensionInPoints = A_SDimensionMake(5.0)
dimensionInPoints = A_SDimensionMakeWithPoints(5.0)
dimensionInPoints = A_SDimensionMake("5.0pt");

A_SDimension dimensionInFractions;
dimensionInFractions = A_SDimensionMake(A_SDimensionTypeFraction, 0.5)
dimensionInFractions = A_SDimensionMakeWithFraction(0.5)
dimensionInFractions = A_SDimensionMake("50%");
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

## Introduction of `A_SDimensionUnitAuto`

Previously `A_SDimensionUnitPoints` and `A_SDimensionUnitFraction` were the only two `A_SDimensionUnit` enum values available. A new dimension type called `A_SDimensionUnitAuto` now exists. All of the ``A_SLayoutElementStyle` sizing properties are set to `A_SDimensionAuto` by default.

`A_SDimensionUnitAuto` means more or less: *"I have no opinion" and may be resolved in whatever way makes most sense given the circumstances.* 

Most of the time this is the intrinsic content size of the `A_SLayoutElement`.

For example, if an `A_SImageNode` has a `width` set to `A_SDimensionUnitAuto`, the width of the linked image file will be used. For an `A_STextNode` the intrinsic content size will be calculated based on the text content. If an `A_SLayoutElement` cannot provide any intrinsic content size like `A_SVideoNode` for example the size needs to set explicitly.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
// 2.0:
// No specific size needs to be set as the imageNode's size 
// will be calculated from the content (the image in this case)
A_SImageNode *imageNode = [A_SImageNode new];
imageNode.image = ...;

// Specific size must be set for A_SLayoutElement objects that
// do not have an intrinsic content size (A_SVideoNode does not
// have a size until it's video downloads)
A_SVideoNode *videoNode = [A_SVideoNode new];
videoNode.style.preferredSize = CGSizeMake(200, 100);
</pre>
<pre lang="swift" class = "swiftCode hidden">
</pre>
</div>
</div>

