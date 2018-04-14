---
title: A_SCollectionNode
layout: docs
permalink: /docs/containers-ascollectionnode.html
prevPage: containers-astablenode.html
nextPage: containers-aspagernode.html
---

`A_SCollectionNode` is equivalent to UIKit's `UICollectionView` and can be used in place of any `UICollectionView`. 

`A_SCollectionNode` replaces `UICollectionView`'s required method

<div class = "highlight-group">
<span class="language-toggle">
  <a data-lang="swift" class="swiftButton">Swift</a>
  <a data-lang="objective-c" class = "active objcButton">Objective-C</a>
</span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath;
  </pre>

  <pre lang="swift" class = "swiftCode hidden">
override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  </pre>
</div>
</div>

with your choice of **_one_** of the following methods

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNode *)collectionNode:(A_SCollectionNode *)collectionNode nodeForItemAtIndexPath:(NSIndexPath *)indexPath
</pre>
  <pre lang="swift" class = "swiftCode hidden">
override func collectionNode(_ collectionNode: A_SCollectionNode, nodeForItemAt indexPath: IndexPath) -> A_SCellNode
  </pre>
</div>
</div>

<p>
or
</p>

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>

<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
</pre>
  <pre lang="swift" class = "swiftCode hidden">
override func collectionNode(_ collectionNode: A_SCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> A_SCellNodeBlock
  </pre>
</div>
</div>

It is recommended that you use the node block version of the method so that your collection node will be able to prepare and display all of its cells concurrently.

As noted in the previous section:

<ul>
  <li>A_SCollectionNodes do not utilize cell reuse.</li>
  <li>Using the "nodeBlock" method is preferred.</li>
  <li>It is very important that the returned node blocks are thread-safe.</li>
  <li>A_SCellNodes can be used by A_STableNode, A_SCollectionNode and A_SPagerNode.</li>
</ul>

### Node Block Thread Safety Warning

It is very important that node blocks be thread-safe. One aspect of that is ensuring that the data model is accessed _outside_ of the node block. Therefore, it is unlikely that you should need to use the index inside of the block. 

Consider the following `-collectionNode:nodeBlockForItemAtIndexPath:` method.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)collectionNode:(A_SCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
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
func collectionNode(_ collectionNode: A_SCollectionNode, nodeBlockForItemAt indexPath: IndexPath) -> A_SCellNodeBlock {
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

### Replacing a UICollectionViewController with an A_SViewController

Tex_ture does not offer an equivalent to UICollectionViewController. Instead, you can use the flexibility of A_SViewController to recreate any type of UI<em>...</em>ViewController. 

Consider, the following A_SViewController subclass.

An A_SCollectionNode is assigned to be managed by an `A_SViewController` in its `-initWithNode:` designated initializer method, thus making it a sort of A_SCollectionNodeController.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (instancetype)init
{
  _flowLayout = [[UICollectionViewFlowLayout alloc] init];
  _collectionNode = [[A_SCollectionNode alloc] initWithCollectionViewLayout:_flowLayout];
  
  self = [super initWithNode:_collectionNode];
  if (self) {
    _flowLayout.minimumInteritemSpacing = 1;
    _flowLayout.minimumLineSpacing = 1;
  }
  
  return self;
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
init() {
  flowLayout = UICollectionViewFlowLayout()
  collectionNode = A_SCollectionNode(collectionViewLayout: flowLayout)

  super.init(node: collectionNode)

  flowLayout.minimumInteritemSpacing = 1
  flowLayout.minimumLineSpacing = 1
}
</pre>
</div>
</div>

This works just as well with any node including as an A_STableNode, A_SPagerNode, etc.

### Accessing the A_SCollectionView
If you've used previous versions of Tex_ture, you'll notice that `A_SCollectionView` has been removed in favor of `A_SCollectionNode`.

<div class = "note">
`A_SCollectionView`, an actual `UICollectionView` subclass, is still used internally by `A_SCollectionNode`. While it should not be created directly, it can still be used directly by accessing the `.view` property of an `A_SCollectionNode`.
<br><br>
Don't forget that a node's `view` or `layer` property should only be accessed after viewDidLoad or didLoad, respectively, have been called.
</div>

The `LocationCollectionNodeController` above accesses the `A_SCollectionView` directly in `-viewDidLoad`.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _collectionNode.delegate = self;
  _collectionNode.dataSource = self;
  _collectionNode.view.allowsSelection = NO;
  _collectionNode.view.backgroundColor = [UIColor whiteColor];
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
override func viewDidLoad() {
  super.viewDidLoad()

  collectionNode.delegate = self
  collectionNode.dataSource = self
  collectionNode.view.allowsSelection = false
  collectionNode.view.backgroundColor = .white
}
</pre>
</div>
</div>

### Cell Sizing and Layout

As discussed in the <a href = "containers-astablenode.html">previous section</a>, `A_SCollectionNode` and `A_STableNode` do not need to keep track of the height of their `A_SCellNode`s.

Right now, cells will grow to fit their constrained size and will be laid out by whatever `UICollectionViewLayout` you provide.

Soon, there will be a method such as `A_STableNode`'s `-constrainedSizeForRow:` but at the moment, if you'd like to constrain the size of a cell used in a collection node, you need to wrap your layoutSpec object in an `A_SStaticLayoutSpec` and provide it with a 

### Examples

The most detailed example of laying out the cells of an `A_SCollectionNode` is the <a href = "https://github.com/texturegroup/texture/tree/master/examples/CustomCollectionView">CustomCollectionView</a> app.  It includes a Pinterest style cell layout using an `A_SCollectionNode` and a custom `UICollectionViewLayout`.

#### More Sample Apps with A_SCollectionNodes

<ul>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/A_SDKgram">A_SDKgram</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/CatDealsCollectionView">CatDealsCollectionView</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/A_SCollectionView">A_SCollectionView</a></li>
  <li><a href = "https://github.com/texturegroup/texture/tree/master/examples/CustomCollectionView">CustomCollectionView</a></li>
</ul>

### Interoperability with UICollectionViewCells

`A_SCollectionNode` supports using <code>UICollectionViewCells</code> alongside native <code>A_SCellNodes</code>. 

Note that these UIKit cells will **not** have the performance benefits of `A_SCellNodes` (like preloading, async layout, and async drawing), even when mixed within the same `A_SCollectionNode`. 

However, this interoperability allows developers the flexibility to test out the framework without needing to convert all of their cells at once. Read more <a href="uicollectionviewinterop.html">here</a>.