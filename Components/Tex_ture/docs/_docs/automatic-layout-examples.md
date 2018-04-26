---
title: Layout Examples
layout: docs
permalink: /docs/automatic-layout-examples.html
prevPage: automatic-layout-containers.html
nextPage: automatic-layout-debugging.html
---

Three examples in increasing order of complexity. 
#NSSpain Talk Example

<img src="/static/images/layout-example-1.png">

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constraint
{
  A_SStackLayoutSpec *vStack = [[A_SStackLayoutSpec alloc] init];
  
  [vStack setChildren:@[titleNode, bodyNode];

  A_SStackLayoutSpec *hstack = [[A_SStackLayoutSpec alloc] init];
  hStack.direction          = A_SStackLayoutDirectionHorizontal;
  hStack.spacing            = 5.0;

  [hStack setChildren:@[imageNode, vStack]];
  
  A_SInsetLayoutSpec *insetSpec = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5,5,5,5) child:hStack];

  return insetSpec;
}
</pre>
<pre lang="swift" class = "swiftCode hidden">

</pre>
</div>
</div>

###Discussion

#Social App Layout

<img src="/static/images/layout-example-2.png">

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{
  // header stack
  _userAvatarImageView.preferredFrameSize = CGSizeMake(USER_IMAGE_HEIGHT, USER_IMAGE_HEIGHT);  // constrain avatar image frame size
  
  A_SLayoutSpec *spacer = [[A_SLayoutSpec alloc] init];
  spacer.flexGrow      = YES;

  A_SStackLayoutSpec *headerStack = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  headerStack.alignItems         = A_SStackLayoutAlignItemsCenter;       // center items vertically in horizontal stack
  headerStack.justifyContent     = A_SStackLayoutJustifyContentStart;    // justify content to left side of header stack
  headerStack.spacing            = HORIZONTAL_BUFFER;

  [headerStack setChildren:@[_userAvatarImageView, _userNameLabel, spacer, _photoTimeIntervalSincePostLabel]];
  
  // header inset stack
  
  UIEdgeInsets insets                = UIEdgeInsetsMake(0, HORIZONTAL_BUFFER, 0, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *headerWithInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:headerStack];
  headerWithInset.flexShrink = YES;
  
  // vertical stack
  
  CGFloat cellWidth                  = constrainedSize.max.width;
  _photoImageView.preferredFrameSize = CGSizeMake(cellWidth, cellWidth);  // constrain photo frame size
  
  A_SStackLayoutSpec *verticalStack   = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.alignItems           = A_SStackLayoutAlignItemsStretch;    // stretch headerStack to fill horizontal space
  
  [verticalStack setChildren:@[headerWithInset, _photoImageView, footerWithInset]];

  return verticalStack;
}
</pre>
<pre lang="swift" class = "swiftCode hidden">

</pre>
</div>
</div>

###Discussion

Get the full Tex_ture project at examples/A_SDKgram.

#Social App Layout 2

<img src="/static/images/layout-example-3.png">

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize {

  A_SLayoutSpec *textSpec  = [self textSpec];
  A_SLayoutSpec *imageSpec = [self imageSpecWithSize:constrainedSize];
  A_SOverlayLayoutSpec *soldOutOverImage = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:imageSpec 
                                                                                  overlay:[self soldOutLabelSpec]];
  
  NSArray *stackChildren = @[soldOutOverImage, textSpec];
  
  A_SStackLayoutSpec *mainStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical 
                                                                         spacing:0.0
                                                                  justifyContent:A_SStackLayoutJustifyContentStart
                                                                      alignItems:A_SStackLayoutAlignItemsStretch          
                                                                        children:stackChildren];
  
  A_SOverlayLayoutSpec *soldOutOverlay = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:mainStack 
                                                                                overlay:self.soldOutOverlay];
  
  return soldOutOverlay;
}

- (A_SLayoutSpec *)textSpec {
  CGFloat kInsetHorizontal        = 16.0;
  CGFloat kInsetTop               = 6.0;
  CGFloat kInsetBottom            = 0.0;
  UIEdgeInsets textInsets         = UIEdgeInsetsMake(kInsetTop, kInsetHorizontal, kInsetBottom, kInsetHorizontal);
  
  A_SLayoutSpec *verticalSpacer    = [[A_SLayoutSpec alloc] init];
  verticalSpacer.flexGrow         = YES;
  
  A_SLayoutSpec *horizontalSpacer1 = [[A_SLayoutSpec alloc] init];
  horizontalSpacer1.flexGrow      = YES;
  
  A_SLayoutSpec *horizontalSpacer2 = [[A_SLayoutSpec alloc] init];
  horizontalSpacer2.flexGrow      = YES;
  
  NSArray *info1Children = @[self.firstInfoLabel, self.distanceLabel, horizontalSpacer1, self.originalPriceLabel];
  NSArray *info2Children = @[self.secondInfoLabel, horizontalSpacer2, self.finalPriceLabel];
  if ([ItemNode isRTL]) {
    info1Children = [[info1Children reverseObjectEnumerator] allObjects];
    info2Children = [[info2Children reverseObjectEnumerator] allObjects];
  }
  
  A_SStackLayoutSpec *info1Stack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal 
                                                                          spacing:1.0
                                                                   justifyContent:A_SStackLayoutJustifyContentStart 
                                                                       alignItems:A_SStackLayoutAlignItemsBaselineLast children:info1Children];
  
  A_SStackLayoutSpec *info2Stack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal 
                                                                          spacing:0.0
                                                                   justifyContent:A_SStackLayoutJustifyContentCenter 
                                                                       alignItems:A_SStackLayoutAlignItemsBaselineLast children:info2Children];
  
  A_SStackLayoutSpec *textStack = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionVertical 
                                                                         spacing:0.0
                                                                  justifyContent:A_SStackLayoutJustifyContentEnd
                                                                      alignItems:A_SStackLayoutAlignItemsStretch
                                                                        children:@[self.titleLabel, verticalSpacer, info1Stack, info2Stack]];
  
  A_SInsetLayoutSpec *textWrapper = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:textInsets 
                                                                          child:textStack];
  textWrapper.flexGrow = YES;
  
  return textWrapper;
}

- (A_SLayoutSpec *)imageSpecWithSize:(A_SSizeRange)constrainedSize {
  CGFloat imageRatio = [self imageRatioFromSize:constrainedSize.max];
  
  A_SRatioLayoutSpec *imagePlace = [A_SRatioLayoutSpec ratioLayoutSpecWithRatio:imageRatio child:self.dealImageView];
  
  self.badge.layoutPosition = CGPointMake(0, constrainedSize.max.height - kFixedLabelsAreaHeight - kBadgeHeight);
  self.badge.sizeRange = A_SRelativeSizeRangeMake(A_SRelativeSizeMake(A_SRelativeDimensionMakeWithPercent(0), A_SRelativeDimensionMakeWithPoints(kBadgeHeight)), A_SRelativeSizeMake(A_SRelativeDimensionMakeWithPercent(1), A_SRelativeDimensionMakeWithPoints(kBadgeHeight)));
  A_SStaticLayoutSpec *badgePosition = [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[self.badge]];
  
  A_SOverlayLayoutSpec *badgeOverImage = [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:imagePlace overlay:badgePosition];
  badgeOverImage.flexGrow = YES;
  
  return badgeOverImage;
}

- (A_SLayoutSpec *)soldOutLabelSpec {
  A_SCenterLayoutSpec *centerSoldOutLabel = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY 
  sizingOptions:A_SCenterLayoutSpecSizingOptionMinimumXY child:self.soldOutLabelFlat];
  A_SStaticLayoutSpec *soldOutBG = [A_SStaticLayoutSpec staticLayoutSpecWithChildren:@[self.soldOutLabelBackground]];
  A_SCenterLayoutSpec *centerSoldOut = [A_SCenterLayoutSpec centerLayoutSpecWithCenteringOptions:A_SCenterLayoutSpecCenteringXY   sizingOptions:A_SCenterLayoutSpecSizingOptionDefault child:soldOutBG];
  A_SBackgroundLayoutSpec *soldOutLabelOverBackground = [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:centerSoldOutLabel background:centerSoldOut];
  return soldOutLabelOverBackground;
}
</pre>
<pre lang="swift" class = "swiftCode hidden">

</pre>
</div>
</div>

###Discussion

Get the full Tex_ture project at examples/CatDealsCollectionView.
