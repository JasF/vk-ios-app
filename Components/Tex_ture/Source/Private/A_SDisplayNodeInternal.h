//
//  A_SDisplayNodeInternal.h
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

//
// The following methods are ONLY for use by _A_SDisplayLayer, _A_SDisplayView, and A_SDisplayNode.
// These methods must never be called or overridden by other classes.
//

#import <atomic>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>
#import <Async_DisplayKit/A_SLayoutElement.h>
#import <Async_DisplayKit/A_SLayoutTransition.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/_A_STransitionContext.h>
#import <Async_DisplayKit/A_SWeakSet.h>

NS_ASSUME_NONNULL_BEGIN

@protocol _A_SDisplayLayerDelegate;
@class _A_SDisplayLayer;
@class _A_SPendingState;
struct A_SDisplayNodeFlags;

BOOL A_SDisplayNodeSubclassOverridesSelector(Class subclass, SEL selector);
BOOL A_SDisplayNodeNeedsSpecialPropertiesHandling(BOOL isSynchronous, BOOL isLayerBacked);

/// Get the pending view state for the node, creating one if needed.
_A_SPendingState * A_SDisplayNodeGetPendingState(A_SDisplayNode * node);

typedef NS_OPTIONS(NSUInteger, A_SDisplayNodeMethodOverrides)
{
  A_SDisplayNodeMethodOverrideNone               = 0,
  A_SDisplayNodeMethodOverrideTouchesBegan       = 1 << 0,
  A_SDisplayNodeMethodOverrideTouchesCancelled   = 1 << 1,
  A_SDisplayNodeMethodOverrideTouchesEnded       = 1 << 2,
  A_SDisplayNodeMethodOverrideTouchesMoved       = 1 << 3,
  A_SDisplayNodeMethodOverrideLayoutSpecThatFits = 1 << 4,
  A_SDisplayNodeMethodOverrideCalcLayoutThatFits = 1 << 5,
  A_SDisplayNodeMethodOverrideCalcSizeThatFits   = 1 << 6,
};

typedef NS_OPTIONS(uint_least32_t, A_SDisplayNodeAtomicFlags)
{
  Synchronous = 1 << 0,
  YogaLayoutInProgress = 1 << 1,
};

#define checkFlag(flag) ((_atomicFlags.load() & flag) != 0)
// Returns the old value of the flag as a BOOL.
#define setFlag(flag, x) (((x ? _atomicFlags.fetch_or(flag) \
                              : _atomicFlags.fetch_and(~flag)) & flag) != 0)

FOUNDATION_EXPORT NSString * const A_SRenderingEngineDidDisplayScheduledNodesNotification;
FOUNDATION_EXPORT NSString * const A_SRenderingEngineDidDisplayNodesScheduledBeforeTimestamp;

// Allow 2^n increments of begin disabling hierarchy notifications
#define VISIBILITY_NOTIFICATIONS_DISABLED_BITS 4

#define TIME_DISPLAYNODE_OPS 0 // If you're using this information frequently, try: (DEBUG || PROFILE)

@interface A_SDisplayNode () <_A_STransitionContextCompletionDelegate>
{
@package
  _A_SPendingState *_pendingViewState;

  UIView *_view;
  CALayer *_layer;

  std::atomic<A_SDisplayNodeAtomicFlags> _atomicFlags;

  struct A_SDisplayNodeFlags {
    // public properties
    unsigned viewEverHadAGestureRecognizerAttached:1;
    unsigned layerBacked:1;
    unsigned displaysAsynchronously:1;
    unsigned rasterizesSubtree:1;
    unsigned shouldBypassEnsureDisplay:1;
    unsigned displaySuspended:1;
    unsigned shouldAnimateSizeChanges:1;
    
    // Wrapped view handling
    
    // The layer contents should not be cleared in case the node is wrapping a UIImageView.UIImageView is specifically
    // optimized for performance and does not use the usual way to provide the contents of the CALayer via the
    // CALayerDelegate method that backs the UIImageView.
    unsigned canClearContentsOfLayer:1;
    
    // Prevent calling setNeedsDisplay on a layer that backs a UIImageView. Usually calling setNeedsDisplay on a CALayer
    // triggers a recreation of the contents of layer unfortunately calling it on a CALayer that backs a UIImageView
    // it goes through the normal flow to assign the contents to a layer via the CALayerDelegate methods. Unfortunately
    // UIImageView does not do recreate the layer contents the usual way, it actually does not implement some of the
    // methods at all instead it throws away the contents of the layer and nothing will show up.
    unsigned canCallSetNeedsDisplayOfLayer:1;

    unsigned implementsDrawRect:1;
    unsigned implementsImageDisplay:1;
    unsigned implementsDrawParameters:1;

    // internal state
    unsigned isEnteringHierarchy:1;
    unsigned isExitingHierarchy:1;
    unsigned isInHierarchy:1;
    unsigned visibilityNotificationsDisabled:VISIBILITY_NOTIFICATIONS_DISABLED_BITS;
    unsigned isDeallocating:1;
  } _flags;
  
@protected
  A_SDisplayNode * __weak _supernode;
  NSMutableArray<A_SDisplayNode *> *_subnodes;

  // Set this to nil whenever you modify _subnodes
  NSArray<A_SDisplayNode *> *_cachedSubnodes;

  A_SLayoutElementStyle *_style;
  std::atomic<A_SPrimitiveTraitCollection> _primitiveTraitCollection;

  std::atomic_uint _displaySentinel;

  // This is the desired contentsScale, not the scale at which the layer's contents should be displayed
  CGFloat _contentsScaleForDisplay;
  A_SDisplayNodeMethodOverrides _methodOverrides;

  UIEdgeInsets _hitTestSlop;
  
#if A_SEVENTLOG_ENABLE
  A_SEventLog *_eventLog;
#endif
  
  // Main thread only
  BOOL _automaticallyManagesSubnodes;
  _A_STransitionContext *_pendingLayoutTransitionContext;
  NSTimeInterval _defaultLayoutTransitionDuration;
  NSTimeInterval _defaultLayoutTransitionDelay;
  UIViewAnimationOptions _defaultLayoutTransitionOptions;
  
  A_SLayoutSpecBlock _layoutSpecBlock;

  std::atomic<int32_t> _transitionID;
  
  std::atomic<int32_t> _pendingTransitionID;
  A_SLayoutTransition *_pendingLayoutTransition;
  std::shared_ptr<A_SDisplayNodeLayout> _calculatedDisplayNodeLayout;
  std::shared_ptr<A_SDisplayNodeLayout> _pendingDisplayNodeLayout;
  
  /// Sentinel for layout data. Incremented when we get -setNeedsLayout / -invalidateCalculatedLayout.
  /// Starts at 1.
  std::atomic<NSUInteger> _layoutVersion;
  
  A_SDisplayNodeViewBlock _viewBlock;
  A_SDisplayNodeLayerBlock _layerBlock;
  NSMutableArray<A_SDisplayNodeDidLoadBlock> *_onDidLoadBlocks;
  Class _viewClass; // nil -> _A_SDisplayView
  Class _layerClass; // nil -> _A_SDisplayLayer
  
  UIImage *_placeholderImage;
  BOOL _placeholderEnabled;
  CALayer *_placeholderLayer;

  // keeps track of nodes/subnodes that have not finished display, used with placeholders
  A_SWeakSet *_pendingDisplayNodes;
  
  CGFloat _cornerRadius;
  A_SCornerRoundingType _cornerRoundingType;
  CALayer *_clipCornerLayers[4];

  A_SDisplayNodeContextModifier _willDisplayNodeContentWithRenderingContext;
  A_SDisplayNodeContextModifier _didDisplayNodeContentWithRenderingContext;

  // Accessibility support
  BOOL _isAccessibilityElement;
  NSString *_accessibilityLabel;
  NSAttributedString *_accessibilityAttributedLabel;
  NSString *_accessibilityHint;
  NSAttributedString *_accessibilityAttributedHint;
  NSString *_accessibilityValue;
  NSAttributedString *_accessibilityAttributedValue;
  UIAccessibilityTraits _accessibilityTraits;
  CGRect _accessibilityFrame;
  NSString *_accessibilityLanguage;
  BOOL _accessibilityElementsHidden;
  BOOL _accessibilityViewIsModal;
  BOOL _shouldGroupAccessibilityChildren;
  NSString *_accessibilityIdentifier;
  UIAccessibilityNavigationStyle _accessibilityNavigationStyle;
  NSArray *_accessibilityHeaderElements;
  CGPoint _accessibilityActivationPoint;
  UIBezierPath *_accessibilityPath;
  BOOL _isAccessibilityContainer;

  // performance measurement
  A_SDisplayNodePerformanceMeasurementOptions _measurementOptions;
  NSTimeInterval _layoutSpecTotalTime;
  NSInteger _layoutSpecNumberOfPasses;
  NSTimeInterval _layoutComputationTotalTime;
  NSInteger _layoutComputationNumberOfPasses;

#if YOGA
  // Only A_SDisplayNodes are supported in _yogaChildren currently. This means that it is necessary to
  // create A_SDisplayNodes to make a stack layout when using Yoga.
  // However, the implementation is mostly ready for id <A_SLayoutElement>, with a few areas requiring updates.
  NSMutableArray<A_SDisplayNode *> *_yogaChildren;
  __weak A_SDisplayNode *_yogaParent;
  A_SLayout *_yogaCalculatedLayout;
#endif
  
  NSString *_debugName;

#pragma mark - A_SDisplayNode (Debugging)
  A_SLayout *_unflattenedLayout;

#if TIME_DISPLAYNODE_OPS
@public
  NSTimeInterval _debugTimeToCreateView;
  NSTimeInterval _debugTimeToApplyPendingState;
  NSTimeInterval _debugTimeToAddSubnodeViews;
  NSTimeInterval _debugTimeForDidLoad;
#endif
}

+ (void)scheduleNodeForRecursiveDisplay:(A_SDisplayNode *)node;

/// The _A_SDisplayLayer backing the node, if any.
@property (nullable, nonatomic, readonly, strong) _A_SDisplayLayer *asyncLayer;

/// Bitmask to check which methods an object overrides.
@property (nonatomic, assign, readonly) A_SDisplayNodeMethodOverrides methodOverrides;

/**
 * Invoked before a call to setNeedsLayout to the underlying view
 */
- (void)__setNeedsLayout;

/**
 * Invoked after a call to setNeedsDisplay to the underlying view
 */
- (void)__setNeedsDisplay;

/**
 * Called whenever the node needs to layout its subnodes and, if it's already loaded, its subviews. Executes the layout pass for the node
 *
 * This method is thread-safe but asserts thread affinity.
 */
- (void)__layout;

/**
 * Internal method to add / replace / insert subnode and remove from supernode without checking if
 * node has automaticallyManagesSubnodes set to YES.
 */
- (void)_addSubnode:(A_SDisplayNode *)subnode;
- (void)_replaceSubnode:(A_SDisplayNode *)oldSubnode withSubnode:(A_SDisplayNode *)replacementSubnode;
- (void)_insertSubnode:(A_SDisplayNode *)subnode belowSubnode:(A_SDisplayNode *)below;
- (void)_insertSubnode:(A_SDisplayNode *)subnode aboveSubnode:(A_SDisplayNode *)above;
- (void)_insertSubnode:(A_SDisplayNode *)subnode atIndex:(NSInteger)idx;
- (void)_removeFromSupernodeIfEqualTo:(A_SDisplayNode *)supernode;
- (void)_removeFromSupernode;

// Private API for helper functions / unit tests.  Use A_SDisplayNodeDisableHierarchyNotifications() to control this.
- (BOOL)__visibilityNotificationsDisabled;
- (BOOL)__selfOrParentHasVisibilityNotificationsDisabled;
- (void)__incrementVisibilityNotificationsDisabled;
- (void)__decrementVisibilityNotificationsDisabled;

/// Helper method to summarize whether or not the node run through the display process
- (BOOL)_implementsDisplay;

/// Display the node's view/layer immediately on the current thread, bypassing the background thread rendering. Will be deprecated.
- (void)displayImmediately;

/// Refreshes any precomposited or drawn clip corners, setting up state as required to transition radius or rounding type.
- (void)updateCornerRoundingWithType:(A_SCornerRoundingType)newRoundingType cornerRadius:(CGFloat)newCornerRadius;

/// Alternative initialiser for backing with a custom view class.  Supports asynchronous display with _A_SDisplayView subclasses.
- (instancetype)initWithViewClass:(Class)viewClass;

/// Alternative initialiser for backing with a custom layer class.  Supports asynchronous display with _A_SDisplayLayer subclasses.
- (instancetype)initWithLayerClass:(Class)layerClass;

@property (nonatomic, assign) CGFloat contentsScaleForDisplay;

- (void)applyPendingViewState;

/**
 * // TODO: NOT YET IMPLEMENTED
 *
 * @abstract Prevents interface state changes from affecting the node, until disabled.
 *
 * @discussion Useful to avoid flashing after removing a node from the hierarchy and re-adding it.
 * Removing a node from the hierarchy will cause it to exit the Display state, clearing its contents.
 * For some animations, it's desirable to be able to remove a node without causing it to re-display.
 * Once re-enabled, the interface state will be updated to the same value it would have been.
 *
 * @see A_SInterfaceState
 */
@property (nonatomic, assign) BOOL interfaceStateSuspended;

/**
 * This method has proven helpful in a few rare scenarios, similar to a category extension on UIView,
 * but it's considered private API for now and its use should not be encouraged.
 * @param checkViewHierarchy If YES, and no supernode can be found, method will walk up from `self.view` to find a supernode.
 * If YES, this method must be called on the main thread and the node must not be layer-backed.
 */
- (nullable A_SDisplayNode *)_supernodeWithClass:(Class)supernodeClass checkViewHierarchy:(BOOL)checkViewHierarchy;

/**
 * Whether this node rasterizes its descendants. See -enableSubtreeRasterization.
 */
@property (atomic, readonly) BOOL rasterizesSubtree;

/**
 * Called if a gesture recognizer was attached to an _A_SDisplayView
 */
- (void)nodeViewDidAddGestureRecognizer;

@end

@interface A_SDisplayNode (InternalPropertyBridge)

@property (nonatomic, assign) CGFloat layerCornerRadius;

@end

NS_ASSUME_NONNULL_END
