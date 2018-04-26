---
title: A_SPagerNode
layout: docs
permalink: /docs/containers-aspagernode.html
prevPage: containers-ascollectionnode.html
nextPage: display-node.html
---

`A_SPagerNode` is a subclass of `A_SCollectionNode` with a specific `UICollectionViewLayout` used under the hood. 

Using it allows you to produce a page style UI similar to what you'd create with UIKit's `UIPageViewController`. `A_SPagerNode` currently supports staying on the correct page during rotation. It does _not_ currently support circular scrolling.

The main dataSource methods are:

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (NSInteger)numberOfPagesInPagerNode:(A_SPagerNode *)pagerNode
</pre>

<pre lang="swift" class = "swiftCode hidden">
func numberOfPages(in pagerNode: A_SPagerNode) -> Int
</pre>
</div>
</div>

and 

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SCellNode *)pagerNode:(A_SPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
</pre>

<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeAt index: Int) -> A_SCellNode
</pre>
</div>
</div>

or

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
<pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)pagerNode:(A_SPagerNode *)pagerNode nodeBlockAtIndex:(NSInteger)index`
</pre>

<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeBlockAt index: Int) -> A_SCellNodeBlock
</pre>
</div>
</div>

These two methods, just as with `A_SCollectionNode` and `A_STableNode` need to return either an `A_SCellNode` or an `A_SCellNodeBlock` - a block that creates an `A_SCellNode` and can be run on a background thread. 

Note that neither methods should rely on cell reuse (they will be called once per row). Also, unlike UIKit, these methods are not called when the row is just about to display. 

While `-pagerNode:nodeAtIndex:` will be called on the main thread, `-pagerNode:nodeBlockAtIndex:` is preferred because it concurrently allocates cell nodes, meaning that the `-init:` method of each  of your subnodes will be run in the background. **It is very important that node blocks be thread-safe** as they can be called on the main thread or a background queue.

### Node Block Thread Safety Warning

It is imperative that the data model be accessed outside of the node block. This means that it is highly unlikely that you should need to use the index inside of the block. 

In the example below, you can see how the index is used to access the photo model before creating the node block.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNodeBlock)pagerNode:(A_SPagerNode *)pagerNode nodeBlockAtIndex:(NSInteger)index
{
  PhotoModel *photoModel = _photoFeed[index];
  
  // this part can be executed on a background thread - it is important to make sure it is thread safe!
  A_SCellNode *(^cellNodeBlock)() = ^A_SCellNode *() {
    PhotoCellNode *cellNode = [[PhotoCellNode alloc] initWithPhoto:photoModel];
    return cellNode;
  };
  
  return cellNodeBlock;
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeBlockAt index: Int) -> A_SCellNodeBlock {
    guard photoFeed.count > index else { return { A_SCellNode() } }
    
    let photoModel = photoFeed[index]
    let cellNodeBlock = { () -> A_SCellNode in
        let cellNode = PhotoCellNode(photo: photoModel)
        return cellNode
    }
    return cellNodeBlock
}
</pre>
</div>
</div>

### Using an A_SViewController For Optimal Performance

One especially useful pattern is to return an `A_SCellNode` that is initialized with an existing `UIViewController` or `A_SViewController`. For optimal performance, use an `A_SViewController`.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNode *)pagerNode:(A_SPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
    NSArray *animals = self.animals[index];
    
    A_SCellNode *node = [[A_SCellNode alloc] initWithViewControllerBlock:^{
        return [[AnimalTableNodeController alloc] initWithAnimals:animals];;
    } didLoadBlock:nil];
    
    node.style.preferredSize = pagerNode.bounds.size;
    
    return node;
}
</pre>

<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeAt index: Int) -> A_SCellNode {
    guard animals.count > index else { return A_SCellNode() }

    let animal = animals[index]
    let node = A_SCellNode(viewControllerBlock: { () -> UIViewController in
      return AnimalTableNodeController(animals: animals)
    }, didLoadBlock: nil)

    node.style.preferredSize = pagerNode.bounds.size

    return node
}
</pre>
</div>
</div>

In this example, you can see that the node is constructed using the `-initWithViewControllerBlock:` method.  It is usually necessary to provide a cell created this way with a `style.preferredSize` so that it can be laid out correctly.

### Use A_SPagerNode as root node of an A_SViewController

#### Log message while popping back in the view controller hierarchy
If you use an `A_SPagerNode` embedded in an `A_SViewController` in full screen. If you pop back from the view controller hierarchy you will see some error message in the console.

To resolve the error message set `self.automaticallyAdjustsScrollViewInsets = NO;` in `viewDidLoad` in your `A_SViewController` subclass.

#### `navigationBar.translucent` is set to YES
If you have an `A_SPagerNode` embedded in an `A_SViewController` in full screen and set the `navigationBar.translucent` to `YES`, you will see an error message while pushing the view controller on the view controller stack.

To resolve the error message add `[self.pagerNode waitUntilAllUpdatesAreCommitted];`  within `- (void)viewWillAppear:(BOOL)animated`  in your `A_SViewController` subclass.
Unfortunately the disadvantage of this is that the first measurement pass will block the main thread until it finishes.

#### Some more details about the error messages above
The reason for this error message is that due to the asynchronous nature of Tex_ture, measurement of nodes will happen on a background thread as UIKit will resize the view of the `A_SViewController`  on  on the main thread. The new layout pass has to wait until the old layout pass finishes with an old layout constrained size. Unfortunately while the measurement pass with the old constrained size is still in progress the `A_SPagerFlowLayout` that is backing a `A_SPagerNode` will print some errors in the console as it expects sizes for nodes already measured with the new constrained size.

### Sample Apps

Check out the following sample apps to see an `A_SPagerNode` in action:
<ul>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/PagerNode">PagerNode</a></li>
  <li><a href="https://github.com/texturegroup/texture/tree/master/examples/VerticalWithinHorizontalScrolling">VerticalWithinHorizontalScrolling</a></li>
</ul>
