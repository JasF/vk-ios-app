---
title: A_SControlNode
layout: docs
permalink: /docs/control-node.html
prevPage: map-node.html
nextPage: scroll-node.html
---

`A_SControlNode` is the Tex_ture equivalent to `UIControl`.  You don't create instances of `A_SControlNode` directly.  Instead, you can use it as a subclassing point when creating controls of your own.  In fact, <a href = "/docs/text-node.html">A_STextNode</a>, <a href = "/docs/image-node.html">A_SImageNode</a>, <a href = "/docs/video-node.html">A_SVideoNode</a> and <a href = "/docs/map-node.html">A_SMapNode</a> are all subclasses of `A_SControlNode`.

This fact is especially useful when it comes to image and text nodes.  Having the ability to add target-action pairs means that you can use any text or image node as a button without having to rely on creating gesture recognizers, as you would with text in UIKit, or creating extraneous views as you might when using `UIButton`.

### Control State

Like `UIControl`, `A_SControlNode` has a state which defines its appearance and ability to support user interactions.  Its state can be one of any state defined by `A_SControlState`.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
<pre lang="objc" class="objcCode">
typedef NS_OPTIONS(NSUInteger, A_SControlState) {
    A_SControlStateNormal       = 0,
    A_SControlStateHighlighted  = 1 << 0,  // used when isHighlighted is set
    A_SControlStateDisabled     = 1 << 1,
    A_SControlStateSelected     = 1 << 2,  // used when isSelected is set
    ...
};
</pre>
<pre lang="swift" class = "swiftCode hidden">
public struct A_SControlState : OptionSet {
    public static var highlighted: A_SControlState { get } // used when A_SControlNode isHighlighted is set
    public static var disabled: A_SControlState { get }
    public static var selected: A_SControlState { get } // used when A_SControlNode isSelected is set
    public static var reserved: A_SControlState { get } // flags reserved for internal framework use
}
</pre>
</div>
</div>

### Target-Action Mechanism

Also similarly to `UIControl`, `A_SControlNode`'s have a set of events defined which you can react to by assigning a target-action pair.  

The available actions are: 
<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
typedef NS_OPTIONS(NSUInteger, A_SControlNodeEvent)
{
  /** A touch-down event in the control node. */
  A_SControlNodeEventTouchDown         = 1 << 0,
  /** A repeated touch-down event in the control node; for this event the value of the UITouch tapCount method is greater than one. */
  A_SControlNodeEventTouchDownRepeat   = 1 << 1,
  /** An event where a finger is dragged inside the bounds of the control node. */
  A_SControlNodeEventTouchDragInside   = 1 << 2,
  /** An event where a finger is dragged just outside the bounds of the control. */
  A_SControlNodeEventTouchDragOutside  = 1 << 3,
  /** A touch-up event in the control node where the finger is inside the bounds of the node. */
  A_SControlNodeEventTouchUpInside     = 1 << 4,
  /** A touch-up event in the control node where the finger is outside the bounds of the node. */
  A_SControlNodeEventTouchUpOutside    = 1 << 5,
  /** A system event canceling the current touches for the control node. */
  A_SControlNodeEventTouchCancel       = 1 << 6,
  /** All events, including system events. */
  A_SControlNodeEventAllEvents         = 0xFFFFFFFF
};
</pre>
<pre lang="swift" class = "swiftCode hidden">
public struct A_SControlNodeEvent : OptionSet {
    /** A touch-down event in the control node. */
    public static var touchDown: A_SControlNodeEvent { get }
    /** A repeated touch-down event in the control node; for this event the value of the UITouch tapCount method is greater than one. */
    public static var touchDownRepeat: A_SControlNodeEvent { get }
    /** An event where a finger is dragged inside the bounds of the control node. */
    public static var touchDragInside: A_SControlNodeEvent { get }
    /** An event where a finger is dragged just outside the bounds of the control. */
    public static var touchDragOutside: A_SControlNodeEvent { get }
    /** A touch-up event in the control node where the finger is inside the bounds of the node. */
    public static var touchUpInside: A_SControlNodeEvent { get }
    /** A touch-up event in the control node where the finger is outside the bounds of the node. */
    public static var touchUpOutside: A_SControlNodeEvent { get }
    /** A system event canceling the current touches for the control node. */
    public static var touchCancel: A_SControlNodeEvent { get }
    /** A system event when the Play/Pause button on the Apple TV remote is pressed. */
    public static var primaryActionTriggered: A_SControlNodeEvent { get }
    /** All events, including system events. */
    public static var allEvents: A_SControlNodeEvent { get }
}
</pre>
</div>
</div>

Assigning a target and action for these events is done with the same methods as a `UIControl`, namely using `–addTarget:action:forControlEvents:`.

### Hit Test Slop

While all node's have a `hitTestSlop` property, this is usually most useful when dealing with controls.  Instead of needing to make your control bigger, or needing to override `-hitTest:withEvent:` you can just assign a `UIEdgeInsets` to your control and its boundaries will be expanded accordingly.

<div class = "highlight-group">
<span class="language-toggle"><a data-lang="swift" class="swiftButton">Swift</a><a data-lang="objective-c" class = "active objcButton">Objective-C</a></span>
<div class = "code">
  <pre lang="objc" class="objcCode">
CGFloat horizontalDiff = (bounds.size.width - _playButton.bounds.size.width)/2;
CGFloat verticalDiff = (bounds.size.height - _playButton.bounds.size.height)/2;

_playButton.hitTestSlop = UIEdgeInsetsMake(-verticalDiff, -horizontalDiff, -verticalDiff, -horizontalDiff);
</pre>
<pre lang="swift" class = "swiftCode hidden">
let horizontalDiff = (bounds.size.width - playButton.bounds.size.width) / 2
let verticalDiff = (bounds.size.height - playButton.bounds.size.height) / 2

playButton.hitTestSlop = UIEdgeInsets(top: -verticalDiff, left: -horizontalDiff, bottom: -verticalDiff, right: -horizontalDiff)
</pre>
</div>
</div>

Remember that, since the property is an inset, you'll need to use negative values in order to expand the size of your tappable region.

### Hit Test Visualization

The <a href = "/docs/debug-tool-hit-test-visualization.html">hit test visualization tool</a> is an option to enable highlighting of the tappable areas of your nodes.  To enable it, include `[A_SControlNode setEnableHitTestDebug:YES]` in your app delegate in `-application:didFinishLaunchingWithOptions:`.
