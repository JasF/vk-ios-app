---
title: Quickstart
layout: docs
permalink: /docs/layout2-quickstart.html
prevPage: multiplex-image-node.html
nextPage: automatic-layout-examples-2.html
---

## Motivation & Benefits

The Layout API was created as a performant alternative to UIKit's Auto Layout, which becomes exponentially expensive for complicated view hierarchies. Tex_ture's Layout API has many benefits over using UIKit's Auto Layout:

- **Fast**: As fast as manual layout code and significantly faster than Auto Layout
- **Asynchronous & Concurrent:** Layouts can be computed on background threads so user interactions are not interrupted. 
- **Declarative**: Layouts are declared with immutable data structures. This makes layout code easier to develop, document, code review, test, debug, profile, and maintain. 
- **Cacheable**: Layout results are immutable data structures so they can be precomputed in the background and cached to increase user perceived performance.
- **Extensible**: Easy to share code between classes. 

## Inspired by CSS Flexbox 

Those who are familiar with Flexbox will notice many similarities in the two systems. However, Tex_ture's Layout API <a href = "layout2-web-flexbox-differences.html">does not</a> re-implement all of CSS.

## Basic Concepts

Tex_ture's layout system is centered around two basic concepts: 

1. Layout Specs
2. Layout Elements
<!-- 3. Relative Sizing -->

### Layout Specs 

A layout spec, short for "layout specification", has no physical presence. Instead, layout specs act as containers for other layout elements by understanding how these children layout elements relate to each other.

Tex_ture provides several <a hfref = "layout2-layoutspec-types.html">subclasses</a> of `A_SLayoutSpec`, from a simple layout specification that insets a single child, to a more complex layout specification that arranges multiple children in varying stack configurations.

### Layout Elements 

Layout specs contain and arrange layout elements. 

All `A_SDisplayNode`s and `A_SLayoutSpec`s conform to the `<A_SLayoutElement>` protocol. This means that you can compose layout specs from both nodes and other layout specs. Cool!

The `A_SLayoutElement` protocol has several properties that can be used to create very complex layouts. In addition, layout specs have their own set of properties that can be used to adjust the arrangment of the layout elements. 

### Combine Layout Specs & Layout Elements to Make Complex UI

Here you can see how `A_STextNode`s (highlighted in yellow), an `A_SVideoNode` (top image) and an `A_SStackLayoutSpec` ("stack layout spec") can be combined to create a complex layout. 

<img src="/static/images/layout-spec-relationship-1.png">

The play button on top of the `A_SVideoNode` (top image) is placed using an `A_SCenterLayoutSpec` ("center layout spec") and an `A_SOverlayLayoutSpec` ("overlay layout spec").  

<img src="/static/images/layout-spec-relationship-2.png">

### Some nodes need Sizes Set

<!-- With manual layout, each element gets its position and size set individually. With Tex_ture's Layout API, very -->

Some elements have an "intrinsic size" based on their immediately available content. For example, A_STextNode can calculate its size based on its attributed string. Other nodes that have an intrinsic size include 

- `A_SImageNode`
- `A_STextNode`
- `A_SButtonNode`

All other nodes either do not have an intrinsic size or lack an intrinsic size until their external resource is loaded. For example, an `A_SNetworkImageNode` does not know its size until the image has been downloaded from the URL. These sorts of elements include 

- `A_SVideoNode`
- `A_SVideoPlayerNode`
- `A_SNetworkImageNode`
- `A_SEditableTextNode`

These nodes that lack an initial intrinsic size must have an initial size set for them using an `A_SRatioLayoutSpec`, an `A_SAbsoluteLayoutSpec` or the size properties on the style object. 

### Layout Debugging

Calling `-asciiArtString` on any `A_SDisplayNode` or `A_SLayoutSpec` returns an ascii-art representation of the object and its children. Optionally, if you set the `.debugName` on any node or layout spec, that will also be included in the ascii art. An example is seen below.

<div class = "highlight-group">
<div class = "code">
<pre lang="objc" class="objcCode">
-----------------------A_SStackLayoutSpec----------------------
|  -----A_SStackLayoutSpec-----  -----A_SStackLayoutSpec-----  |
|  |       A_SImageNode       |  |       A_SImageNode       |  |
|  |       A_SImageNode       |  |       A_SImageNode       |  |
|  ---------------------------  ---------------------------  |
--------------------------------------------------------------
</pre>
</div>
</div>

You can also print out the style object on any `A_SLayoutElement` (node or layout spec). This is especially useful when debugging the sizing properties.

<div class = "highlight-group">
<div class = "code">
<pre lang="objc" class="objcCode">
(lldb) po _photoImageNode.style
Layout Size = min {414pt, 414pt} <= preferred {20%, 50%} <= max {414pt, 414pt}
</pre>
</div>
</div>
