//
//  A_SDisplayNode+Beta.h
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

#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayoutRangeType.h>
#import <Async_DisplayKit/A_SEventLog.h>

#if YOGA
  #import YOGA_HEADER_PATH
  #import <Async_DisplayKit/A_SYogaUtilities.h>
#endif

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN
void A_SPerformBlockOnMainThread(void (^block)(void));
void A_SPerformBlockOnBackgroundThread(void (^block)(void)); // DISPATCH_QUEUE_PRIORITY_DEFAULT
A_SDISPLAYNODE_EXTERN_C_END

#if A_SEVENTLOG_ENABLE
  #define A_SDisplayNodeLogEvent(node, ...) [node.eventLog logEventWithBacktrace:(A_S_SAVE_EVENT_BACKTRACES ? [NSThread callStackSymbols] : nil) format:__VA_ARGS__]
#else
  #define A_SDisplayNodeLogEvent(node, ...)
#endif

#if A_SEVENTLOG_ENABLE
  #define A_SDisplayNodeGetEventLog(node) node.eventLog
#else
  #define A_SDisplayNodeGetEventLog(node) nil
#endif

/**
 * Bitmask to indicate what performance measurements the cell should record.
 */
typedef NS_OPTIONS(NSUInteger, A_SDisplayNodePerformanceMeasurementOptions) {
  A_SDisplayNodePerformanceMeasurementOptionLayoutSpec = 1 << 0,
  A_SDisplayNodePerformanceMeasurementOptionLayoutComputation = 1 << 1
};

typedef struct {
  CFTimeInterval layoutSpecTotalTime;
  NSInteger layoutSpecNumberOfPasses;
  CFTimeInterval layoutComputationTotalTime;
  NSInteger layoutComputationNumberOfPasses;
} A_SDisplayNodePerformanceMeasurements;

@interface A_SDisplayNode (Beta)

/**
 * @abstract Recursively ensures node and all subnodes are displayed.
 * @see Full documentation in A_SDisplayNode+FrameworkPrivate.h
 */
- (void)recursivelyEnsureDisplaySynchronously:(BOOL)synchronously;

/**
 * @abstract allow modification of a context before the node's content is drawn
 *
 * @discussion Set the block to be called after the context has been created and before the node's content is drawn.
 * You can override this to modify the context before the content is drawn. You are responsible for saving and
 * restoring context if necessary. Restoring can be done in contextDidDisplayNodeContent
 * This block can be called from *any* thread and it is unsafe to access any UIKit main thread properties from it.
 */
@property (nonatomic, copy, nullable) A_SDisplayNodeContextModifier willDisplayNodeContentWithRenderingContext;

/**
 * @abstract allow modification of a context after the node's content is drawn
 */
@property (nonatomic, copy, nullable) A_SDisplayNodeContextModifier didDisplayNodeContentWithRenderingContext;

/**
 * @abstract A bitmask representing which actions (layout spec, layout generation) should be measured.
 */
@property (nonatomic, assign) A_SDisplayNodePerformanceMeasurementOptions measurementOptions;

/**
 * @abstract A simple struct representing performance measurements collected.
 */
@property (nonatomic, assign, readonly) A_SDisplayNodePerformanceMeasurements performanceMeasurements;

#if A_SEVENTLOG_ENABLE
/*
 * @abstract The primitive event tracing object. You shouldn't directly use it to log event. Use the A_SDisplayNodeLogEvent macro instead.
 */
@property (nonatomic, strong, readonly) A_SEventLog *eventLog;
#endif

/**
 * @abstract Whether this node acts as an accessibility container. If set to YES, then this node's accessibility label will represent
 * an aggregation of all child nodes' accessibility labels. Nodes in this node's subtree that are also accessibility containers will
 * not be included in this aggregation, and will be exposed as separate accessibility elements to UIKit.
 */
@property (nonatomic, assign) BOOL isAccessibilityContainer;

/**
 * @abstract Invoked when a user performs a custom action on an accessible node. Nodes that are children of accessibility containers, have
 * an accessibity label and have an interactive UIAccessibilityTrait will automatically receive custom-action handling.
 */
- (void)performAccessibilityCustomAction:(UIAccessibilityCustomAction *)action;

/**
 * @abstract Currently used by A_SNetworkImageNode and A_SMultiplexImageNode to allow their placeholders to stay if they are loading an image from the network.
 * Otherwise, a display pass is scheduled and completes, but does not actually draw anything - and A_SDisplayNode considers the element finished.
 */
- (BOOL)placeholderShouldPersist A_S_WARN_UNUSED_RESULT;

/**
 * @abstract Indicates that the receiver and all subnodes have finished displaying. May be called more than once, for example if the receiver has
 * a network image node. This is called after the first display pass even if network image nodes have not downloaded anything (text would be done,
 * and other nodes that are ready to do their final display). Each render of every progressive jpeg network node would cause this to be called, so
 * this hook could be called up to 1 + (pJPEGcount * pJPEGrenderCount) times. The render count depends on how many times the downloader calls the
 * progressImage block.
 */
- (void)hierarchyDisplayDidFinish;

/**
 * Only A_SLayoutRangeModeVisibleOnly or A_SLayoutRangeModeLowMemory are recommended.  Default is A_SLayoutRangeModeVisibleOnly,
 * because this is the only way to ensure an application will not have blank / flashing views as the user navigates back after
 * a memory warning.  Apps that wish to use the more effective / aggressive A_SLayoutRangeModeLowMemory may need to take steps
 * to mitigate this behavior, including: restoring a larger range mode to the next controller before the user navigates there,
 * enabling .neverShowPlaceholders on A_SCellNodes so that the navigation operation is blocked on redisplay completing, etc.
 */
+ (void)setRangeModeForMemoryWarnings:(A_SLayoutRangeMode)rangeMode;

/**
 * @abstract Whether to draw all descendent nodes' contents into this node's layer's backing store.
 *
 * @discussion
 * When called, causes all descendent nodes' contents to be drawn directly into this node's layer's backing
 * store.
 *
 * If a node's descendants are static (never animated or never change attributes after creation) then that node is a
 * good candidate for rasterization.  Rasterizing descendants has two main benefits:
 * 1) Backing stores for descendant layers are not created.  Instead the layers are drawn directly into the rasterized
 * container.  This can save a great deal of memory.
 * 2) Since the entire subtree is drawn into one backing store, compositing and blending are eliminated in that subtree
 * which can help improve animation/scrolling/etc performance.
 *
 * Rasterization does not currently support descendants with transform, sublayerTransform, or alpha. Those properties
 * will be ignored when rasterizing descendants.
 *
 * Note: this has nothing to do with -[CALayer shouldRasterize], which doesn't work with A_SDisplayNode's asynchronous
 * rendering model.
 *
 * Note: You cannot add subnodes whose layers/views are already loaded to a rasterized node.
 * Note: You cannot call this method after the receiver's layer/view is loaded.
 */
- (void)enableSubtreeRasterization;

@end

#pragma mark - Yoga Layout Support

#if YOGA

extern void A_SDisplayNodePerformBlockOnEveryYogaChild(A_SDisplayNode * _Nullable node, void(^block)(A_SDisplayNode *node));

@interface A_SDisplayNode (Yoga)

@property (nonatomic, strong, nullable) NSArray *yogaChildren;

- (void)addYogaChild:(A_SDisplayNode *)child;
- (void)removeYogaChild:(A_SDisplayNode *)child;
- (void)insertYogaChild:(A_SDisplayNode *)child atIndex:(NSUInteger)index;

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute;

@property (nonatomic, assign) BOOL yogaLayoutInProgress;
@property (nonatomic, strong, nullable) A_SLayout *yogaCalculatedLayout;

// These methods are intended to be used internally to Tex_ture, and should not be called directly.
- (BOOL)shouldHaveYogaMeasureFunc;
- (void)invalidateCalculatedYogaLayout;
- (void)calculateLayoutFromYogaRoot:(A_SSizeRange)rootConstrainedSize;

@end

@interface A_SLayoutElementStyle (Yoga)

- (YGNodeRef)yogaNodeCreateIfNeeded;
@property (nonatomic, assign, readonly) YGNodeRef yogaNode;

@property (nonatomic, assign, readwrite) A_SStackLayoutDirection flexDirection;
@property (nonatomic, assign, readwrite) YGDirection direction;
@property (nonatomic, assign, readwrite) A_SStackLayoutJustifyContent justifyContent;
@property (nonatomic, assign, readwrite) A_SStackLayoutAlignItems alignItems;
@property (nonatomic, assign, readwrite) YGPositionType positionType;
@property (nonatomic, assign, readwrite) A_SEdgeInsets position;
@property (nonatomic, assign, readwrite) A_SEdgeInsets margin;
@property (nonatomic, assign, readwrite) A_SEdgeInsets padding;
@property (nonatomic, assign, readwrite) A_SEdgeInsets border;
@property (nonatomic, assign, readwrite) CGFloat aspectRatio;
@property (nonatomic, assign, readwrite) YGWrap flexWrap;

@end

#endif

NS_ASSUME_NONNULL_END
