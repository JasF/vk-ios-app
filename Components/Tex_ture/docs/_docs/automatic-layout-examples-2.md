---
title: Layout Examples
layout: docs
permalink: /docs/automatic-layout-examples-2.html
prevPage: layout2-quickstart.html
nextPage: layout2-layoutspec-types.html
---

Check out the layout specs <a href="https://github.com/texturegroup/texture/tree/master/examples/LayoutSpecExamples">example project</a> to play around with the code below. 

## Simple Header with Left and Right Justified Text

<img src="/static/images/layout-examples-simple-header-with-left-right-justified-text.png">

To create this layout, we will use a:

- a vertical `A_SStackLayoutSpec`
- a horizontal `A_SStackLayoutSpec`
- `A_SInsetLayoutSpec` to inset the entire header

The diagram below shows the composition of the layout elements (nodes + layout specs). 

<img src="/static/images/layout-examples-simple-header-with-left-right-justified-text-diagram.png">

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  // when the username / location text is too long, 
  // shrink the stack to fit onscreen rather than push content to the right, offscreen
  A_SStackLayoutSpec *nameLocationStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  nameLocationStack.style.flexShrink = 1.0;
  nameLocationStack.style.flexGrow = 1.0;
  
  // if fetching post location data from server, 
  // check if it is available yet and include it if so
  if (_postLocationNode.attributedText) {
    nameLocationStack.children = @[_usernameNode, _postLocationNode];
  } else {
    nameLocationStack.children = @[_usernameNode];
  }
  
  // horizontal stack
  A_SStackLayoutSpec *headerStackSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                               spacing:40
                                                                        justifyContent:A_SStackLayoutJustifyContentStart
                                                                            alignItems:A_SStackLayoutAlignItemsCenter
                                                                              children:@[nameLocationStack, _postTimeNode]];
  
  // inset the horizontal stack
  return [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(0, 10, 0, 10) child:headerStackSpec];
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
  let nameLocationStack = A_SStackLayoutSpec.vertical()
  nameLocationStack.style.flexShrink = 1.0
  nameLocationStack.style.flexGrow = 1.0

  if postLocationNode.attributedText != nil {
    nameLocationStack.children = [userNameNode, postLocationNode]
  } else {
    nameLocationStack.children = [userNameNode]
  }

  let headerStackSpec = A_SStackLayoutSpec(direction: .horizontal,
                                          spacing: 40,
                                          justifyContent: .start,
                                          alignItems: .center,
                                          children: [nameLocationStack, postTimeNode])

  return A_SInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10), child: headerStackSpec)
}
  </pre>
</div>
</div>

Rotate the example project from portrait to landscape to see how the spacer grows and shrinks.

## Photo with Inset Text Overlay

<img src="/static/images/layout-examples-photo-with-inset-text-overlay.png">

To create this layout, we will use a:

- `A_SInsetLayoutSpec` to inset the text
- `A_SOverlayLayoutSpec` to overlay the inset text spec on top of the photo

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _photoNode.style.preferredSize = CGSizeMake(USER_IMAGE_HEIGHT*2, USER_IMAGE_HEIGHT*2);

  // INIFINITY is used to make the inset unbounded
  UIEdgeInsets insets = UIEdgeInsetsMake(INFINITY, 12, 12, 12);
  A_SInsetLayoutSpec *textInsetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:_titleNode];
  
  return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:_photoNode overlay:textInsetSpec];
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
  let photoDimension: CGFloat = constrainedSize.max.width / 4.0
  photoNode.style.preferredSize = CGSize(width: photoDimension, height: photoDimension)

  // INFINITY is used to make the inset unbounded
  let insets = UIEdgeInsets(top: CGFloat.infinity, left: 12, bottom: 12, right: 12)
  let textInsetSpec = A_SInsetLayoutSpec(insets: insets, child: titleNode)

  return A_SOverlayLayoutSpec(child: photoNode, overlay: textInsetSpec)
}
  </pre>
</div>
</div>

## Photo with Outset Icon Overlay

<img src="/static/images/layout-examples-photo-with-outset-icon-overlay.png">

To create this layout, we will use a:

- `A_SAbsoluteLayoutSpec` to place the photo and icon which have been individually sized and positioned using their `A_SLayoutable` properties

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _iconNode.style.preferredSize = CGSizeMake(40, 40);
  _iconNode.style.layoutPosition = CGPointMake(150, 0);
  
  _photoNode.style.preferredSize = CGSizeMake(150, 150);
  _photoNode.style.layoutPosition = CGPointMake(40 / 2.0, 40 / 2.0);
  
  return [A_SAbsoluteLayoutSpec absoluteLayoutSpecWithSizing:A_SAbsoluteLayoutSpecSizingSizeToFit
                                                   children:@[_photoNode, _iconNode]];
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
  iconNode.style.preferredSize = CGSize(width: 40, height: 40);
  iconNode.style.layoutPosition = CGPoint(x: 150, y: 0);

  photoNode.style.preferredSize = CGSize(width: 150, height: 150);
  photoNode.style.layoutPosition = CGPoint(x: 40 / 2.0, y: 40 / 2.0);

  let absoluteSpec = A_SAbsoluteLayoutSpec(children: [photoNode, iconNode])

  // A_SAbsoluteLayoutSpec's .sizing property recreates the behavior of Tex_ture Layout API 1.0's "A_SStaticLayoutSpec"
  absoluteSpec.sizing = .sizeToFit

  return absoluteSpec;
}
  </pre>
</div>
</div>



## Simple Inset Text Cell

<img src="/static/images/layout-examples-simple-inset-text-cell.png" width="40%">

To recreate the layout of a <i>single cell</i> as is used in Pinterest's search view above, we will use a:

- `A_SInsetLayoutSpec` to inset the text
- `A_SCenterLayoutSpec` to center the text according to the specified properties

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 12, 4, 4);
    A_SInsetLayoutSpec *inset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets
                                                                      child:_titleNode];

    return [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringY
                                                      sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumX
                                                              child:inset];
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
    let insets = UIEdgeInsets(top: 0, left: 12, bottom: 4, right: 4)
    let inset = A_SInsetLayoutSpec(insets: insets, child: _titleNode)
        
    return A_SCenterLayoutSpec(centeringOptions: .Y, sizingOptions: .minimumX, child: inset)
}
  </pre>
</div>
</div>

## Top and Bottom Separator Lines

<img src="/static/images/layout-examples-top-bottom-separator-line.png">

To create the layout above, we will use a:

- a `A_SInsetLayoutSpec` to inset the text
- a vertical `A_SStackLayoutSpec` to stack the two separator lines on the top and bottom of the text

The diagram below shows the composition of the layoutables (layout specs + nodes). 

<img src="/static/images/layout-examples-top-bottom-separator-line-diagram.png">

The following code can also be found in the `A_SLayoutSpecPlayground` [example project]().

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  _topSeparator.style.flexGrow = 1.0;
  _bottomSeparator.style.flexGrow = 1.0;

  A_SInsetLayoutSpec *insetContentSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(20, 20, 20, 20) child:_textNode];

  return [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical
                                                 spacing:0
                                          justifyContent:A_SStackLayoutJustifyContentCenter
                                              alignItems:A_SStackLayoutAlignItemsStretch
                                                children:@[_topSeparator, insetContentSpec, _bottomSeparator]];
}
  </pre>
  <pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
  topSeparator.style.flexGrow = 1.0
  bottomSeparator.style.flexGrow = 1.0
  textNode.style.alignSelf = .center

  let verticalStackSpec = A_SStackLayoutSpec.vertical()
  verticalStackSpec.spacing = 20
  verticalStackSpec.justifyContent = .center
  verticalStackSpec.children = [topSeparator, textNode, bottomSeparator]

  return A_SInsetLayoutSpec(insets:UIEdgeInsets(top: 60, left: 0, bottom: 60, right: 0), child: verticalStackSpec)
}
  </pre>
</div>
</div>
