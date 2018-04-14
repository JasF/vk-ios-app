---
title: Automatic Subnode Management
layout: docs
permalink: /docs/automatic-subnode-mgmt.html
prevPage: batch-fetching-api.html
nextPage: inversion.html
---

Enabling Automatic Subnode Management (A_SM) is required to use the <a href="layout-transition-api.html">Layout Transition API</a>. However, apps that don't require animations can still benefit from the reduction in code size that this feature enables.

When enabled, A_SM means that your nodes no longer require `addSubnode:` or `removeFromSupernode` method calls. The presence or absence of the A_SM node _and_ its subnodes is completely determined in its `layoutSpecThatFits:` method.

### Example ###
<br>
Consider the following intialization method from the PhotoCellNode class in <a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram sample app</a>. This <code>A_SCellNode</code> subclass produces a simple social media photo feed cell. 

In the "Original Code" we see the familiar `addSubnode:` calls in bold. In the "Code with A_SM" these have been removed and replaced with a single line that enables A_SM. 

By setting `.automaticallyManagesSubnodes` to `YES` on the `A_SCellNode`, we _no longer_ need to call `addSubnode:` for each of the `A_SCellNode`'s subnodes. These `subNodes` will be present in the node hierarchy as long as this class' `layoutSpecThatFits:` method includes them. 


<i>Original code</i>
<div class="highlight-group">
<span class="language-toggle">
  <a data-lang="objective-c" class="active objcButton">Objective-C</a>
  <a data-lang="swift" class="swiftButton">Swift</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (instancetype)initWithPhotoObject:(PhotoModel *)photo;
{
  self = [super init];
  
  if (self) {
    _photoModel = photo;
    
    _userAvatarImageNode = [[A_SNetworkImageNode alloc] init];
    _userAvatarImageNode.URL = photo.ownerUserProfile.userPicURL;
    <b>[self addSubnode:_userAvatarImageNode];</b>

    _photoImageNode = [[A_SNetworkImageNode alloc] init];
    _photoImageNode.URL = photo.URL;
    <b>[self addSubnode:_photoImageNode];</b>

    _userNameTextNode = [[A_STextNode alloc] init];
    _userNameTextNode.attributedString = [photo.ownerUserProfile usernameAttributedStringWithFontSize:FONT_SIZE];
    <b>[self addSubnode:_userNameTextNode];</b>
    
    _photoLocationTextNode = [[A_STextNode alloc] init];
    [photo.location reverseGeocodedLocationWithCompletionBlock:^(LocationModel *locationModel) {
      if (locationModel == _photoModel.location) {
        _photoLocationTextNode.attributedString = [photo locationAttributedStringWithFontSize:FONT_SIZE];
        [self setNeedsLayout];
      }
    }];
    <b>[self addSubnode:_photoLocationTextNode];</b>
  }
  
  return self;
}
</pre>
<pre lang="swift" class="swiftCode hidden">
class PhotoCellNode {
  private let photoModel: PhotoModel
  
  private let userAvatarImageNode = A_SNetworkImageNode()
  private let photoImageNode = A_SNetworkImageNode()
  private let userNameTextNode = A_STextNode()
  private let photoLocationTextNode = A_STextNode()

  init(photo: PhotoModel) {
    photoModel = photo
    
    super.init()
    
    userAvatarImageNode.URL = photo.ownerUserProfile.userPicURL
    <b>addSubnode(userAvatarImageNode)</b>
    
    photoImageNode.URL = photo.URL
    <b>addSubnode(photoImageNode)</b>
    
    userNameTextNode.attributedText = poto.ownerUserProfile.usernameAttributedString(fontSize: fontSize)
    <b>addSubnode(userNameTextNode)</b>
    
    photo.location.reverseGeocodeLocation { [weak self] location in 
      if locationModel == self?.photoModel.location {
        self?.photoLocationTextNode.attributedText = photo.locationAttributedString(fontSize: fontSize)
        self?.setNeedsLayout()
      }
    }
    <b>addSubnode(photoLocationTextNode)</b>
  }
}
</pre>
</div>
</div>

<i>Code with A_SM</i>
<div class="highlight-group">
<span class="language-toggle">
  <a data-lang="objective-c" class="active objcButton">Objective-C</a>
  <a data-lang="swift" class="swiftButton">Swift</a>
</span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (instancetype)initWithPhotoObject:(PhotoModel *)photo;
{
  self = [super init];
  
  if (self) {
    <b>self.automaticallyManagesSubnodes = YES;</b>
    
    _photoModel = photo;
    
    _userAvatarImageNode = [[A_SNetworkImageNode alloc] init];
    _userAvatarImageNode.URL = photo.ownerUserProfile.userPicURL;

    _photoImageNode = [[A_SNetworkImageNode alloc] init];
    _photoImageNode.URL = photo.URL;

    _userNameTextNode = [[A_STextNode alloc] init];
    _userNameTextNode.attributedString = [photo.ownerUserProfile usernameAttributedStringWithFontSize:FONT_SIZE];
    
    _photoLocationTextNode = [[A_STextNode alloc] init];
    [photo.location reverseGeocodedLocationWithCompletionBlock:^(LocationModel *locationModel) {
      if (locationModel == _photoModel.location) {
        _photoLocationTextNode.attributedString = [photo locationAttributedStringWithFontSize:FONT_SIZE];
        [self setNeedsLayout];
      }
    }];
  }
  
  return self;
}
</pre>
<pre lang="swift" class="swiftCode hidden">
class PhotoCellNode {
  private let photoModel: PhotoModel
  
  private let userAvatarImageNode = A_SNetworkImageNode()
  private let photoImageNode = A_SNetworkImageNode()
  private let userNameTextNode = A_STextNode()
  private let photoLocationTextNode = A_STextNode()

  init(photo: PhotoModel) {
    photoModel = photo
    
    super.init()
    
    <b>automaticallyManagesSubnodes = true</b>
    
    userAvatarImageNode.URL = photo.ownerUserProfile.userPicURL
    
    photoImageNode.URL = photo.URL
    
    userNameTextNode.attributedText = poto.ownerUserProfile.usernameAttributedString(fontSize: fontSize)
    
    photo.location.reverseGeocodeLocation { [weak self] location in 
      if locationModel == self?.photoModel.location {
        self?.photoLocationTextNode.attributedText = photo.locationAttributedString(fontSize: fontSize)
        self?.setNeedsLayout()
      }
    }
  }
}
</pre>
</div>
</div>

Several of the elements in this cell - `_userAvatarImageNode`, `_photoImageNode`, and `_photoLocationLabel` depend on seperate data fetches from the network that could return at any time. When should they be added to the UI?

A_SM knows whether or not to include these elements in the UI based on the information provided in the cell's `A_SLayoutSpec`.

<div class = "note">
An <code>A_SLayoutSpec</code> completely describes the UI of a view in your app by specifying the hierarchy state of a node and its subnodes. An <code>A_SLayoutSpec</code> is returned by a node from its <code>layoutSpecThatFits:</code> method. 
</div> 

**It is your job to construct a `layoutSpecThatFits:` that handles how the UI should look with and without these elements.**

Consider the abreviated `layoutSpecThatFits:` method for the `A_SCellNode` subclass above.

<div class = "highlight-group">
<span class="language-toggle">
<a data-lang="objective-c" class="active objcButton">Objective-C</a>
<a data-lang="swift" class="swiftButton">Swift</a>
</span>

<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constrainedSize
{  
  A_SStackLayoutSpec *headerSubStack = [A_SStackLayoutSpec verticalStackLayoutSpec];
  headerSubStack.flexShrink         = YES;
  <b>if (_photoLocationLabel.attributedString) {</b>
    [headerSubStack setChildren:@[_userNameLabel, _photoLocationLabel]];
  <b>} else {</b>
    [headerSubStack setChildren:@[_userNameLabel]];
  <b>}</b>
  
  _userAvatarImageNode.preferredFrameSize = CGSizeMake(USER_IMAGE_HEIGHT, USER_IMAGE_HEIGHT);     // constrain avatar image frame size

  A_SLayoutSpec *spacer           = [[A_SLayoutSpec alloc] init]; 
  spacer.flexGrow                = YES;
  
  UIEdgeInsets avatarInsets      = UIEdgeInsetsMake(HORIZONTAL_BUFFER, 0, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *avatarInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:avatarInsets child:<b>_userAvatarImageNode</b>];

  A_SStackLayoutSpec *headerStack = [A_SStackLayoutSpec horizontalStackLayoutSpec];
  headerStack.alignItems         = A_SStackLayoutAlignItemsCenter;                     // center items vertically in horizontal stack
  headerStack.justifyContent     = A_SStackLayoutJustifyContentStart;                  // justify content to the left side of the header stack
  [headerStack setChildren:@[avatarInset, headerSubStack, spacer]];
  
  // header inset stack
  UIEdgeInsets insets                = UIEdgeInsetsMake(0, HORIZONTAL_BUFFER, 0, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *headerWithInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:insets child:headerStack];
  
  // footer inset stack
  UIEdgeInsets footerInsets          = UIEdgeInsetsMake(VERTICAL_BUFFER, HORIZONTAL_BUFFER, VERTICAL_BUFFER, HORIZONTAL_BUFFER);
  A_SInsetLayoutSpec *footerWithInset = [A_SInsetLayoutSpec insetLayoutSpecWithInsets:footerInsets child:<b>_photoCommentsNode</b>];
  
  // vertical stack
  CGFloat cellWidth                  = constrainedSize.max.width;
  _photoImageNode.preferredFrameSize = CGSizeMake(cellWidth, cellWidth);              // constrain photo frame size
  
  A_SStackLayoutSpec *verticalStack   = [A_SStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.alignItems           = A_SStackLayoutAlignItemsStretch;                // stretch headerStack to fill horizontal space
  [verticalStack setChildren:@[headerWithInset, <b>_photoImageNode</b>, footerWithInset]];

  return verticalStack;
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func layoutSpecThatFits(_ constrainedSize: A_SSizeRange) -> A_SLayoutSpec {
  let headerSubStack: A_SStackLayoutSpec = .vertical()
  headerSubStack.style.flexShrink = 1

  <b>if photoLocationLabel.attributedText != nil {</b>
    headerSubStack.children = [userNameLabel, photoLocationLabel]
  <b>} else {</b>
    headerSubStack.children = [userNameLabel]
  <b>}</b>

  userAvatarImageNode.style.preferredSize = CGSize(width: userImageHeight, height: userImageHeight) //  constrain avatar image frame size

  let spacer = A_SLayoutSpec()
  spacer.style.flexGrow = 1

  let avatarInsets = UIEdgeInsets(top: horizontalBuffer, left: 0, bottom: horizontalBuffer, right: horizontalBuffer)
  let avatarInset = A_SInsetLayoutSpec(insets: avatarInsets, child: <b>userAvatarImageNode</b>)

  let headerStack: A_SStackLayoutSpec = .horizontal()
  headerStack.alignItems = .center      // center items vertically in horizontal stack
  headerStack.justifyContent = .start   // justify content to the left side of the header stack
  headerStack.children = [avatarInset, headerSubStack, spacer]

  // header inset stack
  let insets = UIEdgeInsets(top: 0, left: horizontalBuffer, bottom: 0, right: horizontalBuffer)
  let headerWithInset = A_SInsetLayoutSpec(insets: insets, child: headerStack)

  // footer inset stack
  let footerInsets = UIEdgeInsets(top: verticalBuffer, left: horizontalBuffer, bottom: verticalBuffer, right: horizontalBuffer)
  let footerWithInset = A_SInsetLayoutSpec(insets: footerInsets, child: <b>photoCommentsNode</b>)

  // vertical stack
  let cellWidth = constrainedSize.max.width
  photoImageNode.style.preferredSize = CGSize(width: cellWidth, height: cellWidth)  // constrain photo frame size

  let verticalStack: A_SStackLayoutSpec = .vertical()
  verticalStack.alignItems = .stretch   // stretch headerStack to fill horizontal space
  verticalStack.children = [headerWithInset, <b>photoImageNode</b>, footerWithInset]

  return verticalStack
}
</pre>
</div>
</div>


Here you can see that the children of the `headerSubStack` depend on whether or not the `_photoLocationLabel` attributed string has returned from the reverseGeocode process yet. 

The `_userAvatarImageNode`, `_photoImageNode`, and `_photoCommentsNode` are added into the A_SLayoutSpec, but will not show up until their data fetches return.

### Updating an A_SLayoutSpec ###
<br>
**If something happens that you know will change your `A_SLayoutSpec`,  it is your job to call `setNeedsLayout`**. This is equivalent to `transitionLayout:duration:0` in the Transition Layout API. You can see this call in the completion block of the `photo.location reverseGeocodedLocationWithCompletionBlock:` call in the first code block. 

An appropriately constructed A_SLayoutSpec will know which subnodes need to be added, removed or animated. 

Try out the <a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram sample app</a> after looking at the code above, and you will see how simple it is to code an `A_SCellNode` whose layout is responsive to numerous, individual data fetches and returns. While the `A_SLayoutSpec` is coded in a way that leaves holes for the avatar and photo to populate, you can see how the cell's height will automatically adjust to accomodate the comments node at the bottom of the photo. 

This is just a simple example, but this feature has many more powerful uses. 

<div class = "note">
<b>Warning:</b> <code>addSubnode:</code> and <code>removeFromSupernode</code> should never be called on a node that has A_SM enabled. Doing so could cause the following exception - "A flattened layout must consist exclusively of node sublayouts".
</div> 
