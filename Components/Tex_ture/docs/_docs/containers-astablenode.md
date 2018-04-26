---
title: A_STableNode
layout: docs
permalink: /docs/containers-astablenode.html
prevPage: containers-asnodecontroller.html
nextPage: containers-ascollectionnode.html
---

`A_STableNode` is equivalent to UIKit's `UITableView` and can be used in place of any `UITableView`. 

`A_STableNode` replaces `UITableView`'s required method

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
  </pre>
</div>
</div>

with your choice of **_one_** of the following methods

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNode *)tableNode:(A_STableNode *)tableNode nodeForRowAtIndexPath:(NSIndexPath *)indexPath
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
func tableNode(_ tableNode: A_STableNode, nodeForRowAt indexPath: IndexPath) -> A_SCellNode
  </pre>
</div>
</div>

or

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)tableNode:(A_STableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
func tableNode(_ tableNode: A_STableNode, nodeBlockForRowAt indexPath: IndexPath) -> A_SCellNodeBlock
  </pre>
</div>
</div>

<br>
<div class = "note">
It is recommended that you use the node block version of these methods so that your table node will be able to prepare and display all of its cells concurrently. This means that all subnode initialization methods can be run in the background.  Make sure to keep 'em thread safe.
</div>

These two methods, need to return either an <a href = "cell-node.html">`A_SCellNode`</a> or an `A_SCellNodeBlock`. An `A_SCellNodeBlock` is a block that creates a `A_SCellNode` which can be run on a background thread. Note that `A_SCellNodes` are used by `A_STableNode`, `A_SCollectionNode` and `A_SPagerNode`. 

Note that neither of these methods require a reuse mechanism.

### Replacing UITableViewController with A_SViewController

Tex_ture does not offer an equivalent to `UITableViewController`. Instead, use an `A_SViewController` initialized with an `A_STableNode`. 

Consider, again, the `A_SViewController` subclass - PhotoFeedNodeController - from the <a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">`A_SDKgram sample app`</a> that uses a table node as its managed node.

An `A_STableNode` is assigned to be managed by an `A_SViewController` in its `-initWithNode:` designated initializer method. 

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (instancetype)init
{
    _tableNode = [[A_STableNode alloc] initWithStyle:UITableViewStylePlain];
    self = [super initWithNode:_tableNode];
    
    if (self) {
      _tableNode.dataSource = self;
      _tableNode.delegate = self;
    }
    
    return self;
}
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
init(models: [Model]) {
    let tableNode = A_STableNode(style: .plain)

    super.init(node: tableNode)

    self.models = models  
    self.tableNode = tableNode
    self.tableNode.dataSource = self
    
    return self
}
</pre>
</div>
</div>

### Node Block Thread Safety Warning

It is very important that node blocks be thread-safe. One aspect of that is ensuring that the data model is accessed _outside_ of the node block. Therefore, it is unlikely that you should need to use the index inside of the block. 

Consider the following `-tableNode:nodeBlockForRowAtIndexPath:` method from the `PhotoFeedNodeController.m` file in the <a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram sample app</a>.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)tableNode:(A_STableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoModel *photoModel = [_photoFeed objectAtIndex:indexPath.row];
    
    // this may be executed on a background thread - it is important to make sure it is thread safe
    A_SCellNode *(^cellNodeBlock)() = ^A_SCellNode *() {
        PhotoCellNode *cellNode = [[PhotoCellNode alloc] initWithPhoto:photoModel];
        cellNode.delegate = self;
        return cellNode;
    };
    
    return cellNodeBlock;
}
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
func tableNode(_ tableNode: A_STableNode, nodeBlockForRowAt indexPath: IndexPath) -> A_SCellNodeBlock {
  guard photoFeed.count > indexPath.row else { return { A_SCellNode() } }
    
  let photoModel = photoFeed[indexPath.row]
    
  // this may be executed on a background thread - it is important to make sure it is thread safe
  let cellNodeBlock = { () -> A_SCellNode in
    let cellNode = PhotoCellNode(photo: photoModel)
    cellNode.delegate = self
    return cellNode
  }
    
  return cellNodeBlock
}
</pre>
</div>
</div>

In the example above, you can see how the index is used to access the photo model before creating the node block.

### Accessing the A_STableView

If you've used previous versions of Tex_ture, you'll notice that `A_STableView` has been removed in favor of `A_STableNode`.

<div class = "note">
<code>A_STableView</code>, an actual <code>UITableView</code> subclass, is still used internally by <code>A_STableNode</code>. While it should not be created directly, it can still be used directly by accessing the <code>.view</code> property of an <code>A_STableNode</code>.

Don't forget that a node's <code>view</code> or <code>layer</code> property should only be accessed after <code>-viewDidLoad</code> or <code>-didLoad</code>, respectively, have been called.
</div>

For example, you may want to set a table's separator style property. This can be done by accessing the table node's view in the `-viewDidLoad:` method as seen in the example below. 

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _tableNode.view.allowsSelection = NO;
  _tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
  _tableNode.view.leadingScreensForBatching = 3.0;  // default is 2.0
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func viewDidLoad() {
  super.viewDidLoad()

  tableNode.view.allowsSelection = false
  tableNode.view.separatorStyle = .none
  tableNode.view.leadingScreensForBatching = 3.0  // default is 2.0
}
</pre>
</div>
</div>

### Table Row Height

An important thing to notice is that `A_STableNode` does not provide an equivalent to `UITableView`'s `-tableView:heightForRowAtIndexPath:`.

This is because nodes are responsible for determining their own height based on the provided constraints.  This means you no longer have to write code to determine this detail at the view controller level. 

A node defines its height by way of the layoutSpec returned in the `-layoutSpecThatFits:` method. All nodes given a constrained size are able to calculate their desired size.

<div class = "note">
By default, a <code>A_STableNode</code> provides its cells with a size range constraint where the minimum width is the tableNode's width and a minimum height is <code>0</code>.  The maximum width is also the <code>tableNode</code>'s width but the maximum height is <code>FLT_MAX</code>.
<br><br>
This is all to say, a `tableNode`'s cells will always fill the full width of the `tableNode`, but their height is flexible making self-sizing cells something that happens automatically. 
</div>

If you call `-setNeedsLayout` on an `A_SCellNode`, it will automatically perform another layout pass and if its overall desired size has changed, the table will be informed and will update itself. 

This is different from `UIKit` where normally you would have to call reload row / item. This saves tons of code, check out the <a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram sample app</a> to see side by side implementations of an `UITableView` and `A_STableNode` implemented social media feed. 

### Sample Apps using A_STableNode
<ul>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/Kittens">Kittens</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/HorizontalWithinVerticalScrolling">HorizontalWithinVerticalScrolling</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/VerticalWithinHorizontalScrolling">VerticalWithinHorizontalScrolling</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/SocialAppLayout">SocialAppLayout</a></li>
</ul>
