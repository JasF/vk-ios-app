---
title: Layout Options
layout: docs
permalink: /docs/layout-options.html
prevPage: automatic-layout-debugging.html
nextPage: layer-backing.html
---

When using Tex_ture, you have three options for layout. Note that UIKit Autolayout is **not** supported by Tex_ture. 
#Manual Sizing & Layout

This original layout method shipped with Tex_ture 1.0 and is analogous to UIKit's layout methods. Use this method for A_SViewControllers (unless you subclass the node).

`[A_SDisplayNode calculateSizeThatFits:]` **vs.** `[UIView sizeThatFits:]`

`[A_SDisplayNode layout]` **vs.** `[UIView layoutSubviews]`

###Advantages (over UIKit)
- Eliminates all main thread layout cost
- Results are cached

###Shortcomings (same as UIKit):
- Code duplication between methods
- Logic is not reusable

#Unified Sizing & Layout

This layout method does not have a UIKit analog. It is implemented by calling

`- (A_SLayout *)calculateLayoutThatFits: (A_SSizeRange)constraint`

###Advantages
- zero duplication
- still async, still cached

###Shortcomings
- logic is not reusable, and is still manual

# Automatic, Extensible Layout

This is the reccomended layout method. It does not have a UIKit analog and is implemented by calling

`- (A_SLayoutSpec *)layoutSpecThatFits:(A_SSizeRange)constraint`
###Advantages
- can reuse even complex, custom layouts
- built-in specs provide automatic layout
- combine to compose new layouts easily
- still async, cached, and zero duplication

The diagram below shows how options #2 and #3 above both result in an A_SLayout, except that in option #3, the A_SLayout is produced automatically by the A_SLayoutSpec.  

<INSERT DIAGRAM>
