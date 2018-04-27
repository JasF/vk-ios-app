//
//  A_SDisplayNode.h
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/_A_SAsyncTransactionContainer.h>
#import <Async_DisplayKit/A_SBaseDefines.h>
#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SAsciiArtBoxCreator.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <Async_DisplayKit/A_SLayoutElement.h>

NS_ASSUME_NONNULL_BEGIN

#define A_SDisplayNodeLoggingEnabled 0

@class A_SDisplayNode;
@protocol A_SContextTransitioning;

/**
 * UIView creation block. Used to create the backing view of a new display node.
 */
typedef UIView * _Nonnull(^A_SDisplayNodeViewBlock)(void);

/**
 * UIView creation block. Used to create the backing view of a new display node.
 */
typedef UIViewController * _Nonnull(^A_SDisplayNodeViewControllerBlock)(void);

/**
 * CALayer creation block. Used to create the backing layer of a new display node.
 */
typedef CALayer * _Nonnull(^A_SDisplayNodeLayerBlock)(void);

/**
 * A_SDisplayNode loaded callback block. This block is called BEFORE the -didLoad method and is always called on the main thread.
 */
typedef void (^A_SDisplayNodeDidLoadBlock)(__kindof A_SDisplayNode * node);

/**
 * A_SDisplayNode will / did render node content in context.
 */
typedef void (^A_SDisplayNodeContextModifier)(CGContextRef context, id _Nullable drawParameters);

/**
 * A_SDisplayNode layout spec block. This block can be used instead of implementing layoutSpecThatFits: in subclass
 */
typedef A_SLayoutSpec * _Nonnull(^A_SLayoutSpecBlock)(__kindof A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize);

/**
 * Async_DisplayKit non-fatal error block. This block can be used for handling non-fatal errors. Useful for reporting
 * errors that happens in production.
 */
typedef void (^A_SDisplayNodeNonFatalErrorBlock)(__kindof NSError * _Nonnull error);

/**
 * Interface state is available on A_SDisplayNode and A_SViewController, and
 * allows checking whether a node is in an interface situation where it is prudent to trigger certain
 * actions: measurement, data loading, display, and visibility (the latter for animations or other onscreen-only effects).
 * 
 * The defualt state, A_SInterfaceStateNone, means that the element is not predicted to be onscreen soon and
 * preloading should not be performed. Swift: use [] for the default behavior.
 */
typedef NS_OPTIONS(NSUInteger, A_SInterfaceState)
{
  /** The element is not predicted to be onscreen soon and preloading should not be performed */
  A_SInterfaceStateNone          = 0,
  /** The element may be added to a view soon that could become visible.  Measure the layout, including size calculation. */
  A_SInterfaceStateMeasureLayout = 1 << 0,
  /** The element is likely enough to come onscreen that disk and/or network data required for display should be fetched. */
  A_SInterfaceStatePreload       = 1 << 1,
  /** The element is very likely to become visible, and concurrent rendering should be executed for any -setNeedsDisplay. */
  A_SInterfaceStateDisplay       = 1 << 2,
  /** The element is physically onscreen by at least 1 pixel.
   In practice, all other bit fields should also be set when this flag is set. */
  A_SInterfaceStateVisible       = 1 << 3,

  /**
   * The node is not contained in a cell but it is in a window.
   *
   * Currently we only set `interfaceState` to other values for
   * nodes contained in table views or collection views.
   */
  A_SInterfaceStateInHierarchy   = A_SInterfaceStateMeasureLayout | A_SInterfaceStatePreload | A_SInterfaceStateDisplay | A_SInterfaceStateVisible,
};

typedef NS_ENUM(NSInteger, A_SCornerRoundingType) {
  A_SCornerRoundingTypeDefaultSlowCALayer,
  A_SCornerRoundingTypePrecomposited,
  A_SCornerRoundingTypeClipping
};

/**
 * Default drawing priority for display node
 */
extern NSInteger const A_SDefaultDrawingPriority;

/**
 * An `A_SDisplayNode` is an abstraction over `UIView` and `CALayer` that allows you to perform calculations about a view
 * hierarchy off the main thread, and could do rendering off the main thread as well.
 *
 * The node API is designed to be as similar as possible to `UIView`. See the README for examples.
 *
 * ## Subclassing
 *
 * `A_SDisplayNode` can be subclassed to create a new UI element. The subclass header `A_SDisplayNode+Subclasses` provides
 * necessary declarations and conveniences.
 *
 * Commons reasons to subclass includes making a `UIView` property available and receiving a callback after async
 * display.
 *
 */

@interface A_SDisplayNode : NSObject

/** @name Initializing a node object */


/** 
 * @abstract Designated initializer.
 *
 * @return An A_SDisplayNode instance whose view will be a subclass that enables asynchronous rendering, and passes 
 * through -layout and touch handling methods.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;


/**
 * @abstract Alternative initializer with a block to create the backing view.
 *
 * @param viewBlock The block that will be used to create the backing view.
 *
 * @return An A_SDisplayNode instance that loads its view with the given block that is guaranteed to run on the main
 * queue. The view will render synchronously and -layout and touch handling methods on the node will not be called.
 */
- (instancetype)initWithViewBlock:(A_SDisplayNodeViewBlock)viewBlock;

/**
 * @abstract Alternative initializer with a block to create the backing view.
 *
 * @param viewBlock The block that will be used to create the backing view.
 * @param didLoadBlock The block that will be called after the view created by the viewBlock is loaded
 *
 * @return An A_SDisplayNode instance that loads its view with the given block that is guaranteed to run on the main
 * queue. The view will render synchronously and -layout and touch handling methods on the node will not be called.
 */
- (instancetype)initWithViewBlock:(A_SDisplayNodeViewBlock)viewBlock didLoadBlock:(nullable A_SDisplayNodeDidLoadBlock)didLoadBlock;

/**
 * @abstract Alternative initializer with a block to create the backing layer.
 *
 * @param layerBlock The block that will be used to create the backing layer.
 *
 * @return An A_SDisplayNode instance that loads its layer with the given block that is guaranteed to run on the main
 * queue. The layer will render synchronously and -layout and touch handling methods on the node will not be called.
 */
- (instancetype)initWithLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock;

/**
 * @abstract Alternative initializer with a block to create the backing layer.
 *
 * @param layerBlock The block that will be used to create the backing layer.
 * @param didLoadBlock The block that will be called after the layer created by the layerBlock is loaded
 *
 * @return An A_SDisplayNode instance that loads its layer with the given block that is guaranteed to run on the main
 * queue. The layer will render synchronously and -layout and touch handling methods on the node will not be called.
 */
- (instancetype)initWithLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock didLoadBlock:(nullable A_SDisplayNodeDidLoadBlock)didLoadBlock;

/**
 * @abstract Add a block of work to be performed on the main thread when the node's view or layer is loaded. Thread safe.
 * @warning Be careful not to retain self in `body`. Change the block parameter list to `^(MYCustomNode *self) {}` if you
 *   want to shadow self (e.g. if calling this during `init`).
 *
 * @param body The work to be performed when the node is loaded.
 *
 * @precondition The node is not already loaded.
 */
- (void)onDidLoad:(A_SDisplayNodeDidLoadBlock)body;

/**
 * Set the block that should be used to load this node's view.
 *
 * @param viewBlock The block that creates a view for this node.
 *
 * @precondition The node is not yet loaded.
 *
 * @note You will usually NOT call this. See the limitations documented in @c initWithViewBlock:
 */
- (void)setViewBlock:(A_SDisplayNodeViewBlock)viewBlock;

/**
 * Set the block that should be used to load this node's layer.
 *
 * @param layerBlock The block that creates a layer for this node.
 *
 * @precondition The node is not yet loaded.
 *
 * @note You will usually NOT call this. See the limitations documented in @c initWithLayerBlock:
 */
- (void)setLayerBlock:(A_SDisplayNodeLayerBlock)layerBlock;

/** 
 * @abstract Returns whether the node is synchronous.
 *
 * @return NO if the node wraps a _A_SDisplayView, YES otherwise.
 */
@property (atomic, readonly, assign, getter=isSynchronous) BOOL synchronous;

/** @name Getting view and layer */

/** 
 * @abstract Returns a view.
 *
 * @discussion The view property is lazily initialized, similar to UIViewController. 
 * To go the other direction, use A_SViewToDisplayNode() in A_SDisplayNodeExtras.h.
 *
 * @warning The first access to it must be on the main thread, and should only be used on the main thread thereafter as 
 * well.
 */
@property (nonatomic, readonly, strong) UIView *view;

/** 
 * @abstract Returns whether a node's backing view or layer is loaded.
 *
 * @return YES if a view is loaded, or if layerBacked is YES and layer is not nil; NO otherwise.
 */
@property (nonatomic, readonly, assign, getter=isNodeLoaded) BOOL nodeLoaded;

/** 
 * @abstract Returns whether the node rely on a layer instead of a view.
 *
 * @return YES if the node rely on a layer, NO otherwise.
 */
@property (nonatomic, assign, getter=isLayerBacked) BOOL layerBacked;

/** 
 * @abstract Returns a layer.
 *
 * @discussion The layer property is lazily initialized, similar to the view property.
 * To go the other direction, use A_SLayerToDisplayNode() in A_SDisplayNodeExtras.h.
 *
 * @warning The first access to it must be on the main thread, and should only be used on the main thread thereafter as 
 * well.
 */
@property (nonatomic, readonly, strong) CALayer * _Nonnull layer;

/**
 * Returns YES if the node is – at least partially – visible in a window.
 *
 * @see didEnterVisibleState and didExitVisibleState
 */
@property (readonly, getter=isVisible) BOOL visible;

/**
 * Returns YES if the node is in the preloading interface state.
 *
 * @see didEnterPreloadState and didExitPreloadState
 */
@property (readonly, getter=isInPreloadState) BOOL inPreloadState;

/**
 * Returns YES if the node is in the displaying interface state.
 *
 * @see didEnterDisplayState and didExitDisplayState
 */
@property (readonly, getter=isInDisplayState) BOOL inDisplayState;

/**
 * @abstract Returns the Interface State of the node.
 *
 * @return The current A_SInterfaceState of the node, indicating whether it is visible and other situational properties.
 *
 * @see A_SInterfaceState
 */
@property (readonly) A_SInterfaceState interfaceState;

/**
 * @abstract Class property that allows to set a block that can be called on non-fatal errors. This
 * property can be useful for cases when Async Display Kit can recover from an abnormal behavior, but
 * still gives the opportunity to use a reporting mechanism to catch occurrences in production. In
 * development, Async Display Kit will assert instead of calling this block.
 *
 * @warning This method is not thread-safe.
 */
@property (nonatomic, class, copy) A_SDisplayNodeNonFatalErrorBlock nonFatalErrorBlock;

/** @name Managing the nodes hierarchy */


/** 
 * @abstract Add a node as a subnode to this node.
 *
 * @param subnode The node to be added.
 *
 * @discussion The subnode's view will automatically be added to this node's view, lazily if the views are not created 
 * yet.
 */
- (void)addSubnode:(A_SDisplayNode *)subnode;

/** 
 * @abstract Insert a subnode before a given subnode in the list.
 *
 * @param subnode The node to insert below another node.
 * @param below The sibling node that will be above the inserted node.
 *
 * @discussion If the views are loaded, the subnode's view will be inserted below the given node's view in the hierarchy 
 * even if there are other non-displaynode views.
 */
- (void)insertSubnode:(A_SDisplayNode *)subnode belowSubnode:(A_SDisplayNode *)below;

/** 
 * @abstract Insert a subnode after a given subnode in the list.
 *
 * @param subnode The node to insert below another node.
 * @param above The sibling node that will be behind the inserted node.
 *
 * @discussion If the views are loaded, the subnode's view will be inserted above the given node's view in the hierarchy
 * even if there are other non-displaynode views.
 */
- (void)insertSubnode:(A_SDisplayNode *)subnode aboveSubnode:(A_SDisplayNode *)above;

/** 
 * @abstract Insert a subnode at a given index in subnodes.
 *
 * @param subnode The node to insert.
 * @param idx The index in the array of the subnodes property at which to insert the node. Subnodes indices start at 0
 * and cannot be greater than the number of subnodes.
 *
 * @discussion If this node's view is loaded, A_SDisplayNode insert the subnode's view after the subnode at index - 1's 
 * view even if there are other non-displaynode views.
 */
- (void)insertSubnode:(A_SDisplayNode *)subnode atIndex:(NSInteger)idx;

/** 
 * @abstract Replace subnode with replacementSubnode.
 *
 * @param subnode A subnode of self.
 * @param replacementSubnode A node with which to replace subnode.
 *
 * @discussion Should both subnode and replacementSubnode already be subnodes of self, subnode is removed and 
 * replacementSubnode inserted in its place.
 * If subnode is not a subnode of self, this method will throw an exception.
 * If replacementSubnode is nil, this method will throw an exception
 */
- (void)replaceSubnode:(A_SDisplayNode *)subnode withSubnode:(A_SDisplayNode *)replacementSubnode;

/** 
 * @abstract Remove this node from its supernode.
 *
 * @discussion The node's view will be automatically removed from the supernode's view.
 */
- (void)removeFromSupernode;

/** 
 * @abstract The receiver's immediate subnodes.
 */
@property (nonatomic, readonly, copy) NSArray<A_SDisplayNode *> *subnodes;

/** 
 * @abstract The receiver's supernode.
 */
@property (nonatomic, readonly, weak) A_SDisplayNode *supernode;


/** @name Drawing and Updating the View */

/** 
 * @abstract Whether this node's view performs asynchronous rendering.
 *
 * @return Defaults to YES, except for synchronous views (ie, those created with -initWithViewBlock: /
 * -initWithLayerBlock:), which are always NO.
 *
 * @discussion If this flag is set, then the node will participate in the current asyncdisplaykit_async_transaction and 
 * do its rendering on the displayQueue instead of the main thread.
 *
 * Asynchronous rendering proceeds as follows:
 *
 * When the view is initially added to the hierarchy, it has -needsDisplay true.
 * After layout, Core Animation will call -display on the _A_SDisplayLayer
 * -display enqueues a rendering operation on the displayQueue
 * When the render block executes, it calls the delegate display method (-drawRect:... or -display)
 * The delegate provides contents via this method and an operation is added to the asyncdisplaykit_async_transaction
 * Once all rendering is complete for the current asyncdisplaykit_async_transaction,
 * the completion for the block sets the contents on all of the layers in the same frame
 *
 * If asynchronous rendering is disabled:
 *
 * When the view is initially added to the hierarchy, it has -needsDisplay true.
 * After layout, Core Animation will call -display on the _A_SDisplayLayer
 * -display calls  delegate display method (-drawRect:... or -display) immediately
 * -display sets the layer contents immediately with the result
 *
 * Note: this has nothing to do with -[CALayer drawsAsynchronously].
 */
@property (nonatomic, assign) BOOL displaysAsynchronously;

/** 
 * @abstract Prevent the node's layer from displaying.
 *
 * @discussion A subclass may check this flag during -display or -drawInContext: to cancel a display that is already in 
 * progress.
 *
 * Defaults to NO. Does not control display for any child or descendant nodes; for that, use 
 * -recursivelySetDisplaySuspended:.
 *
 * If a setNeedsDisplay occurs while displaySuspended is YES, and displaySuspended is set to NO, then the 
 * layer will be automatically displayed.
 */
@property (nonatomic, assign) BOOL displaySuspended;

/**
 * @abstract Whether size changes should be animated. Default to YES.
 */
@property (nonatomic, assign) BOOL shouldAnimateSizeChanges;

/** 
 * @abstract Prevent the node and its descendants' layer from displaying.
 *
 * @param flag YES if display should be prevented or cancelled; NO otherwise.
 *
 * @see displaySuspended
 */
- (void)recursivelySetDisplaySuspended:(BOOL)flag;

/**
 * @abstract Calls -clearContents on the receiver and its subnode hierarchy.
 *
 * @discussion Clears backing stores and other memory-intensive intermediates.
 * If the node is removed from a visible hierarchy and then re-added, it will automatically trigger a new asynchronous display,
 * as long as displaySuspended is not set.
 * If the node remains in the hierarchy throughout, -setNeedsDisplay is required to trigger a new asynchronous display.
 *
 * @see displaySuspended and setNeedsDisplay
 */
- (void)recursivelyClearContents;

/**
 * @abstract Toggle displaying a placeholder over the node that covers content until the node and all subnodes are
 * displayed.
 *
 * @discussion Defaults to NO.
 */
@property (nonatomic, assign) BOOL placeholderEnabled;

/**
 * @abstract Set the time it takes to fade out the placeholder when a node's contents are finished displaying.
 *
 * @discussion Defaults to 0 seconds.
 */
@property (nonatomic, assign) NSTimeInterval placeholderFadeDuration;

/**
 * @abstract Determines drawing priority of the node. Nodes with higher priority will be drawn earlier.
 *
 * @discussion Defaults to A_SDefaultDrawingPriority. There may be multiple drawing threads, and some of them may
 * decide to perform operations in queued order (regardless of drawingPriority)
 */
@property (atomic, assign) NSInteger drawingPriority;

/** @name Hit Testing */


/** 
 * @abstract Bounds insets for hit testing.
 *
 * @discussion When set to a non-zero inset, increases the bounds for hit testing to make it easier to tap or perform 
 * gestures on this node.  Default is UIEdgeInsetsZero.
 *
 * This affects the default implementation of -hitTest and -pointInside, so subclasses should call super if you override 
 * it and want hitTestSlop applied.
 */
@property (nonatomic, assign) UIEdgeInsets hitTestSlop;

/** 
 * @abstract Returns a Boolean value indicating whether the receiver contains the specified point.
 *
 * @discussion Includes the "slop" factor specified with hitTestSlop.
 *
 * @param point A point that is in the receiver's local coordinate system (bounds).
 * @param event The event that warranted a call to this method.
 *
 * @return YES if point is inside the receiver's bounds; otherwise, NO.
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event A_S_WARN_UNUSED_RESULT;


/** @name Converting Between View Coordinate Systems */


/** 
 * @abstract Converts a point from the receiver's coordinate system to that of the specified node.
 *
 * @param point A point specified in the local coordinate system (bounds) of the receiver.
 * @param node The node into whose coordinate system point is to be converted.
 *
 * @return The point converted to the coordinate system of node.
 */
- (CGPoint)convertPoint:(CGPoint)point toNode:(nullable A_SDisplayNode *)node A_S_WARN_UNUSED_RESULT;


/** 
 * @abstract Converts a point from the coordinate system of a given node to that of the receiver.
 *
 * @param point A point specified in the local coordinate system (bounds) of node.
 * @param node The node with point in its coordinate system.
 *
 * @return The point converted to the local coordinate system (bounds) of the receiver.
 */
- (CGPoint)convertPoint:(CGPoint)point fromNode:(nullable A_SDisplayNode *)node A_S_WARN_UNUSED_RESULT;


/** 
 * @abstract Converts a rectangle from the receiver's coordinate system to that of another view.
 *
 * @param rect A rectangle specified in the local coordinate system (bounds) of the receiver.
 * @param node The node that is the target of the conversion operation.
 *
 * @return The converted rectangle.
 */
- (CGRect)convertRect:(CGRect)rect toNode:(nullable A_SDisplayNode *)node A_S_WARN_UNUSED_RESULT;

/** 
 * @abstract Converts a rectangle from the coordinate system of another node to that of the receiver.
 *
 * @param rect A rectangle specified in the local coordinate system (bounds) of node.
 * @param node The node with rect in its coordinate system.
 *
 * @return The converted rectangle.
 */
- (CGRect)convertRect:(CGRect)rect fromNode:(nullable A_SDisplayNode *)node A_S_WARN_UNUSED_RESULT;

/**
 * Whether or not the node would support having .layerBacked = YES.
 */
@property (nonatomic, readonly) BOOL supportsLayerBacking;

@end

/**
 * Convenience methods for debugging.
 */
@interface A_SDisplayNode (Debugging) <A_SDebugNameProvider>

/**
 * Set to YES to tell all A_SDisplayNode instances to store their unflattened layouts.
 *
 * The layout can be accessed via `-unflattenedCalculatedLayout`.
 *
 * Flattened layouts use less memory and are faster to lookup. On the other hand, unflattened layouts are useful for debugging
 * because they preserve original information.
 */
+ (void)setShouldStoreUnflattenedLayouts:(BOOL)shouldStore;

/**
 * Whether or not A_SDisplayNode instances should store their unflattened layouts. 
 *
 * The layout can be accessed via `-unflattenedCalculatedLayout`.
 * 
 * Flattened layouts use less memory and are faster to lookup. On the other hand, unflattened layouts are useful for debugging
 * because they preserve original information.
 *
 * Defaults to NO.
 */
+ (BOOL)shouldStoreUnflattenedLayouts;

@property (nonatomic, strong, readonly, nullable) A_SLayout *unflattenedCalculatedLayout;

/**
 * @abstract Return a description of the node hierarchy.
 *
 * @discussion For debugging: (lldb) po [node displayNodeRecursiveDescription]
 */
- (NSString *)displayNodeRecursiveDescription A_S_WARN_UNUSED_RESULT;

/**
 * A detailed description of this node's layout state. This is useful when debugging.
 */
@property (atomic, copy, readonly) NSString *detailedLayoutDescription;

@end

/**
 * ## UIView bridge
 *
 * A_SDisplayNode provides thread-safe access to most of UIView and CALayer properties and methods, traditionally unsafe.
 *
 * Using them will not cause the actual view/layer to be created, and will be applied when it is created (when the view 
 * or layer property is accessed).
 *
 * - NOTE: After the view or layer is created, the properties pass through to the view or layer directly and must be called on the main thread.
 *
 * See UIView and CALayer for documentation on these common properties.
 */
@interface A_SDisplayNode (UIViewBridge)

/**
 * Marks the view as needing display. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 */
- (void)setNeedsDisplay;

/**
 * Marks the node as needing layout. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 *
 * If the node determines its own desired layout size will change in the next layout pass, it will propagate this
 * information up the tree so its parents can have a chance to consider and apply if necessary the new size onto the node.
 *
 * Note: A_SCellNode has special behavior in that calling this method will automatically notify
 * the containing A_STableView / A_SCollectionView that the cell should be resized, if necessary.
 */
- (void)setNeedsLayout;

/**
 * Performs a layout pass on the node. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 */
- (void)layoutIfNeeded;

@property (nonatomic, assign)           CGRect frame;                          // default=CGRectZero
@property (nonatomic, assign)           CGRect bounds;                         // default=CGRectZero
@property (nonatomic, assign)           CGPoint position;                      // default=CGPointZero
@property (nonatomic, assign)           CGFloat alpha;                         // default=1.0f

/* @abstract Sets the corner rounding method to use on the A_SDisplayNode.
 * There are three types of corner rounding provided by Tex_ture: CALayer, Precomposited, and Clipping.
 *
 * - A_SCornerRoundingTypeDefaultSlowCALayer: uses CALayer's inefficient .cornerRadius property. Use
 * this type of corner in situations in which there is both movement through and movement underneath
 * the corner (very rare). This uses only .cornerRadius.
 *
 * - A_SCornerRoundingTypePrecomposited: corners are drawn using bezier paths to clip the content in a
 * CGContext / UIGraphicsContext. This requires .backgroundColor and .cornerRadius to be set. Use opaque
 * background colors when possible for optimal efficiency, but transparent colors are supported and much
 * more efficient than CALayer. The only limitation of this approach is that it cannot clip children, and
 * thus works best for A_SImageNodes or containers showing a background around their children.
 *
 * - A_SCornerRoundingTypeClipping: overlays 4 seperate opaque corners on top of the content that needs
 * corner rounding. Requires .backgroundColor and .cornerRadius to be set. Use clip corners in situations 
 * in which is movement through the corner, with an opaque background (no movement underneath the corner).
 * Clipped corners are ideal for animating / resizing views, and still outperform CALayer.
 *
 * For more information and examples, see http://texturegroup.org/docs/corner-rounding.html
 *
 * @default A_SCornerRoundingTypeDefaultSlowCALayer
 */
@property (nonatomic, assign)           A_SCornerRoundingType cornerRoundingType;  // default=Slow CALayer .cornerRadius (offscreen rendering)
@property (nonatomic, assign)           CGFloat cornerRadius;                     // default=0.0

@property (nonatomic, assign)           BOOL clipsToBounds;                    // default==NO
@property (nonatomic, getter=isHidden)  BOOL hidden;                           // default==NO
@property (nonatomic, getter=isOpaque)  BOOL opaque;                           // default==YES

@property (nonatomic, strong, nullable) id contents;                           // default=nil
@property (nonatomic, assign)           CGRect contentsRect;                   // default={0,0,1,1}. @see CALayer.h for details.
@property (nonatomic, assign)           CGRect contentsCenter;                 // default={0,0,1,1}. @see CALayer.h for details.
@property (nonatomic, assign)           CGFloat contentsScale;                 // default=1.0f. See @contentsScaleForDisplay for details.
@property (nonatomic, assign)           CGFloat rasterizationScale;            // default=1.0f.

@property (nonatomic, assign)           CGPoint anchorPoint;                   // default={0.5, 0.5}
@property (nonatomic, assign)           CGFloat zPosition;                     // default=0.0
@property (nonatomic, assign)           CATransform3D transform;               // default=CATransform3DIdentity
@property (nonatomic, assign)           CATransform3D subnodeTransform;        // default=CATransform3DIdentity

@property (nonatomic, assign, getter=isUserInteractionEnabled) BOOL userInteractionEnabled; // default=YES (NO for layer-backed nodes)
#if TARGET_OS_IOS
@property (nonatomic, assign, getter=isExclusiveTouch) BOOL exclusiveTouch;    // default=NO
#endif

/**
 * @abstract The node view's background color.
 *
 * @discussion In contrast to UIView, setting a transparent color will not set opaque = NO.
 * This only affects nodes that implement +drawRect like A_STextNode.
*/
@property (nonatomic, strong, nullable) UIColor *backgroundColor;              // default=nil

@property (nonatomic, strong, null_resettable) UIColor *tintColor;             // default=Blue
- (void)tintColorDidChange;                                                    // Notifies the node when the tintColor has changed.

/**
 * @abstract A flag used to determine how a node lays out its content when its bounds change.
 *
 * @discussion This is like UIView's contentMode property, but better. We do our own mapping to layer.contentsGravity in 
 * _A_SDisplayView. You can set needsDisplayOnBoundsChange independently. 
 * Thus, UIViewContentModeRedraw is not allowed; use needsDisplayOnBoundsChange = YES instead, and pick an appropriate 
 * contentMode for your content while it's being re-rendered.
 */
@property (nonatomic, assign)           UIViewContentMode contentMode;         // default=UIViewContentModeScaleToFill
@property (nonatomic, copy)             NSString *contentsGravity;             // Use .contentMode in preference when possible.
@property (nonatomic, assign)           UISemanticContentAttribute semanticContentAttribute; // default=Unspecified

@property (nonatomic, nullable)         CGColorRef shadowColor;                // default=opaque rgb black
@property (nonatomic, assign)           CGFloat shadowOpacity;                 // default=0.0
@property (nonatomic, assign)           CGSize shadowOffset;                   // default=(0, -3)
@property (nonatomic, assign)           CGFloat shadowRadius;                  // default=3
@property (nonatomic, assign)           CGFloat borderWidth;                   // default=0
@property (nonatomic, nullable)         CGColorRef borderColor;                // default=opaque rgb black

@property (nonatomic, assign)           BOOL allowsGroupOpacity;
@property (nonatomic, assign)           BOOL allowsEdgeAntialiasing;
@property (nonatomic, assign)           unsigned int edgeAntialiasingMask;     // default==all values from CAEdgeAntialiasingMask

@property (nonatomic, assign)           BOOL needsDisplayOnBoundsChange;       // default==NO
@property (nonatomic, assign)           BOOL autoresizesSubviews;              // default==YES (undefined for layer-backed nodes)
@property (nonatomic, assign)           UIViewAutoresizing autoresizingMask;   // default==UIViewAutoresizingNone (undefined for layer-backed nodes)

// UIResponder methods
// By default these fall through to the underlying view, but can be overridden.
- (BOOL)canBecomeFirstResponder;                                            // default==NO
- (BOOL)becomeFirstResponder;                                               // default==NO (no-op)
- (BOOL)canResignFirstResponder;                                            // default==YES
- (BOOL)resignFirstResponder;                                               // default==NO (no-op)
- (BOOL)isFirstResponder;
- (BOOL)canPerformAction:(nonnull SEL)action withSender:(nonnull id)sender;

#if TARGET_OS_TV
//Focus Engine
- (void)setNeedsFocusUpdate;
- (BOOL)canBecomeFocused;
- (void)updateFocusIfNeeded;
- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator;
- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context;
- (nullable UIView *)preferredFocusedView;
#endif

@end

@interface A_SDisplayNode (UIViewBridgeAccessibility)

// Accessibility support
@property (nonatomic, assign)           BOOL isAccessibilityElement;
@property (nonatomic, copy, nullable)   NSString *accessibilityLabel;
@property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedLabel API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, copy, nullable)   NSString *accessibilityHint;
@property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedHint API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, copy, nullable)   NSString *accessibilityValue;
@property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedValue API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, assign)           UIAccessibilityTraits accessibilityTraits;
@property (nonatomic, assign)           CGRect accessibilityFrame;
@property (nonatomic, copy, nullable)   UIBezierPath *accessibilityPath;
@property (nonatomic, assign)           CGPoint accessibilityActivationPoint;
@property (nonatomic, copy, nullable)   NSString *accessibilityLanguage;
@property (nonatomic, assign)           BOOL accessibilityElementsHidden;
@property (nonatomic, assign)           BOOL accessibilityViewIsModal;
@property (nonatomic, assign)           BOOL shouldGroupAccessibilityChildren;
@property (nonatomic, assign)           UIAccessibilityNavigationStyle accessibilityNavigationStyle;
#if TARGET_OS_TV
@property(nonatomic, copy, nullable) 	NSArray *accessibilityHeaderElements;
#endif

// Accessibility identification support
@property (nonatomic, copy, nullable)   NSString *accessibilityIdentifier;

@end

@interface A_SDisplayNode (A_SLayoutElement) <A_SLayoutElement>

/**
 * @abstract Asks the node to return a layout based on given size range.
 *
 * @param constrainedSize The minimum and maximum sizes the receiver should fit in.
 *
 * @return An A_SLayout instance defining the layout of the receiver (and its children, if the box layout model is used).
 *
 * @discussion Though this method does not set the bounds of the view, it does have side effects--caching both the
 * constraint and the result.
 *
 * @warning Subclasses must not override this; it caches results from -calculateLayoutThatFits:.  Calling this method may
 * be expensive if result is not cached.
 *
 * @see [A_SDisplayNode(Subclassing) calculateLayoutThatFits:]
 */
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize;

@end

@interface A_SDisplayNode (A_SLayoutElementStylability) <A_SLayoutElementStylability>

@end

@interface A_SDisplayNode (A_SLayout)

/** @name Managing dimensions */

/**
 * @abstract Provides a way to declare a block to provide an A_SLayoutSpec without having to subclass A_SDisplayNode and
 * implement layoutSpecThatFits:
 *
 * @return A block that takes a constrainedSize A_SSizeRange argument, and must return an A_SLayoutSpec that includes all
 * of the subnodes to position in the layout. This input-output relationship is identical to the subclass override
 * method -layoutSpecThatFits:
 *
 * @warning Subclasses that implement -layoutSpecThatFits: must not also use .layoutSpecBlock. Doing so will trigger
 * an exception. A future version of the framework may support using both, calling them serially, with the
 * .layoutSpecBlock superseding any values set by the method override.
 *
 * @code ^A_SLayoutSpec *(__kindof A_SDisplayNode * _Nonnull node, A_SSizeRange constrainedSize) {};
 */
@property (nonatomic, readwrite, copy, nullable) A_SLayoutSpecBlock layoutSpecBlock;

/** 
 * @abstract Return the calculated size.
 *
 * @discussion Ideal for use by subclasses in -layout, having already prompted their subnodes to calculate their size by
 * calling -layoutThatFits: on them in -calculateLayoutThatFits.
 *
 * @return Size already calculated by -calculateLayoutThatFits:.
 *
 * @warning Subclasses must not override this; it returns the last cached measurement and is never expensive.
 */
@property (nonatomic, readonly, assign) CGSize calculatedSize;

/** 
 * @abstract Return the constrained size range used for calculating layout.
 *
 * @return The minimum and maximum constrained sizes used by calculateLayoutThatFits:.
 */
@property (nonatomic, readonly, assign) A_SSizeRange constrainedSizeForCalculatedLayout;


@end

@interface A_SDisplayNode (A_SLayoutTransitioning)

/**
 * @abstract The amount of time it takes to complete the default transition animation. Default is 0.2.
 */
@property (nonatomic, assign) NSTimeInterval defaultLayoutTransitionDuration;

/**
 * @abstract The amount of time (measured in seconds) to wait before beginning the default transition animation.
 *           Default is 0.0.
 */
@property (nonatomic, assign) NSTimeInterval defaultLayoutTransitionDelay;

/**
 * @abstract A mask of options indicating how you want to perform the default transition animations.
 *           For a list of valid constants, see UIViewAnimationOptions.
 */
@property (nonatomic, assign) UIViewAnimationOptions defaultLayoutTransitionOptions;

/**
 * @discussion A place to perform your animation. New nodes have been inserted here. You can also use this time to re-order the hierarchy.
 */
- (void)animateLayoutTransition:(nonnull id<A_SContextTransitioning>)context;

/**
 * @discussion A place to clean up your nodes after the transition
 */
- (void)didCompleteLayoutTransition:(nonnull id<A_SContextTransitioning>)context;

/**
 * @abstract Transitions the current layout with a new constrained size. Must be called on main thread.
 *
 * @param animated Animation is optional, but will still proceed through your `animateLayoutTransition` implementation with `isAnimated == NO`.
 * @param shouldMeasureAsync Measure the layout asynchronously.
 * @param completion Optional completion block called only if a new layout is calculated.
 * It is called on main, right after the measurement and before -animateLayoutTransition:.
 *
 * @discussion If the passed constrainedSize is the the same as the node's current constrained size, this method is noop. If passed YES to shouldMeasureAsync it's guaranteed that measurement is happening on a background thread, otherwise measaurement will happen on the thread that the method was called on. The measurementCompletion callback is always called on the main thread right after the measurement and before -animateLayoutTransition:.
 *
 * @see animateLayoutTransition:
 *
 */
- (void)transitionLayoutWithSizeRange:(A_SSizeRange)constrainedSize
                             animated:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(nullable void(^)(void))completion;


/**
 * @abstract Invalidates the layout and begins a relayout of the node with the current `constrainedSize`. Must be called on main thread.
 *
 * @discussion It is called right after the measurement and before -animateLayoutTransition:.
 *
 * @param animated Animation is optional, but will still proceed through your `animateLayoutTransition` implementation with `isAnimated == NO`.
 * @param shouldMeasureAsync Measure the layout asynchronously.
 * @param completion Optional completion block called only if a new layout is calculated.
 *
 * @see animateLayoutTransition:
 *
 */
- (void)transitionLayoutWithAnimation:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(nullable void(^)(void))completion;

/**
 * @abstract Cancels all performing layout transitions. Can be called on any thread.
 */
- (void)cancelLayoutTransition;

@end

/*
 * A_SDisplayNode support for automatic subnode management.
 */
@interface A_SDisplayNode (A_SAutomaticSubnodeManagement)

/**
 * @abstract A boolean that shows whether the node automatically inserts and removes nodes based on the presence or
 * absence of the node and its subnodes is completely determined in its layoutSpecThatFits: method.
 *
 * @discussion If flag is YES the node no longer require addSubnode: or removeFromSupernode method calls. The presence
 * or absence of subnodes is completely determined in its layoutSpecThatFits: method.
 */
@property (nonatomic, assign) BOOL automaticallyManagesSubnodes;

@end

/*
 * A_SDisplayNode participates in A_SAsyncTransactions, so you can determine when your subnodes are done rendering.
 * See: -(void)asyncdisplaykit_asyncTransactionContainerStateDidChange in A_SDisplayNodeSubclass.h
 */
@interface A_SDisplayNode (A_SAsyncTransactionContainer) <A_SAsyncTransactionContainer>
@end

/** UIVIew(Async_DisplayKit) defines convenience method for adding sub-A_SDisplayNode to an UIView. */
@interface UIView (Async_DisplayKit)
/**
 * Convenience method, equivalent to [view addSubview:node.view] or [view.layer addSublayer:node.layer] if layer-backed.
 *
 * @param node The node to be added.
 */
- (void)addSubnode:(nonnull A_SDisplayNode *)node;
@end

/*
 * CALayer(Async_DisplayKit) defines convenience method for adding sub-A_SDisplayNode to a CALayer.
 */
@interface CALayer (Async_DisplayKit)
/**
 * Convenience method, equivalent to [layer addSublayer:node.layer].
 *
 * @param node The node to be added.
 */
- (void)addSubnode:(nonnull A_SDisplayNode *)node;

@end

NS_ASSUME_NONNULL_END