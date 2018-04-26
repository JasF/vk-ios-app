---
title: A_SCellNode
layout: docs
permalink: /docs/cell-node.html
prevPage: display-node.html
nextPage: button-node.html
---

`A_SCellNode`, as you may have guessed, is the cell class of Tex_ture.  Unlike the various cells in UIKit, `A_SCellNode` can be used with `A_STableNodes`, `A_SCollectionNodes` and `A_SPagerNodes`, making it incredibly flexible.

### 3 Ways to Party

There are three ways in which you can implement the cells you'll use in your Tex_ture app: subclassing `A_SCellNode`, initializing with an existing `A_SViewController` or using an existing UIView or `CALayer`.

#### Subclassing

Subclassing an `A_SCellNode` is pretty much the same as <a href = "/docs/subclassing.html">subclassing</a> a regular `A_SDisplayNode`.  

Most likely, you'll write a few of the following:

- `-init` -- Thread safe initialization.
- `-layoutSpecThatFits:` -- Return a layout spec that defines the layout of your cell.
- `-didLoad` -- Called on the main thread.  Good place to add gesture recognizers, etc.
- `-layout` -- Also called on the main thread.  Layout is complete after the call to super which means you can do any extra tweaking you need to do.


#### Initializing with an `A_SViewController`

Say you already have some type of view controller written to display a view in your app.  If you want to take that view controller and drop its view in as a cell in one of the scrolling nodes or a pager node its no problem.

For example, say you already have a view controller written that manages an `A_STableNode`.  To use that table as a page in an `A_SPagerNode` you can use  `-initWithViewControllerBlock`.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNode *)pagerNode:(A_SPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
    NSArray *animals = self.allAnimals[index];
    
    A_SCellNode *node = [[A_SCellNode alloc] initWithViewControllerBlock:^UIViewController * _Nonnull{
        return [[AnimalTableNodeController alloc] initWithAnimals:animals];
    } didLoadBlock:nil];
    
    node.style.preferredSize = pagerNode.bounds.size;
    
    return node;
}
</pre>
<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeAt index: Int) -> A_SCellNode {
    let animals = allAnimals[index]
    
    let node = A_SCellNode(viewControllerBlock: { () -> UIViewController in
        return AnimalTableNodeController(animals: animals)
    }, didLoad: nil)
    
    node.style.preferredSize = pagerNode.bounds.size
    
    return node
}
</pre>
</div>
</div>

And this works for any combo of scrolling container node and `UIViewController` subclass.  You want to embed random view controllers in your collection node? Go for it.

<div class = "note">
Notice that you need to set the <code>.style.preferredSize</code> of a node created this way.  Normally your nodes will implement <code>-layoutSpecThatFits:</code> but since these don't you'll need give the cell a size.
</div>


#### Initializing with a `UIView` or `CALayer`

Alternatively, if you already have a `UIView` or `CALayer` subclass that you'd like to drop in as cell you can do that instead.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
- (A_SCellNode *)pagerNode:(A_SPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
    NSArray *animal = self.animals[index];
    
    A_SCellNode *node = [[A_SCellNode alloc] initWithViewBlock:^UIView * _Nonnull{
        return [[SomeAnimalView alloc] initWithAnimal:animal];
    }];

    node.style.preferredSize = pagerNode.bounds.size;
    
    return node;
}
</pre>
<pre lang="swift" class = "swiftCode hidden">
func pagerNode(_ pagerNode: A_SPagerNode, nodeAt index: Int) -> A_SCellNode {
    let animal = animals[index]
    
    let node = A_SCellNode { () -> UIView in
        return SomeAnimalView(animal: animal)
    }

    node.style.preferredSize = pagerNode.bounds.size
    
    return node
}
</pre>
</div>
</div>

As you can see, its roughly the same idea.  That being said, if you're doing this, you may consider converting the existing `UIView` subclass to be an `A_SCellNode` subclass in order to gain the advantage of asynchronous display.

### Never Show Placeholders

Usually, if a cell hasn't finished its display pass before it has reached the screen it will show placeholders until it has completed drawing its content.

If placeholders are unacceptable, you can set an `A_SCellNode`'s `neverShowPlaceholders` property to `YES`.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
node.neverShowPlaceholders = YES;
</pre>
<pre lang="swift" class = "swiftCode hidden">
node.neverShowPlaceholders = true
</pre>
</div>
</div>

With this property set to `YES`, the main thread will be blocked until display has completed for the cell.  This is more similar to UIKit, and in fact makes Tex_ture scrolling visually indistinguishable from UIKit's, except being faster.

<div class = "note">
Using this option does not eliminate all of the performance advantages of Tex_ture. Normally, a cell has been preloading and is almost done when it reaches the screen, so the blocking time is very short.  Even if the <code>rangeTuningParameters</code> are set to 0 this option outperforms UIKit.  While the main thread is waiting, subnode display executes concurrently.
</div>

### `UITableViewCell` specific propertys

<code>UITableViewCell</code> has properties like <code>selectionStyle</code>, <code>accessoryType</code> and <code>seperatorInset</code> that many of us use sometimes to give the Cell more detail. For this case <code>A_SCellNode</code> has the same (passthrough) properties that can be used. 

<div class = "note">
UIKits <code>UITableViewCell</code> contains <code>A_SCellNode</code> as a subview. Depending how your <code>A_SLayoutSpec</code> is defined it may occure that your Layout overlays the <code>UITableViewCell.accessoryView</code> and therefore not visible. Make sure that your Layout doesn't overlays any <code>UITableViewCell</code>'s specific properties.
</div>
