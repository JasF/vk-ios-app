//
//  A_SDisplayNodeTests.mm
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

#import <QuartzCore/QuartzCore.h>

#import "A_SXCTExtensions.h"
#import <XCTest/XCTest.h>

#import <Async_DisplayKit/_A_SDisplayLayer.h>
#import <Async_DisplayKit/_A_SDisplayView.h>
#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import "A_SDisplayNodeTestsHelper.h"
#import <Async_DisplayKit/UIView+A_SConvenience.h>
#import <Async_DisplayKit/A_SCellNode.h>
#import <Async_DisplayKit/A_SImageNode.h>
#import <Async_DisplayKit/A_SOverlayLayoutSpec.h>
#import <Async_DisplayKit/A_SInsetLayoutSpec.h>
#import <Async_DisplayKit/A_SCenterLayoutSpec.h>
#import <Async_DisplayKit/A_SBackgroundLayoutSpec.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+Beta.h>

// Conveniences for making nodes named a certain way
#define DeclareNodeNamed(n) A_SDisplayNode *n = [[A_SDisplayNode alloc] init]; n.debugName = @#n
#define DeclareViewNamed(v) \
    A_SDisplayNode *node_##v = [[A_SDisplayNode alloc] init]; \
    node_##v.debugName = @#v; \
    UIView *v = node_##v.view;
#define DeclareLayerNamed(l) \
   A_SDisplayNode *node_##l = [[A_SDisplayNode alloc] init]; \
   node_##l.debugName = @#l; \
   node_##l.layerBacked = YES; \
   CALayer *l = node_##l.layer;

static NSString *orderStringFromSublayers(CALayer *l) {
  return [[[l.sublayers valueForKey:@"asyncdisplaykit_node"] valueForKey:@"debugName"] componentsJoinedByString:@","];
}

static NSString *orderStringFromSubviews(UIView *v) {
  return [[[v.subviews valueForKey:@"asyncdisplaykit_node"] valueForKey:@"debugName"] componentsJoinedByString:@","];
}

static NSString *orderStringFromSubnodes(A_SDisplayNode *n) {
  return [[n.subnodes valueForKey:@"debugName"] componentsJoinedByString:@","];
}

// Asserts subnode, subview, sublayer order match what you provide here
#define XCTAssertNodeSubnodeSubviewSublayerOrder(n, loaded, isLayerBacked, order, description) \
XCTAssertEqualObjects(orderStringFromSubnodes(n), order, @"Incorrect node order for "  description );\
if (loaded) {\
  if (!isLayerBacked) {\
    XCTAssertEqualObjects(orderStringFromSubviews(n.view), order, @"Incorrect subviews for " description);\
  }\
  XCTAssertEqualObjects(orderStringFromSublayers(n.layer), order, @"Incorrect sublayers for " description);\
}

#define XCTAssertNodesHaveParent(parent, nodes ...) \
for (A_SDisplayNode *n in @[ nodes ]) {\
  XCTAssertEqualObjects(parent, n.supernode, @"%@ has the wrong parent", n.debugName);\
}

#define XCTAssertNodesLoaded(nodes ...) \
for (A_SDisplayNode *n in @[ nodes ]) {\
  XCTAssertTrue(n.nodeLoaded, @"%@ should be loaded", n.debugName);\
}

#define XCTAssertNodesNotLoaded(nodes ...) \
for (A_SDisplayNode *n in @[ nodes ]) {\
  XCTAssertFalse(n.nodeLoaded, @"%@ should not be loaded", n.debugName);\
}


@interface A_SDisplayNode (HackForTests)
- (id)initWithViewClass:(Class)viewClass;
- (id)initWithLayerClass:(Class)layerClass;

// FIXME: Importing A_SDisplayNodeInternal.h causes a heap of problems.
- (void)enterInterfaceState:(A_SInterfaceState)interfaceState;
@end

@interface A_STestDisplayNode : A_SDisplayNode
@property (nonatomic, copy) void (^willDeallocBlock)(__unsafe_unretained A_STestDisplayNode *node);
@property (nonatomic, copy) CGSize(^calculateSizeBlock)(A_STestDisplayNode *node, CGSize size);

@property (nonatomic, nullable) UIGestureRecognizer *gestureRecognizer;
@property (nonatomic, nullable) id idGestureRecognizer;
@property (nonatomic, nullable) UIImage *bigImage;
@property (nonatomic, nullable) NSArray *randomProperty;

@property (nonatomic) BOOL displayRangeStateChangedToYES;
@property (nonatomic) BOOL displayRangeStateChangedToNO;

@property (nonatomic) BOOL hasPreloaded;
@property (nonatomic) BOOL preloadStateChangedToYES;
@property (nonatomic) BOOL preloadStateChangedToNO;

@property (nonatomic, assign) NSUInteger displayWillStartCount;
@property (nonatomic, assign) NSUInteger didDisplayCount;

@end

@interface A_STestResponderNode : A_STestDisplayNode
@end

@implementation A_STestDisplayNode

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  return _calculateSizeBlock ? _calculateSizeBlock(self, constrainedSize) : CGSizeZero;
}

- (void)didEnterDisplayState
{
  [super didEnterDisplayState];
  self.displayRangeStateChangedToYES = YES;
}

- (void)didExitDisplayState
{
  [super didExitDisplayState];
  self.displayRangeStateChangedToNO = YES;
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  self.preloadStateChangedToYES = YES;
  self.hasPreloaded = YES;
}

- (void)didExitPreloadState
{
  [super didExitPreloadState];
  self.preloadStateChangedToNO = YES;
}

- (void)dealloc
{
  if (_willDeallocBlock) {
    _willDeallocBlock(self);
  }
}

- (void)displayDidFinish
{
  [super displayDidFinish];
  _didDisplayCount++;
}

- (void)displayWillStartAsynchronously:(BOOL)asynchronously
{
  [super displayWillStartAsynchronously:asynchronously];
  _displayWillStartCount++;
}

@end

@interface UIDisplayNodeTestView : UIView
@end

@interface UIResponderNodeTestView : _A_SDisplayView
@property(nonatomic) BOOL testIsFirstResponder;
@end

@implementation UIDisplayNodeTestView
@end

@interface A_STestWindow : UIWindow
@end

@implementation A_STestWindow

- (id)firstResponder {
  return self.subviews.firstObject;
}

@end

@implementation A_STestResponderNode

+ (Class)viewClass {
  return [UIResponderNodeTestView class];
}

- (BOOL)canBecomeFirstResponder {
  return YES;
}

@end

@implementation UIResponderNodeTestView

- (BOOL)becomeFirstResponder {
  self.testIsFirstResponder = YES;
  return YES;
}

- (BOOL)canResignFirstResponder {
  return YES;
}

- (BOOL)resignFirstResponder {
  [super resignFirstResponder];
  if (self.testIsFirstResponder) {
    self.testIsFirstResponder = NO;
    return YES;
  }
  return NO;
}

@end

@interface A_SDisplayNodeTests : XCTestCase
@end

@implementation A_SDisplayNodeTests
{
  dispatch_queue_t queue;
}

- (void)testOverriddenFirstResponderBehavior {
  A_STestDisplayNode *node = [[A_STestResponderNode alloc] init];
  XCTAssertTrue([node canBecomeFirstResponder]);
  XCTAssertTrue([node becomeFirstResponder]);
}

- (void)testDefaultFirstResponderBehavior {
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  XCTAssertFalse([node canBecomeFirstResponder]);
  XCTAssertFalse([node becomeFirstResponder]);
}

- (void)setUp
{
  [super setUp];
  queue = dispatch_queue_create("com.facebook.Async_DisplayKit.A_SDisplayNodeTestsQueue", NULL);
}

- (void)testViewCreatedOffThreadCanBeRealizedOnThread
{
  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] init];
  }];

  UIView *view = node.view;
  XCTAssertNotNil(view, @"Getting node's view on-thread should succeed.");
}

- (void)testNodeCreatedOffThreadWithExistingView
{
  UIView *view = [[UIDisplayNodeTestView alloc] init];

  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] initWithViewBlock:^UIView *{
      return view;
    }];
  }];

  XCTAssertFalse(node.layerBacked, @"Can't be layer backed");
  XCTAssertTrue(node.synchronous, @"Node with plain view should be synchronous");
  XCTAssertFalse(node.nodeLoaded, @"Shouldn't have a view yet");
  XCTAssertEqual(view, node.view, @"Getting node's view on-thread should succeed.");
}

- (void)testNodeCreatedOffThreadWithLazyView
{
  __block UIView *view = nil;
  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] initWithViewBlock:^UIView *{
      XCTAssertTrue([NSThread isMainThread], @"View block must run on the main queue");
      view = [[UIDisplayNodeTestView alloc] init];
      return view;
    }];
  }];

  XCTAssertNil(view, @"View block should not be invoked yet");
  [node view];
  XCTAssertNotNil(view, @"View block should have been invoked");
  XCTAssertEqual(view, node.view, @"Getting node's view on-thread should succeed.");
  XCTAssertTrue(node.synchronous, @"Node with plain view should be synchronous");
}

- (void)testNodeCreatedWithLazyAsyncView
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] initWithViewBlock:^UIView *{
    XCTAssertTrue([NSThread isMainThread], @"View block must run on the main queue");
    return [[_A_SDisplayView alloc] init];
  }];

  XCTAssertThrows([node view], @"Externally provided views should be synchronous");
  XCTAssertTrue(node.synchronous, @"Node with externally provided view should be synchronous");
}

- (void)checkValuesMatchDefaults:(A_SDisplayNode *)node isLayerBacked:(BOOL)isLayerBacked
{
  NSString *targetName = isLayerBacked ? @"layer" : @"view";
  NSString *hasLoadedView = node.nodeLoaded ? @"with view" : [NSString stringWithFormat:@"after loading %@", targetName];

//  id rgbBlackCGColorIdPtr = (id)[UIColor blackColor].CGColor;

  XCTAssertEqual((id)nil, node.contents, @"default contents broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.clipsToBounds, @"default clipsToBounds broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.opaque, @"default opaque broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.needsDisplayOnBoundsChange, @"default needsDisplayOnBoundsChange broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.allowsGroupOpacity, @"default allowsGroupOpacity broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.allowsEdgeAntialiasing, @"default allowsEdgeAntialiasing broken %@", hasLoadedView);
  XCTAssertEqual((unsigned int)(kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge), node.edgeAntialiasingMask, @"default edgeAntialisingMask broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.hidden, @"default hidden broken %@", hasLoadedView);
  XCTAssertEqual(1.0f, node.alpha, @"default alpha broken %@", hasLoadedView);
  XCTAssertTrue(CGRectEqualToRect(CGRectZero, node.bounds), @"default bounds broken %@", hasLoadedView);
  XCTAssertTrue(CGRectEqualToRect(CGRectZero, node.frame), @"default frame broken %@", hasLoadedView);
  XCTAssertTrue(CGPointEqualToPoint(CGPointZero, node.position), @"default position broken %@", hasLoadedView);
  XCTAssertEqual((CGFloat)0.0, node.zPosition, @"default zPosition broken %@", hasLoadedView);
  XCTAssertEqual(1.0f, node.contentsScale, @"default contentsScale broken %@", hasLoadedView);
  XCTAssertEqual([UIScreen mainScreen].scale, node.contentsScaleForDisplay, @"default contentsScaleForDisplay broken %@", hasLoadedView);
  XCTAssertTrue(CATransform3DEqualToTransform(CATransform3DIdentity, node.transform), @"default transform broken %@", hasLoadedView);
  XCTAssertTrue(CATransform3DEqualToTransform(CATransform3DIdentity, node.subnodeTransform), @"default subnodeTransform broken %@", hasLoadedView);
  XCTAssertEqual((id)nil, node.backgroundColor, @"default backgroundColor broken %@", hasLoadedView);
  XCTAssertEqual(UIViewContentModeScaleToFill, node.contentMode, @"default contentMode broken %@", hasLoadedView);
//  XCTAssertEqualObjects(rgbBlackCGColorIdPtr, (id)node.shadowColor, @"default shadowColor broken %@", hasLoadedView);
  XCTAssertEqual(0.0f, node.shadowOpacity, @"default shadowOpacity broken %@", hasLoadedView);
  XCTAssertTrue(CGSizeEqualToSize(CGSizeMake(0, -3), node.shadowOffset), @"default shadowOffset broken %@", hasLoadedView);
  XCTAssertEqual(3.f, node.shadowRadius, @"default shadowRadius broken %@", hasLoadedView);
  XCTAssertEqual(0.0f, node.borderWidth, @"default borderWidth broken %@", hasLoadedView);
//  XCTAssertEqualObjects(rgbBlackCGColorIdPtr, (id)node.borderColor, @"default borderColor broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.displaySuspended, @"default displaySuspended broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.displaysAsynchronously, @"default displaysAsynchronously broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.asyncdisplaykit_asyncTransactionContainer, @"default asyncdisplaykit_asyncTransactionContainer broken %@", hasLoadedView);
  XCTAssertEqualObjects(nil, node.debugName, @"default name broken %@", hasLoadedView);
  
  XCTAssertEqual(NO, node.isAccessibilityElement, @"default isAccessibilityElement is broken %@", hasLoadedView);
  XCTAssertEqual((id)nil, node.accessibilityLabel, @"default accessibilityLabel is broken %@", hasLoadedView);
  XCTAssertEqual((id)nil, node.accessibilityHint, @"default accessibilityHint is broken %@", hasLoadedView);
  XCTAssertEqual((id)nil, node.accessibilityValue, @"default accessibilityValue is broken %@", hasLoadedView);
//  if (A_S_AT_LEA_ST_IOS11) {
//    XCTAssertEqual((id)nil, node.accessibilityAttributedLabel, @"default accessibilityAttributedLabel is broken %@", hasLoadedView);
//    XCTAssertEqual((id)nil, node.accessibilityAttributedHint, @"default accessibilityAttributedHint is broken %@", hasLoadedView);
//    XCTAssertEqual((id)nil, node.accessibilityAttributedValue, @"default accessibilityAttributedValue is broken %@", hasLoadedView);
//  }
  XCTAssertEqual(UIAccessibilityTraitNone, node.accessibilityTraits, @"default accessibilityTraits is broken %@", hasLoadedView);
  XCTAssertTrue(CGRectEqualToRect(CGRectZero, node.accessibilityFrame), @"default accessibilityFrame is broken %@", hasLoadedView);
  XCTAssertEqual((id)nil, node.accessibilityLanguage, @"default accessibilityLanguage is broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.accessibilityElementsHidden, @"default accessibilityElementsHidden is broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.accessibilityViewIsModal, @"default accessibilityViewIsModal is broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.shouldGroupAccessibilityChildren, @"default shouldGroupAccessibilityChildren is broken %@", hasLoadedView);

  if (!isLayerBacked) {
    XCTAssertEqual(YES, node.userInteractionEnabled, @"default userInteractionEnabled broken %@", hasLoadedView);
    XCTAssertEqual(NO, node.exclusiveTouch, @"default exclusiveTouch broken %@", hasLoadedView);
    XCTAssertEqual(YES, node.autoresizesSubviews, @"default autoresizesSubviews broken %@", hasLoadedView);
    XCTAssertEqual(UIViewAutoresizingNone, node.autoresizingMask, @"default autoresizingMask broken %@", hasLoadedView);
  } else {
    XCTAssertEqual(NO, node.userInteractionEnabled, @"layer-backed nodes do not support userInteractionEnabled %@", hasLoadedView);
    XCTAssertEqual(NO, node.exclusiveTouch, @"layer-backed nodes do not support exclusiveTouch %@", hasLoadedView);
  }
}

- (void)checkDefaultPropertyValuesWithLayerBacking:(BOOL)isLayerBacked
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];

  XCTAssertEqual(NO, node.isLayerBacked, @"default isLayerBacked broken without view");
  node.layerBacked = isLayerBacked;
  XCTAssertEqual(isLayerBacked, node.isLayerBacked, @"setIsLayerBacked: broken");

  // Assert that the values can be fetched from the node before the view is realized.
  [self checkValuesMatchDefaults:node isLayerBacked:isLayerBacked];

  [node layer]; // Force either view or layer loading
  XCTAssertTrue(node.nodeLoaded, @"Didn't load view");

  // Assert that the values can be fetched from the node after the view is realized.
  [self checkValuesMatchDefaults:node isLayerBacked:isLayerBacked];
}

- (void)testDefaultPropertyValuesLayer
{
  [self checkDefaultPropertyValuesWithLayerBacking:YES];
}

- (void)testDefaultPropertyValuesView
{
  [self checkDefaultPropertyValuesWithLayerBacking:NO];
}

- (UIImage *)bogusImage
{
  static UIImage *bogusImage;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    UIGraphicsBeginImageContext(CGSizeMake(1, 1));
    bogusImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
  });
  return bogusImage;
}

- (void)checkValuesMatchSetValues:(A_SDisplayNode *)node isLayerBacked:(BOOL)isLayerBacked
{
  NSString *targetName = isLayerBacked ? @"layer" : @"view";
  NSString *hasLoadedView = node.nodeLoaded ? @"with view" : [NSString stringWithFormat:@"after loading %@", targetName];

  XCTAssertEqual(isLayerBacked, node.isLayerBacked, @"isLayerBacked broken %@", hasLoadedView);
  XCTAssertEqualObjects((id)[self bogusImage].CGImage, (id)node.contents, @"contents broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.clipsToBounds, @"clipsToBounds broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.opaque, @"opaque broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.needsDisplayOnBoundsChange, @"needsDisplayOnBoundsChange broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.allowsGroupOpacity, @"allowsGroupOpacity broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.allowsEdgeAntialiasing, @"allowsEdgeAntialiasing broken %@", hasLoadedView);
  XCTAssertTrue((unsigned int)(kCALayerLeftEdge | kCALayerTopEdge) == node.edgeAntialiasingMask, @"edgeAntialiasingMask broken: %@", hasLoadedView);
  XCTAssertEqual(YES, node.hidden, @"hidden broken %@", hasLoadedView);
  XCTAssertEqual(.5f, node.alpha, @"alpha broken %@", hasLoadedView);
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(10, 15, 42, 115.2), node.bounds), @"bounds broken %@", hasLoadedView);
  XCTAssertTrue(CGPointEqualToPoint(CGPointMake(10, 65), node.position), @"position broken %@", hasLoadedView);
  XCTAssertEqual((CGFloat)5.6, node.zPosition, @"zPosition broken %@", hasLoadedView);
  XCTAssertEqual(.5f, node.contentsScale, @"contentsScale broken %@", hasLoadedView);
  XCTAssertTrue(CATransform3DEqualToTransform(CATransform3DMakeScale(0.5, 0.5, 1.0), node.transform), @"transform broken %@", hasLoadedView);
  XCTAssertTrue(CATransform3DEqualToTransform(CATransform3DMakeTranslation(1337, 7357, 7007), node.subnodeTransform), @"subnodeTransform broken %@", hasLoadedView);
  XCTAssertEqualObjects([UIColor clearColor], node.backgroundColor, @"backgroundColor broken %@", hasLoadedView);
  XCTAssertEqual(UIViewContentModeBottom, node.contentMode, @"contentMode broken %@", hasLoadedView);
  XCTAssertEqual([[UIColor cyanColor] CGColor], node.shadowColor, @"shadowColor broken %@", hasLoadedView);
  XCTAssertEqual(.5f, node.shadowOpacity, @"shadowOpacity broken %@", hasLoadedView);
  XCTAssertTrue(CGSizeEqualToSize(CGSizeMake(1.0f, 1.0f), node.shadowOffset), @"shadowOffset broken %@", hasLoadedView);
  XCTAssertEqual(.5f, node.shadowRadius, @"shadowRadius broken %@", hasLoadedView);
  XCTAssertEqual(.5f, node.borderWidth, @"borderWidth broken %@", hasLoadedView);
  XCTAssertEqual([[UIColor orangeColor] CGColor], node.borderColor, @"borderColor broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.displaySuspended, @"displaySuspended broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.displaysAsynchronously, @"displaySuspended broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.asyncdisplaykit_asyncTransactionContainer, @"asyncTransactionContainer broken %@", hasLoadedView);
  XCTAssertEqual(NO, node.userInteractionEnabled, @"userInteractionEnabled broken %@", hasLoadedView);
  XCTAssertEqual((BOOL)!isLayerBacked, node.exclusiveTouch, @"exclusiveTouch broken %@", hasLoadedView);
  XCTAssertEqualObjects(@"quack like a duck", node.debugName, @"debugName broken %@", hasLoadedView);
  
  XCTAssertEqual(YES, node.isAccessibilityElement, @"accessibilityElement broken %@", hasLoadedView);
  XCTAssertEqualObjects(@"Ship love", node.accessibilityLabel, @"accessibilityLabel broken %@", hasLoadedView);
  XCTAssertEqualObjects(@"Awesome things will happen", node.accessibilityHint, @"accessibilityHint broken %@", hasLoadedView);
  XCTAssertEqualObjects(@"1 of 2", node.accessibilityValue, @"accessibilityValue broken %@", hasLoadedView);

  // setting the accessibilityLabel, accessibilityHint and accessibilityValue is supposed to be bridged to the attributed versions
//  if (A_S_AT_LEA_ST_IOS11) {
//    XCTAssertEqualObjects(@"Ship love", node.accessibilityAttributedLabel.string, @"accessibilityAttributedLabel is broken %@", hasLoadedView);
//    XCTAssertEqualObjects(@"Awesome things will happen", node.accessibilityAttributedHint.string, @"accessibilityAttributedHint is broken %@", hasLoadedView);
//    XCTAssertEqualObjects(@"1 of 2", node.accessibilityAttributedValue.string, @"accessibilityAttributedValue is broken %@", hasLoadedView);
//  }
  XCTAssertEqual(UIAccessibilityTraitSelected | UIAccessibilityTraitButton, node.accessibilityTraits, @"accessibilityTraits broken %@", hasLoadedView);
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(1, 2, 3, 4), node.accessibilityFrame), @"accessibilityFrame broken %@", hasLoadedView);
  XCTAssertEqualObjects(@"mas", node.accessibilityLanguage, @"accessibilityLanguage broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.accessibilityElementsHidden, @"accessibilityElementsHidden broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.accessibilityViewIsModal, @"accessibilityViewIsModal broken %@", hasLoadedView);
  XCTAssertEqual(YES, node.shouldGroupAccessibilityChildren, @"shouldGroupAccessibilityChildren broken %@", hasLoadedView);
  XCTAssertEqual(UIAccessibilityNavigationStyleSeparate, node.accessibilityNavigationStyle, @"accessibilityNavigationStyle broken %@", hasLoadedView);
  XCTAssertTrue(CGPointEqualToPoint(CGPointMake(1.0, 1.0), node.accessibilityActivationPoint), @"accessibilityActivationPoint broken %@", hasLoadedView);
  XCTAssertNotNil(node.accessibilityPath, @"accessibilityPath broken %@", hasLoadedView);
  

  if (!isLayerBacked) {
    XCTAssertEqual(UIViewAutoresizingFlexibleLeftMargin, node.autoresizingMask, @"autoresizingMask %@", hasLoadedView);
    XCTAssertEqual(NO, node.autoresizesSubviews, @"autoresizesSubviews broken %@", hasLoadedView);
  }
}

- (void)checkSimpleBridgePropertiesSetPropagate:(BOOL)isLayerBacked
{
  __block A_SDisplayNode *node = nil;

  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] init];
    node.layerBacked = isLayerBacked;

    node.contents = (id)[self bogusImage].CGImage;
    node.clipsToBounds = YES;
    node.opaque = NO;
    node.needsDisplayOnBoundsChange = YES;
    node.allowsGroupOpacity = NO;
    node.allowsEdgeAntialiasing = YES;
    node.edgeAntialiasingMask = (kCALayerLeftEdge | kCALayerTopEdge);
    node.hidden = YES;
    node.alpha = .5f;
    node.position = CGPointMake(10, 65);
    node.zPosition = 5.6;
    node.bounds = CGRectMake(10, 15, 42, 115.2);
    node.contentsScale = .5f;
    node.transform = CATransform3DMakeScale(0.5, 0.5, 1.0);
    node.subnodeTransform = CATransform3DMakeTranslation(1337, 7357, 7007);
    node.backgroundColor = [UIColor clearColor];
    node.contentMode = UIViewContentModeBottom;
    node.shadowColor = [[UIColor cyanColor] CGColor];
    node.shadowOpacity = .5f;
    node.shadowOffset = CGSizeMake(1.0f, 1.0f);
    node.shadowRadius = .5f;
    node.borderWidth = .5f;
    node.borderColor = [[UIColor orangeColor] CGColor];
    node.displaySuspended = YES;
    node.displaysAsynchronously = NO;
    node.asyncdisplaykit_asyncTransactionContainer = YES;
    node.userInteractionEnabled = NO;
    node.debugName = @"quack like a duck";
    
    node.isAccessibilityElement = YES;

    for (int i = 0; i < 4; i++) {
      if (i % 2 == 0) {
        XCTAssertNoThrow(node.accessibilityLabel = nil);
        XCTAssertNoThrow(node.accessibilityHint = nil);
        XCTAssertNoThrow(node.accessibilityValue = nil);
      } else {
        node.accessibilityLabel = @"Ship love";
        node.accessibilityHint = @"Awesome things will happen";
        node.accessibilityValue = @"1 of 2";
      }
    }

    node.accessibilityTraits = UIAccessibilityTraitSelected | UIAccessibilityTraitButton;
    node.accessibilityFrame = CGRectMake(1, 2, 3, 4);
    node.accessibilityLanguage = @"mas";
    node.accessibilityElementsHidden = YES;
    node.accessibilityViewIsModal = YES;
    node.shouldGroupAccessibilityChildren = YES;
    node.accessibilityNavigationStyle = UIAccessibilityNavigationStyleSeparate;
    node.accessibilityActivationPoint = CGPointMake(1.0, 1.0);
    node.accessibilityPath = [UIBezierPath bezierPath];

    if (!isLayerBacked) {
      node.exclusiveTouch = YES;
      node.autoresizesSubviews = NO;
      node.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }
  }];

  // Assert that the values can be fetched from the node before the view is realized.
  [self checkValuesMatchSetValues:node isLayerBacked:isLayerBacked];

  // Assert that the realized view/layer have the correct values.
  [node layer];

  [self checkValuesMatchSetValues:node isLayerBacked:isLayerBacked];

  // As a final sanity check, change a value on the realized view and ensure it is fetched through the node.
  if (isLayerBacked) {
    node.layer.hidden = NO;
  } else {
    node.view.hidden = NO;
  }
  XCTAssertEqual(NO, node.hidden, @"After the view is realized, the node should delegate properties to the view.");
}

// Set each of the simple bridged UIView properties to a non-default value off-thread, then
// assert that they are correct on the node and propagated to the UIView realized on-thread.
- (void)testSimpleUIViewBridgePropertiesSetOffThreadPropagate
{
  [self checkSimpleBridgePropertiesSetPropagate:NO];
}

- (void)testSimpleCALayerBridgePropertiesSetOffThreadPropagate
{
  [self checkSimpleBridgePropertiesSetPropagate:YES];
}

- (void)testPropertiesSetOffThreadBeforeLoadingExternalView
{
  UIView *view = [[UIDisplayNodeTestView alloc] init];

  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] initWithViewBlock:^{
      return view;
    }];
    node.backgroundColor = [UIColor blueColor];
    node.frame = CGRectMake(10, 20, 30, 40);
    node.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    node.userInteractionEnabled = YES;
  }];

  [self checkExternalViewAppliedPropertiesMatch:node];
}

- (void)testPropertiesSetOnThreadAfterLoadingExternalView
{
  UIView *view = [[UIDisplayNodeTestView alloc] init];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] initWithViewBlock:^{
    return view;
  }];

  // Load the backing view first
  [node view];

  node.backgroundColor = [UIColor blueColor];
  node.frame = CGRectMake(10, 20, 30, 40);
  node.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  node.userInteractionEnabled = YES;

  [self checkExternalViewAppliedPropertiesMatch:node];
}

- (void)checkExternalViewAppliedPropertiesMatch:(A_SDisplayNode *)node
{
  UIView *view = node.view;

  XCTAssertEqualObjects([UIColor blueColor], view.backgroundColor, @"backgroundColor not propagated to view");
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(10, 20, 30, 40), view.frame), @"frame not propagated to view");
  XCTAssertEqual(UIViewAutoresizingFlexibleWidth, view.autoresizingMask, @"autoresizingMask not propagated to view");
  XCTAssertEqual(YES, view.userInteractionEnabled, @"userInteractionEnabled not propagated to view");
}

- (void)testPropertiesSetOffThreadBeforeLoadingExternalLayer
{
  CALayer *layer = [[CA_ShapeLayer alloc] init];

  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] initWithLayerBlock:^{
      return layer;
    }];
    node.backgroundColor = [UIColor blueColor];
    node.frame = CGRectMake(10, 20, 30, 40);
  }];

  [self checkExternalLayerAppliedPropertiesMatch:node];
}

- (void)testPropertiesSetOnThreadAfterLoadingExternalLayer
{
  CALayer *layer = [[CA_ShapeLayer alloc] init];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] initWithLayerBlock:^{
    return layer;
  }];

  // Load the backing layer first
  [node layer];

  node.backgroundColor = [UIColor blueColor];
  node.frame = CGRectMake(10, 20, 30, 40);

  [self checkExternalLayerAppliedPropertiesMatch:node];
}

- (void)checkExternalLayerAppliedPropertiesMatch:(A_SDisplayNode *)node
{
  CALayer *layer = node.layer;

  XCTAssertTrue(CGColorEqualToColor([UIColor blueColor].CGColor, layer.backgroundColor), @"backgroundColor not propagated to layer");
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(10, 20, 30, 40), layer.frame), @"frame not propagated to layer");
}


// Perform parallel updates of a standard UIView/CALayer and an A_SDisplayNode and ensure they are equivalent.
- (void)testDeriveFrameFromBoundsPositionAnchorPoint
{
  UIView *plainView = [[UIView alloc] initWithFrame:CGRectZero];
  plainView.layer.anchorPoint = CGPointMake(0.25f, 0.75f);
  plainView.layer.position = CGPointMake(10, 20);
  plainView.layer.bounds = CGRectMake(0, 0, 60, 80);

  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] init];
    node.anchorPoint = CGPointMake(0.25f, 0.75f);
    node.bounds = CGRectMake(0, 0, 60, 80);
    node.position = CGPointMake(10, 20);
  }];

  XCTAssertTrue(CGRectEqualToRect(plainView.frame, node.frame), @"Node frame should match UIView frame before realization.");
  XCTAssertTrue(CGRectEqualToRect(plainView.frame, node.view.frame), @"Realized view frame should match UIView frame.");
}

// Perform parallel updates of a standard UIView/CALayer and an A_SDisplayNode and ensure they are equivalent.
- (void)testSetFrameSetsBoundsPosition
{
  UIView *plainView = [[UIView alloc] initWithFrame:CGRectZero];
  plainView.layer.anchorPoint = CGPointMake(0.25f, 0.75f);
  plainView.layer.frame = CGRectMake(10, 20, 60, 80);

  __block A_SDisplayNode *node = nil;
  [self executeOffThread:^{
    node = [[A_SDisplayNode alloc] init];
    node.anchorPoint = CGPointMake(0.25f, 0.75f);
    node.frame = CGRectMake(10, 20, 60, 80);
  }];

  XCTAssertTrue(CGPointEqualToPoint(plainView.layer.position, node.position), @"Node position should match UIView position before realization.");
  XCTAssertTrue(CGRectEqualToRect(plainView.layer.bounds, node.bounds), @"Node bounds should match UIView bounds before realization.");
  XCTAssertTrue(CGPointEqualToPoint(plainView.layer.position, node.view.layer.position), @"Realized view position should match UIView position before realization.");
  XCTAssertTrue(CGRectEqualToRect(plainView.layer.bounds, node.view.layer.bounds), @"Realized view bounds should match UIView bounds before realization.");
}

- (void)testDisplayNodePointConversionWithFrames
{
  A_SDisplayNode *node = nil;
  A_SDisplayNode *innerNode = nil;

  // Setup
  CGPoint originalPoint = CGPointZero, convertedPoint = CGPointZero, correctPoint = CGPointZero;
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* outer node's coordinate space to inner node's coordinate space
  node.frame = CGRectMake(100, 100, 100, 100);
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(105, 105), correctPoint = CGPointMake(95, 95);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:node selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* inner node's coordinate space to outer node's coordinate space
  node.frame = CGRectMake(100, 100, 100, 100);
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(5, 5), correctPoint = CGPointMake(15, 15);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:node];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in inner node's coordinate space *TO* outer node's coordinate space
  node.frame = CGRectMake(100, 100, 100, 100);
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(95, 95), correctPoint = CGPointMake(105, 105);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:node selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in outer node's coordinate space *TO* inner node's coordinate space
  node.frame = CGRectMake(0, 0, 100, 100);
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(5, 5), correctPoint = CGPointMake(-5, -5);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:node];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));
}

// Test conversions when bounds is not null.
// NOTE: Esoteric values were picked to facilitate visual inspection by demonstrating the relevance of certain numbers and lack of relevance of others
- (void)testDisplayNodePointConversionWithNonZeroBounds
{
  A_SDisplayNode *node = nil;
  A_SDisplayNode *innerNode = nil;

  // Setup
  CGPoint originalPoint = CGPointZero, convertedPoint = CGPointZero, correctPoint = CGPointZero;
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* outer node's coordinate space to inner node's coordinate space
  node.anchorPoint = CGPointZero;
  innerNode.anchorPoint = CGPointZero;
  node.bounds = CGRectMake(20, 20, 100, 100);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(42, 42), correctPoint = CGPointMake(36, 36);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:node selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* inner node's coordinate space to outer node's coordinate space
  node.anchorPoint = CGPointZero;
  innerNode.anchorPoint = CGPointZero;
  node.bounds = CGRectMake(-1000, -1000, 1337, 1337);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 200, 200);
  originalPoint = CGPointMake(5, 5), correctPoint = CGPointMake(11, 11);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:node];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in inner node's coordinate space *TO* outer node's coordinate space
  node.anchorPoint = CGPointZero;
  innerNode.anchorPoint = CGPointZero;
  node.bounds = CGRectMake(20, 20, 100, 100);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(36, 36), correctPoint = CGPointMake(42, 42);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:node selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in outer node's coordinate space *TO* inner node's coordinate space
  node.anchorPoint = CGPointZero;
  innerNode.anchorPoint = CGPointZero;
  node.bounds = CGRectMake(-1000, -1000, 1337, 1337);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 200, 200);
  originalPoint = CGPointMake(11, 11), correctPoint = CGPointMake(5, 5);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:node];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));
}

// Test conversions when the anchorPoint is not {0.0, 0.0}.
- (void)testDisplayNodePointConversionWithNonZeroAnchorPoint
{
  A_SDisplayNode *node = nil;
  A_SDisplayNode *innerNode = nil;

  // Setup
  CGPoint originalPoint = CGPointZero, convertedPoint = CGPointZero, correctPoint = CGPointZero;
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* outer node's coordinate space to inner node's coordinate space
  node.bounds = CGRectMake(20, 20, 100, 100);
  innerNode.anchorPoint = CGPointMake(0.75, 1);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(42, 42), correctPoint = CGPointMake(51, 56);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:node selfNode:innerNode];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(convertedPoint, correctPoint, 0.001), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point *FROM* inner node's coordinate space to outer node's coordinate space
  node.bounds = CGRectMake(-1000, -1000, 1337, 1337);
  innerNode.anchorPoint = CGPointMake(0.3, 0.3);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 200, 200);
  originalPoint = CGPointMake(55, 55), correctPoint = CGPointMake(1, 1);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:node];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(convertedPoint, correctPoint, 0.001), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in inner node's coordinate space *TO* outer node's coordinate space
  node.bounds = CGRectMake(20, 20, 100, 100);
  innerNode.anchorPoint = CGPointMake(0.75, 1);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(51, 56), correctPoint = CGPointMake(42, 42);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:node selfNode:innerNode];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(convertedPoint, correctPoint, 0.001), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));

  // Setup
  node = [[A_SDisplayNode alloc] init], innerNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:innerNode];

  // Convert point in outer node's coordinate space *TO* inner node's coordinate space
  node.bounds = CGRectMake(-1000, -1000, 1337, 1337);
  innerNode.anchorPoint = CGPointMake(0.3, 0.3);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 200, 200);
  originalPoint = CGPointMake(1, 1), correctPoint = CGPointMake(55, 55);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:node];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(convertedPoint, correctPoint, 0.001), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));
}

- (void)testDisplayNodePointConversionAgainstSelf {
  A_SDisplayNode *innerNode = nil;
  CGPoint originalPoint = CGPointZero, convertedPoint = CGPointZero;

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(105, 105);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:innerNode];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(convertedPoint, originalPoint, 0.001), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(42, 42);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, originalPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.anchorPoint = CGPointMake(0.3, 0.3);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 200, 200);
  originalPoint = CGPointMake(55, 55);
  convertedPoint = [self checkConvertPoint:originalPoint fromNode:innerNode selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, originalPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.frame = CGRectMake(10, 10, 20, 20);
  originalPoint = CGPointMake(95, 95);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, originalPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(36, 36);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, originalPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));

  innerNode = [[A_SDisplayNode alloc] init];
  innerNode.anchorPoint = CGPointMake(0.75, 1);
  innerNode.position = CGPointMake(23, 23);
  innerNode.bounds = CGRectMake(17, 17, 20, 20);
  originalPoint = CGPointMake(51, 56);
  convertedPoint = [self checkConvertPoint:originalPoint toNode:innerNode selfNode:innerNode];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, originalPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(convertedPoint));
}

- (void)testDisplayNodePointConversionFailureFromDisjointHierarchies
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *childNode = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *otherNode = [[A_SDisplayNode alloc] init];
  [node addSubnode:childNode];

  XCTAssertNoThrow([self checkConvertPoint:CGPointZero fromNode:node selfNode:childNode], @"Assertion should have succeeded; nodes are in the same hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero fromNode:node selfNode:otherNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero fromNode:childNode selfNode:otherNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");

  XCTAssertNoThrow([self checkConvertPoint:CGPointZero fromNode:childNode selfNode:node], @"Assertion should have succeeded; nodes are in the same hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero fromNode:otherNode selfNode:node], @"Assertion should have failed for nodes that are not in the same node hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero fromNode:otherNode selfNode:childNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");

  XCTAssertNoThrow([self checkConvertPoint:CGPointZero toNode:node selfNode:childNode], @"Assertion should have succeeded; nodes are in the same hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero toNode:node selfNode:otherNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero toNode:childNode selfNode:otherNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");

  XCTAssertNoThrow([self checkConvertPoint:CGPointZero toNode:childNode selfNode:node], @"Assertion should have succeeded; nodes are in the same hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero toNode:otherNode selfNode:node], @"Assertion should have failed for nodes that are not in the same node hierarchy");
  XCTAssertThrows([self checkConvertPoint:CGPointZero toNode:otherNode selfNode:childNode], @"Assertion should have failed for nodes that are not in the same node hierarchy");
}

- (void)testDisplayNodePointConversionOnDeepHierarchies
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];

  // 7 deep (six below root); each one positioned at position = (1, 1)
  _addTonsOfSubnodes(node, 2, 6, ^(A_SDisplayNode *createdNode) {
    createdNode.position = CGPointMake(1, 1);
  });

  A_SDisplayNode *deepSubNode = [self _getDeepSubnodeForRoot:node withIndices:@[@1, @1, @1, @1, @1, @1]];

  CGPoint originalPoint = CGPointMake(55, 55);
  CGPoint correctPoint = CGPointMake(61, 61);
  CGPoint convertedPoint = [deepSubNode convertPoint:originalPoint toNode:node];
  XCTAssertTrue(CGPointEqualToPoint(convertedPoint, correctPoint), @"Unexpected point conversion result. Point: %@ Expected conversion: %@ Actual conversion: %@", NSStringFromCGPoint(originalPoint), NSStringFromCGPoint(correctPoint), NSStringFromCGPoint(convertedPoint));
}

// Adds nodes (breadth-first rather than depth-first addition)
static void _addTonsOfSubnodes(A_SDisplayNode *parent, NSUInteger fanout, NSUInteger depth, void (^onCreate)(A_SDisplayNode *createdNode)) {
  if (depth == 0) {
    return;
  }

  for (NSUInteger i = 0; i < fanout; i++) {
    A_SDisplayNode *subnode = [[A_SDisplayNode alloc] init];
    [parent addSubnode:subnode];
    onCreate(subnode);
  }
  for (NSUInteger i = 0; i < fanout; i++) {
    _addTonsOfSubnodes(parent.subnodes[i], fanout, depth - 1, onCreate);
  }
}

// Convenience function for getting a node deep within a node hierarchy
- (A_SDisplayNode *)_getDeepSubnodeForRoot:(A_SDisplayNode *)root withIndices:(NSArray *)indexArray {
  if ([indexArray count] == 0) {
    return root;
  }

  NSArray *subnodes = root.subnodes;
  if ([subnodes count] == 0) {
    XCTFail(@"Node hierarchy isn't deep enough for given index array");
  }

  NSUInteger index = [indexArray[0] unsignedIntegerValue];
  NSArray *otherIndices = [indexArray subarrayWithRange:NSMakeRange(1, [indexArray count] -1)];

  return [self _getDeepSubnodeForRoot:subnodes[index] withIndices:otherIndices];
}

static inline BOOL _CGPointEqualToPointWithEpsilon(CGPoint point1, CGPoint point2, CGFloat epsilon) {
  CGFloat absEpsilon =  fabs(epsilon);
  BOOL xOK = fabs(point1.x - point2.x) < absEpsilon;
  BOOL yOK = fabs(point1.y - point2.y) < absEpsilon;
  return xOK && yOK;
}

- (CGPoint)checkConvertPoint:(CGPoint)point fromNode:(A_SDisplayNode *)fromNode selfNode:(A_SDisplayNode *)toNode
{
  CGPoint nodeConversion = [toNode convertPoint:point fromNode:fromNode];

  UIView *fromView = fromNode.view;
  UIView *toView = toNode.view;
  CGPoint viewConversion = [toView convertPoint:point fromView:fromView];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(nodeConversion, viewConversion, 0.001), @"Conversion mismatch: node: %@ view: %@", NSStringFromCGPoint(nodeConversion), NSStringFromCGPoint(viewConversion));
  return nodeConversion;
}

- (CGPoint)checkConvertPoint:(CGPoint)point toNode:(A_SDisplayNode *)toNode selfNode:(A_SDisplayNode *)fromNode
{
  CGPoint nodeConversion = [fromNode convertPoint:point toNode:toNode];

  UIView *fromView = fromNode.view;
  UIView *toView = toNode.view;
  CGPoint viewConversion = [fromView convertPoint:point toView:toView];
  XCTAssertTrue(_CGPointEqualToPointWithEpsilon(nodeConversion, viewConversion, 0.001), @"Conversion mismatch: node: %@ view: %@", NSStringFromCGPoint(nodeConversion), NSStringFromCGPoint(viewConversion));
  return nodeConversion;
}

- (void)executeOffThread:(void (^)(void))block
{
  __block BOOL blockExecuted = NO;
  dispatch_group_t g = dispatch_group_create();
  dispatch_group_async(g, queue, ^{
    block();
    blockExecuted = YES;
  });
  dispatch_group_wait(g, DISPATCH_TIME_FOREVER);
  XCTAssertTrue(blockExecuted, @"Block did not finish executing. Timeout or exception?");
}

- (void)testReferenceCounting
{
  __weak A_STestDisplayNode *weakNode = nil;
  {
    NS_VALID_UNTIL_END_OF_SCOPE A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
    weakNode = node;
  }
  XCTAssertNil(weakNode);
}

- (void)testAddingNodeToHierarchyRetainsNode
{
  UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
  __weak A_STestDisplayNode *weakNode = nil;
  {
    NS_VALID_UNTIL_END_OF_SCOPE A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
    [v addSubview:node.view];
    weakNode = node;
  }
  XCTAssertNotNil(weakNode);
}

- (void)testAddingSubnodeDoesNotCreateRetainCycle
{
  __weak A_STestDisplayNode *weakNode = nil;
  __weak A_STestDisplayNode *weakSubnode = nil;
  {
    NS_VALID_UNTIL_END_OF_SCOPE A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
    NS_VALID_UNTIL_END_OF_SCOPE A_STestDisplayNode *subnode = [[A_STestDisplayNode alloc] init];
    [node addSubnode:subnode];
    weakNode = node;
    weakSubnode = subnode;
    
    XCTAssertNotNil(weakNode);
    XCTAssertNotNil(weakSubnode);
  }
  XCTAssertNil(weakNode);
  XCTAssertNil(weakSubnode);
}

- (void)testThatUIKitDeallocationTrampoliningWorks
{
  NS_VALID_UNTIL_END_OF_SCOPE __weak UIGestureRecognizer *weakRecognizer = nil;
  NS_VALID_UNTIL_END_OF_SCOPE __weak UIGestureRecognizer *weakIdRecognizer = nil;
  NS_VALID_UNTIL_END_OF_SCOPE __weak UIView *weakView = nil;
  NS_VALID_UNTIL_END_OF_SCOPE __weak CALayer *weakLayer = nil;
  NS_VALID_UNTIL_END_OF_SCOPE __weak UIImage *weakImage = nil;
  NS_VALID_UNTIL_END_OF_SCOPE __weak NSArray *weakArray = nil;
  __block NS_VALID_UNTIL_END_OF_SCOPE A_STestDisplayNode *node = nil;
  @autoreleasepool {
    node = [[A_STestDisplayNode alloc] init];
    node.gestureRecognizer = [[UIGestureRecognizer alloc] init];
    node.idGestureRecognizer = [[UIGestureRecognizer alloc] init];
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1000, 1000), YES, 1);
    node.bigImage = UIGraphicsGetImageFromCurrentImageContext();
    node.randomProperty = @[ @"Hello, world!" ];
    UIGraphicsEndImageContext();
    weakImage = node.bigImage;
    weakView = node.view;
    weakLayer = node.layer;
    weakArray = node.randomProperty;
    weakIdRecognizer = node.idGestureRecognizer;
    weakRecognizer = node.gestureRecognizer;
  }

  [self executeOffThread:^{
    node = nil;
  }];

  XCTAssertNotNil(weakRecognizer, @"UIGestureRecognizer ivars should be deallocated on main.");
  XCTAssertNotNil(weakIdRecognizer, @"UIGestureRecognizer-backed 'id' ivars should be deallocated on main.");
  XCTAssertNotNil(weakView, @"UIView ivars should be deallocated on main.");
  XCTAssertNotNil(weakLayer, @"CALayer ivars should be deallocated on main.");
  XCTAssertNil(weakImage, @"UIImage ivars should be deallocated normally.");
  XCTAssertNil(weakArray, @"NSArray ivars should be deallocated normally.");
  XCTAssertNil(node);
  
  [self expectationForPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nonnull evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
    return (weakRecognizer == nil && weakIdRecognizer == nil && weakView == nil);
  }] evaluatedWithObject:(id)kCFNull handler:nil];
  [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testSubnodes
{
  A_SDisplayNode *parent = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *nilNode = nil;
  XCTAssertThrows([parent addSubnode:nilNode], @"Don't try to add nil, but we'll deal with it in production, but throw in development.");
  XCTAssertNoThrow([parent addSubnode:parent], @"Not good, test that we recover");
  XCTAssertEqual(0u, parent.subnodes.count, @"We shouldn't have any subnodes");
}

- (void)testReplaceSubnodeNoView
{
  [self checkReplaceSubnodeLoaded:NO layerBacked:NO];
}

- (void)testReplaceSubnodeNoLayer
{
  [self checkReplaceSubnodeLoaded:NO layerBacked:YES];
}

- (void)testReplaceSubnodeView
{
  [self checkReplaceSubnodeLoaded:YES layerBacked:NO];
}

- (void)testReplaceSubnodeLayer
{
  [self checkReplaceSubnodeLoaded:YES layerBacked:YES];
}


- (void)checkReplaceSubnodeLoaded:(BOOL)loaded layerBacked:(BOOL)isLayerBacked
{
  DeclareNodeNamed(parent);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);
  DeclareNodeNamed(d);

  for (A_SDisplayNode *n in @[parent, a, b, c, d]) {
    n.layerBacked = isLayerBacked;
  }

  [parent addSubnode:a];
  [parent addSubnode:b];
  [parent addSubnode:c];

  if (loaded) {
    [parent layer];
  }

  if (loaded) {
    XCTAssertFalse(d.nodeLoaded, @"Should not yet be loaded");
  }

  // Shut the type mismatch up
  A_SDisplayNode *nilParent = nil;

  // Check initial state
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"initial state");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Check replace 0th
  [parent replaceSubnode:a withSubnode:d];

  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"d,b,c", @"after replace 0th");
  XCTAssertNodesHaveParent(parent, d, b, c);
  XCTAssertNodesHaveParent(nilParent, a);
  if (loaded) {
    XCTAssertNodesLoaded(d);
  }

  [parent replaceSubnode:d withSubnode:a];

  // Check replace 1st
  [parent replaceSubnode:b withSubnode:d];

  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,d,c", @"Replace");
  XCTAssertNodesHaveParent(parent, a, c, d);
  XCTAssertNodesHaveParent(nilParent, b);

  [parent replaceSubnode:d withSubnode:b];

  // Check replace 2nd
  [parent replaceSubnode:c withSubnode:d];

  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,d", @"Replace");
  XCTAssertNodesHaveParent(parent, a, b, d);
  XCTAssertNodesHaveParent(nilParent, c);

  [parent replaceSubnode:d withSubnode:c];

  //Check initial again
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"check should back to initial");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Check replace 0th with 2nd
  [parent replaceSubnode:a withSubnode:c];

  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,b", @"After replace 0th");
  XCTAssertNodesHaveParent(parent, c, b);
  XCTAssertNodesHaveParent(nilParent, a,d);

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}

- (void)testInsertSubnodeAtIndexView
{
  [self checkInsertSubnodeAtIndexWithViewLoaded:YES layerBacked:NO];
}

- (void)testInsertSubnodeAtIndexLayer
{
  [self checkInsertSubnodeAtIndexWithViewLoaded:YES layerBacked:YES];
}

- (void)testInsertSubnodeAtIndexNoView
{
  [self checkInsertSubnodeAtIndexWithViewLoaded:NO layerBacked:NO];
}

- (void)testInsertSubnodeAtIndexNoLayer
{
  [self checkInsertSubnodeAtIndexWithViewLoaded:NO layerBacked:YES];
}

- (void)checkInsertSubnodeAtIndexWithViewLoaded:(BOOL)loaded layerBacked:(BOOL)isLayerBacked
{
  DeclareNodeNamed(parent);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);

  for (A_SDisplayNode *v in @[parent, a, b, c]) {
    v.layerBacked = isLayerBacked;
  }

  // Load parent
  if (loaded) {
    (void)[parent layer];
  }

  // Add another subnode to test creation after parent is loaded
  DeclareNodeNamed(d);
  d.layerBacked = isLayerBacked;
  if (loaded) {
    XCTAssertFalse(d.nodeLoaded, @"Should not yet be loaded");
  }

  // Shut the type mismatch up
  A_SDisplayNode *nilParent = nil;

  // Check initial state
  XCTAssertEqual(0u, parent.subnodes.count, @"Should have the right subnode count");

  // Check insert at 0th () => (a,b,c)
  [parent insertSubnode:c atIndex:0];
  [parent insertSubnode:b atIndex:0];
  [parent insertSubnode:a atIndex:0];

  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"initial state");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  if (loaded) {
    XCTAssertNodesLoaded(a, b, c);
  } else {
    XCTAssertNodesNotLoaded(a, b, c);
  }

  // Check insert at 1st (a,b,c) => (a,d,b,c)
  [parent insertSubnode:d atIndex:1];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,d,b,c", @"initial state");
  XCTAssertNodesHaveParent(parent, a, b, c, d);
  if (loaded) {
    XCTAssertNodesLoaded(d);
  }

  // Reset
  [d removeFromSupernode];
  XCTAssertEqual(3u, parent.subnodes.count, @"Should have the right subnode count");
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"Bad removal of d");
  XCTAssertNodesHaveParent(nilParent, d);

  // Check insert at last position
  [parent insertSubnode:d atIndex:3];

  XCTAssertEqual(4u, parent.subnodes.count, @"Should have the right subnode count");
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c,d", @"insert at last position.");
  XCTAssertNodesHaveParent(parent, a, b, c, d);

  // Reset
  [d removeFromSupernode];
  XCTAssertEqual(3u, parent.subnodes.count, @"Should have the right subnode count");
  XCTAssertEqualObjects(nilParent, d.supernode, @"d's parent is messed up");

  // Check insert a nil node
  A_SDisplayNode *nilNode = nil;
  XCTAssertThrows([parent insertSubnode:nilNode atIndex:0], @"Should not allow insertion of nil node. We will throw in development and deal with it in production");

  // Check insert at invalid index
  XCTAssertThrows([parent insertSubnode:d atIndex:NSNotFound], @"Should not allow insertion at invalid index");
  XCTAssertThrows([parent insertSubnode:d atIndex:-1], @"Should not allow insertion at invalid index");

  // Should have same state as before
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"Funny business should not corrupt state");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Check reordering existing subnodes with the insert API
  // Move c to front
  [parent insertSubnode:c atIndex:0];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,a,b", @"Move to front when already a subnode");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Move c to middle
  [parent insertSubnode:c atIndex:1];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Move c to middle");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Insert c at the index it's already at
  [parent insertSubnode:c atIndex:1];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Funny business should not corrupt state");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  // Insert c at 0th when it's already in the array
  [parent insertSubnode:c atIndex:2];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b,c", @"Funny business should not corrupt state");
  XCTAssertNodesHaveParent(parent, a, b, c);
  XCTAssertNodesHaveParent(nilParent, d);

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}

// This tests our resiliancy to having other views and layers inserted into our view or layer
- (void)testInsertSubviewAtIndexWithMeddlingViewsAndLayersViewBacked
{
  A_SDisplayNode *parent = [[A_SDisplayNode alloc] init];

  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);
  DeclareViewNamed(d);
  DeclareLayerNamed(e);

  [parent layer];

  // (a,b)
  [parent addSubnode:a];
  [parent addSubnode:b];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,b", @"Didn't match");

  // (a,b) => (a,d,b)
  [parent.view insertSubview:d aboveSubview:a.view];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,d,b", @"Didn't match");

  // (a,d,b) => (a,e,d,b)
  [parent.layer insertSublayer:e above:a.layer];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,e,d,b", @"Didn't match");

  // (a,e,d,b) => (a,e,d,c,b)
  [parent insertSubnode:c belowSubnode:b];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,e,d,c,b", @"Didn't match");

  XCTAssertEqual(4u, parent.subnodes.count, @"Should have the right subnode count");
  XCTAssertEqual(4u, parent.view.subviews.count, @"Should have the right subview count");
  XCTAssertEqual(5u, parent.layer.sublayers.count, @"Should have the right sublayer count");
  
  [e removeFromSuperlayer];
  XCTAssertEqual(4u, parent.layer.sublayers.count, @"Should have the right sublayer count");

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}

- (void)testAppleBugInsertSubview
{
  DeclareViewNamed(parent);

  DeclareLayerNamed(aa);
  DeclareLayerNamed(ab);
  DeclareViewNamed(a);
  DeclareLayerNamed(ba);
  DeclareLayerNamed(bb);
  DeclareLayerNamed(bc);
  DeclareLayerNamed(bd);
  DeclareViewNamed(c);
  DeclareViewNamed(d);
  DeclareLayerNamed(ea);
  DeclareLayerNamed(eb);
  DeclareLayerNamed(ec);

  [parent.layer addSublayer:aa];
  [parent.layer addSublayer:ab];
  [parent addSubview:a];
  [parent.layer addSublayer:ba];
  [parent.layer addSublayer:bb];
  [parent.layer addSublayer:bc];
  [parent.layer addSublayer:bd];
  [parent addSubview:d];
  [parent.layer addSublayer:ea];
  [parent.layer addSublayer:eb];
  [parent.layer addSublayer:ec];

  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"aa,ab,a,ba,bb,bc,bd,d,ea,eb,ec", @"Should be in order");

  // Should insert at SUBVIEW index 1, right??
  [parent insertSubview:c atIndex:1];

  // You would think that this would be true, but instead it inserts it at the SUBLAYER index 1
//  XCTAssertEquals([parent.subviews indexOfObjectIdenticalTo:c], 1u, @"Should have index 1 after insert");
//  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"aa,ab,a,ba,bb,bc,bd,c,d,ea,eb,ec", @"Should be in order");

  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"aa,c,ab,a,ba,bb,bc,bd,d,ea,eb,ec", @"Apple has fixed insertSubview:atIndex:. You must update insertSubnode: etc. APIS to accomidate this.");
}

// This tests our resiliancy to having other views and layers inserted into our view or layer
- (void)testInsertSubviewAtIndexWithMeddlingView
{
  DeclareNodeNamed(parent);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);
  DeclareViewNamed(d);

  [parent layer];

  // (a,b)
  [parent addSubnode:a];
  [parent addSubnode:b];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,b", @"Didn't match");

  // (a,b) => (a,d,b)
  [parent.view insertSubview:d aboveSubview:a.view];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,d,b", @"Didn't match");

  // (a,d,b) => (a,d,>c<,b)
  [parent insertSubnode:c belowSubnode:b];
  XCTAssertEqualObjects(orderStringFromSublayers(parent.layer), @"a,d,c,b", @"Didn't match");

  XCTAssertEqual(4u, parent.subnodes.count, @"Should have the right subnode count");
  XCTAssertEqual(4u, parent.view.subviews.count, @"Should have the right subview count");
  XCTAssertEqual(4u, parent.layer.sublayers.count, @"Should have the right sublayer count");

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}


- (void)testInsertSubnodeBelowWithView
{
  [self checkInsertSubnodeBelowWithView:YES layerBacked:NO];
}

- (void)testInsertSubnodeBelowWithNoView
{
  [self checkInsertSubnodeBelowWithView:NO layerBacked:NO];
}

- (void)testInsertSubnodeBelowWithNoLayer
{
  [self checkInsertSubnodeBelowWithView:NO layerBacked:YES];
}

- (void)testInsertSubnodeBelowWithLayer
{
  [self checkInsertSubnodeBelowWithView:YES layerBacked:YES];
}


- (void)checkInsertSubnodeBelowWithView:(BOOL)loaded layerBacked:(BOOL)isLayerBacked
{
  DeclareNodeNamed(parent);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);

  for (A_SDisplayNode *v in @[parent, a, b, c]) {
    v.layerBacked = isLayerBacked;
  }

  [parent addSubnode:b];

  if (loaded) {
    [parent layer];
  }

  // Shut the type mismatch up
  A_SDisplayNode *nilParent = nil;

  // (b) => (a, b)
  [parent insertSubnode:a belowSubnode:b];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b", @"Incorrect insertion below");
  XCTAssertNodesHaveParent(parent, a, b);
  XCTAssertNodesHaveParent(nilParent, c);

  // (a,b) => (c,a,b)
  [parent insertSubnode:c belowSubnode:a];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,a,b", @"Incorrect insertion below");
  XCTAssertNodesHaveParent(parent, a, b, c);

  // Check insertSubnode with no below
  A_SDisplayNode *nilNode = nil;
  XCTAssertThrows([parent insertSubnode:b belowSubnode:nilNode], @"Can't insert below a nil");
  // Check nothing was inserted
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,a,b", @"Incorrect insertion below");


  XCTAssertThrows([parent insertSubnode:nilNode belowSubnode:nilNode], @"Can't insert a nil subnode");
  XCTAssertThrows([parent insertSubnode:nilNode belowSubnode:a], @"Can't insert a nil subnode");

  // Check inserting below when you're already in the array
  // (c,a,b) => (a,c,b)
  [parent insertSubnode:c belowSubnode:b];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Incorrect insertion below");
  XCTAssertNodesHaveParent(parent, a, c, b);

  // Check what happens when you try to insert a node below itself (should do nothing)
  // (a,c,b) => (a,c,b)
  [parent insertSubnode:c belowSubnode:c];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Incorrect insertion below");
  XCTAssertNodesHaveParent(parent, a, c, b);

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}

- (void)testInsertSubnodeAboveWithView
{
  [self checkInsertSubnodeAboveLoaded:YES layerBacked:NO];
}

- (void)testInsertSubnodeAboveWithNoView
{
  [self checkInsertSubnodeAboveLoaded:NO layerBacked:NO];
}

- (void)testInsertSubnodeAboveWithLayer
{
  [self checkInsertSubnodeAboveLoaded:YES layerBacked:YES];
}

- (void)testInsertSubnodeAboveWithNoLayer
{
  [self checkInsertSubnodeAboveLoaded:NO layerBacked:YES];
}


- (void)checkInsertSubnodeAboveLoaded:(BOOL)loaded layerBacked:(BOOL)isLayerBacked
{
  DeclareNodeNamed(parent);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);

  for (A_SDisplayNode *n in @[parent, a, b, c]) {
    n.layerBacked = isLayerBacked;
  }

  [parent addSubnode:a];

  if (loaded) {
    [parent layer];
  }

  // Shut the type mismatch up
  A_SDisplayNode *nilParent = nil;

  // (a) => (a,b)
  [parent insertSubnode:b aboveSubnode:a];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,b", @"Insert subnode above");
  XCTAssertNodesHaveParent(parent, a,b);
  XCTAssertNodesHaveParent(nilParent, c);

  // (a,b) => (a,c,b)
  [parent insertSubnode:c aboveSubnode:a];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"After insert c above a");

  // Check insertSubnode with invalid parameters throws and doesn't change anything
  // (a,c,b) => (a,c,b)
  A_SDisplayNode *nilNode = nil;
  XCTAssertThrows([parent insertSubnode:b aboveSubnode:nilNode], @"Can't insert below a nil");
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Check no monkey business");

  XCTAssertThrows([parent insertSubnode:nilNode aboveSubnode:nilNode], @"Can't insert a nil subnode");
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Check no monkey business");

  XCTAssertThrows([parent insertSubnode:nilNode aboveSubnode:a], @"Can't insert a nil subnode");
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"a,c,b", @"Check no monkey business");

  // Check inserting above when you're already in the array
  // (a,c,b) => (c,b,a)
  [parent insertSubnode:a aboveSubnode:b];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,b,a", @"Check inserting above when you're already in the array");
  XCTAssertNodesHaveParent(parent, a, c, b);

  // Check what happens when you try to insert a node above itself (should do nothing)
  // (c,b,a) => (c,b,a)
  [parent insertSubnode:a aboveSubnode:a];
  XCTAssertNodeSubnodeSubviewSublayerOrder(parent, loaded, isLayerBacked, @"c,b,a", @"Insert above self should not change anything");
  XCTAssertNodesHaveParent(parent, a, c, b);

  //TODO: assert that things deallocate immediately and don't have latent autoreleases in here
}

- (void)testRemoveFromViewBackedLoadedSupernode
{
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  [b addSubnode:a];
  [a view];
  [b view];
  XCTAssertNodesLoaded(a, b);
  XCTAssertEqual(a.supernode, b);
  XCTAssertEqual(a.view.superview, b.view);
  
  [a removeFromSupernode];
  XCTAssertNil(a.supernode);
  XCTAssertNil(a.view.superview);
}

- (void)testRemoveFromLayerBackedLoadedSupernode
{
  DeclareNodeNamed(a);
  a.layerBacked = YES;
  DeclareNodeNamed(b);
  b.layerBacked = YES;
  [b addSubnode:a];
  [a layer];
  [b layer];
  XCTAssertNodesLoaded(a, b);
  XCTAssertEqual(a.supernode, b);
  XCTAssertEqual(a.layer.superlayer, b.layer);
  
  [a removeFromSupernode];
  XCTAssertNil(a.supernode);
  XCTAssertNil(a.layer.superlayer);
}

- (void)testRemoveLayerBackedFromViewBackedLoadedSupernode
{
  DeclareNodeNamed(a);
  a.layerBacked = YES;
  DeclareNodeNamed(b);
  [b addSubnode:a];
  [a layer];
  [b view];
  XCTAssertNodesLoaded(a, b);
  XCTAssertEqual(a.supernode, b);
  XCTAssertEqual(a.layer.superlayer, b.layer);
  
  [a removeFromSupernode];
  XCTAssertNil(a.supernode);
  XCTAssertNil(a.layer.superlayer);
}

- (void)testSubnodeAddedBeforeLoadingExternalView
{
  UIView *view = [[UIDisplayNodeTestView alloc] init];

  __block A_SDisplayNode *parent = nil;
  __block A_SDisplayNode *child = nil;
  [self executeOffThread:^{
    parent = [[A_SDisplayNode alloc] initWithViewBlock:^{
      return view;
    }];
    child = [[A_SDisplayNode alloc] init];
    [parent addSubnode:child];
  }];

  XCTAssertEqual(1, parent.subnodes.count, @"Parent should have 1 subnode");
  XCTAssertEqualObjects(parent, child.supernode, @"Child has the wrong parent");
  XCTAssertEqual(0, view.subviews.count, @"View shouldn't have any subviews");

  [parent view];

  XCTAssertEqual(1, view.subviews.count, @"View should have 1 subview");
}

- (void)testSubnodeAddedAfterLoadingExternalView
{
  UIView *view = [[UIDisplayNodeTestView alloc] init];
  A_SDisplayNode *parent = [[A_SDisplayNode alloc] initWithViewBlock:^{
    return view;
  }];

  [parent view];

  A_SDisplayNode *child = [[A_SDisplayNode alloc] init];
  [parent addSubnode:child];

  XCTAssertEqual(1, parent.subnodes.count, @"Parent should have 1 subnode");
  XCTAssertEqualObjects(parent, child.supernode, @"Child has the wrong parent");
  XCTAssertEqual(1, view.subviews.count, @"View should have 1 subview");
}

- (void)checkBackgroundColorOpaqueRelationshipWithViewLoaded:(BOOL)loaded layerBacked:(BOOL)isLayerBacked
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layerBacked = isLayerBacked;

  if (loaded) {
    // Force load
    [node layer];
  }

  XCTAssertTrue(node.opaque, @"Node should start opaque");
  XCTAssertTrue(node.layer.opaque, @"Node should start opaque");

  node.backgroundColor = [UIColor clearColor];

  // This could be debated, but at the moment we differ from UIView's behavior to change the other property in response
  XCTAssertTrue(node.opaque, @"Set background color should not have made this not opaque");
  XCTAssertTrue(node.layer.opaque, @"Set background color should not have made this not opaque");

  [node layer];

  XCTAssertTrue(node.opaque, @"Set background color should not have made this not opaque");
  XCTAssertTrue(node.layer.opaque, @"Set background color should not have made this not opaque");
}

- (void)testBackgroundColorOpaqueRelationshipView
{
  [self checkBackgroundColorOpaqueRelationshipWithViewLoaded:YES layerBacked:NO];
}

- (void)testBackgroundColorOpaqueRelationshipLayer
{
  [self checkBackgroundColorOpaqueRelationshipWithViewLoaded:YES layerBacked:YES];
}

- (void)testBackgroundColorOpaqueRelationshipNoView
{
  [self checkBackgroundColorOpaqueRelationshipWithViewLoaded:NO layerBacked:NO];
}

- (void)testBackgroundColorOpaqueRelationshipNoLayer
{
  [self checkBackgroundColorOpaqueRelationshipWithViewLoaded:NO layerBacked:YES];
}

// Check that nodes who have no cell node (no range controller)
// do get their `preload` called, and they do report
// the preload interface state.
- (void)testInterfaceStateForNonCellNode
{
  A_STestWindow *window = [A_STestWindow new];
  A_STestDisplayNode *node = [A_STestDisplayNode new];
  XCTAssert(node.interfaceState == A_SInterfaceStateNone);
  XCTAssert(!node.hasPreloaded);

  [window addSubview:node.view];
  XCTAssert(node.hasPreloaded);
  XCTAssert(node.interfaceState == A_SInterfaceStateInHierarchy);

  [node.view removeFromSuperview];
  // We don't want to call -didExitPreloadState on nodes that aren't being managed by a range controller.
  // Otherwise we get flashing behavior from normal UIKit manipulations like navigation controller push / pop.
  // Still, the interfaceState should be None to reflect the current state of the node.
  // We just don't proactively clear contents or fetched data for this state transition.
  XCTAssert(node.hasPreloaded);
  XCTAssert(node.interfaceState == A_SInterfaceStateNone);
}

// Check that nodes who have no cell node (no range controller)
// do get their `preload` called, and they do report
// the preload interface state.
- (void)testInterfaceStateForCellNode
{
  A_SCellNode *cellNode = [A_SCellNode new];
  A_STestDisplayNode *node = [A_STestDisplayNode new];
  XCTAssert(node.interfaceState == A_SInterfaceStateNone);
  XCTAssert(!node.hasPreloaded);

  // Simulate range handler updating cell node.
  [cellNode addSubnode:node];
  [cellNode enterInterfaceState:A_SInterfaceStatePreload];
  XCTAssert(node.hasPreloaded);
  XCTAssert(node.interfaceState == A_SInterfaceStatePreload);

  // If the node goes into a view it should not adopt the `InHierarchy` state.
  A_STestWindow *window = [A_STestWindow new];
  [window addSubview:cellNode.view];
  XCTAssert(node.hasPreloaded);
  XCTAssert(node.interfaceState == A_SInterfaceStateInHierarchy);
}

- (void)testSetNeedsPreloadImmediateState
{
  A_SCellNode *cellNode = [A_SCellNode new];
  A_STestDisplayNode *node = [A_STestDisplayNode new];
  [cellNode addSubnode:node];
  [cellNode enterInterfaceState:A_SInterfaceStatePreload];
  node.hasPreloaded = NO;
  [cellNode setNeedsPreload];
  XCTAssert(node.hasPreloaded);
}

- (void)testPreloadExitingAndEnteringRange
{
  A_SCellNode *cellNode = [A_SCellNode new];
  A_STestDisplayNode *node = [A_STestDisplayNode new];
  [cellNode addSubnode:node];
  [cellNode setHierarchyState:A_SHierarchyStateRangeManaged];
  
  // Simulate enter range, preload, exit range
  [cellNode enterInterfaceState:A_SInterfaceStatePreload];
  [cellNode exitInterfaceState:A_SInterfaceStatePreload];
  node.hasPreloaded = NO;
  [cellNode enterInterfaceState:A_SInterfaceStatePreload];

  XCTAssert(node.hasPreloaded);
}

- (void)testInitWithViewClass
{
  A_SDisplayNode *scrollNode = [[A_SDisplayNode alloc] initWithViewClass:[UIScrollView class]];

  XCTAssertFalse(scrollNode.isLayerBacked, @"Can't be layer backed");
  XCTAssertFalse(scrollNode.nodeLoaded, @"Shouldn't have a view yet");

  scrollNode.frame = CGRectMake(12, 52, 100, 53);
  scrollNode.alpha = 0.5;

  XCTAssertTrue([scrollNode.view isKindOfClass:[UIScrollView class]], @"scrollview should load as expected");
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(12, 52, 100, 53), scrollNode.frame), @"Should have set the frame on the scroll node");
  XCTAssertEqual(0.5f, scrollNode.alpha, @"Alpha not working");
}

- (void)testInitWithLayerClass
{
  A_SDisplayNode *transformNode = [[A_SDisplayNode alloc] initWithLayerClass:[CATransformLayer class]];

  XCTAssertTrue(transformNode.isLayerBacked, @"Created with layer class => should be layer-backed by default");
  XCTAssertFalse(transformNode.nodeLoaded, @"Shouldn't have a view yet");

  transformNode.frame = CGRectMake(12, 52, 100, 53);
  transformNode.alpha = 0.5;

  XCTAssertTrue([transformNode.layer isKindOfClass:[CATransformLayer class]], @"scrollview should load as expected");
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(12, 52, 100, 53), transformNode.frame), @"Should have set the frame on the scroll node");
  XCTAssertEqual(0.5f, transformNode.alpha, @"Alpha not working");
}

static bool stringContainsPointer(NSString *description, id p) {
  return [description rangeOfString:[NSString stringWithFormat:@"%p", p]].location != NSNotFound;
}

- (void)testDebugDescription
{
  // View node has subnodes. Make sure all of the nodes are included in the description
  A_SDisplayNode *parent = [[A_SDisplayNode alloc] init];

  A_SDisplayNode *a = [[A_SDisplayNode alloc] init];
  a.layerBacked = YES;
  A_SDisplayNode *b = [[A_SDisplayNode alloc] init];
  b.layerBacked = YES;
  b.frame = CGRectMake(0, 0, 100, 123);
  A_SDisplayNode *c = [[A_SDisplayNode alloc] init];

  for (A_SDisplayNode *child in @[a, b, c]) {
    [parent addSubnode:child];
  }

  NSString *nodeDescription = [parent displayNodeRecursiveDescription];

  // Make sure [parent recursiveDescription] contains a, b, and c's pointer string
  XCTAssertTrue(stringContainsPointer(nodeDescription, a), @"Layer backed node not present in [parent displayNodeRecursiveDescription]");
  XCTAssertTrue(stringContainsPointer(nodeDescription, b), @"Layer-backed node not present in [parent displayNodeRecursiveDescription]");
  XCTAssertTrue(stringContainsPointer(nodeDescription, c), @"View-backed node not present in [parent displayNodeRecursiveDescription]");

  NSString *viewDescription = [parent.view valueForKey:@"recursiveDescription"];

  // Make sure string contains a, b, and c's pointer string
  XCTAssertTrue(stringContainsPointer(viewDescription, a), @"Layer backed node not present");
  XCTAssertTrue(stringContainsPointer(viewDescription, b), @"Layer-backed node not present");
  XCTAssertTrue(stringContainsPointer(viewDescription, c), @"View-backed node not present");

  // Make sure layer names have display node in description
  XCTAssertTrue(stringContainsPointer([a.layer debugDescription], a), @"Layer backed node not present");
  XCTAssertTrue(stringContainsPointer([b.layer debugDescription], b), @"Layer-backed node not present");
}

- (void)checkNameInDescriptionIsLayerBacked:(BOOL)isLayerBacked
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layerBacked = isLayerBacked;

  XCTAssertFalse([node.description containsString:@"debugName"], @"Shouldn't reference 'debugName' in description");
  node.debugName = @"big troll eater name";

  XCTAssertTrue([node.description containsString:node.debugName], @"debugName didn't end up in description");
  [node layer];
  XCTAssertTrue([node.description containsString:node.debugName], @"debugName didn't end up in description");
}

- (void)testNameInDescriptionLayer
{
  [self checkNameInDescriptionIsLayerBacked:YES];
}

- (void)testNameInDescriptionView
{
  [self checkNameInDescriptionIsLayerBacked:NO];
}

- (void)testBounds
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.bounds = CGRectMake(1, 2, 3, 4);
  node.frame = CGRectMake(5, 6, 7, 8);

  XCTAssert(node.bounds.origin.x == 1, @"Wrong A_SDisplayNode.bounds.origin.x");
  XCTAssert(node.bounds.origin.y == 2, @"Wrong A_SDisplayNode.bounds.origin.y");
  XCTAssert(node.bounds.size.width == 7, @"Wrong A_SDisplayNode.bounds.size.width");
  XCTAssert(node.bounds.size.height == 8, @"Wrong A_SDisplayNode.bounds.size.height");
}

- (void)testDidEnterDisplayIsCalledWhenNodesEnterDisplayRange
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];

  [node recursivelySetInterfaceState:A_SInterfaceStateDisplay];
  
  XCTAssert([node displayRangeStateChangedToYES]);
}

- (void)testDidExitDisplayIsCalledWhenNodesExitDisplayRange
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  
  [node recursivelySetInterfaceState:A_SInterfaceStateDisplay];
  [node recursivelySetInterfaceState:A_SInterfaceStatePreload];
  
  XCTAssert([node displayRangeStateChangedToNO]);
}

- (void)testDidEnterPreloadIsCalledWhenNodesEnterPreloadRange
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  
  [node recursivelySetInterfaceState:A_SInterfaceStatePreload];
  
  XCTAssert([node preloadStateChangedToYES]);
}

- (void)testDidExitPreloadIsCalledWhenNodesExitPreloadRange
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  [node setHierarchyState:A_SHierarchyStateRangeManaged];
  
  [node recursivelySetInterfaceState:A_SInterfaceStatePreload];
  [node recursivelySetInterfaceState:A_SInterfaceStateDisplay];

  XCTAssert([node preloadStateChangedToNO]);
}


- (void)testThatNodeGetsRenderedIfItGoesFromZeroSizeToRealSizeButOnlyOnce
{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo-square"
                                                                    ofType:@"png" inDirectory:@"TestResources"];
  UIImage *image = [UIImage imageWithContentsOfFile:path];
  A_SImageNode *node = [[A_SImageNode alloc] init];
  node.image = image;

  // When rendered at zero-size, we get no contents
  XCTAssert(CGSizeEqualToSize(node.bounds.size, CGSizeZero));
  [node recursivelyEnsureDisplaySynchronously:YES];
  XCTAssertNil(node.contents);

  // When size becomes positive, we got some new contents
  node.bounds = CGRectMake(0, 0, 100, 100);
  [node recursivelyEnsureDisplaySynchronously:YES];
  id contentsAfterRedisplay = node.contents;
  XCTAssertNotNil(contentsAfterRedisplay);

  // When size changes again, we do not get new contents
  node.bounds = CGRectMake(0, 0, 1000, 1000);
  [node recursivelyEnsureDisplaySynchronously:YES];
  XCTAssertEqual(contentsAfterRedisplay, node.contents);
}

// Underlying issue for: https://github.com/facebook/Async_DisplayKit/issues/2205
- (void)testThatRasterizedNodesGetInterfaceStateUpdatesWhenContainerEntersHierarchy
{
  A_SDisplayNode *supernode = [[A_SDisplayNode alloc] init];
  [supernode enableSubtreeRasterization];
  A_SDisplayNode *subnode = [[A_SDisplayNode alloc] init];
  A_SSetDebugNames(supernode, subnode);
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [supernode addSubnode:subnode];
  [window addSubnode:supernode];
  [window makeKeyAndVisible];
  XCTAssertTrue(A_SHierarchyStateIncludesRasterized(subnode.hierarchyState));
  XCTAssertTrue(subnode.isVisible);
  [supernode.view removeFromSuperview];
  XCTAssertTrue(A_SHierarchyStateIncludesRasterized(subnode.hierarchyState));
  XCTAssertFalse(subnode.isVisible);
}

// Underlying issue for: https://github.com/facebook/Async_DisplayKit/issues/2205
- (void)testThatRasterizedNodesGetInterfaceStateUpdatesWhenAddedToContainerThatIsInHierarchy
{
  A_SDisplayNode *supernode = [[A_SDisplayNode alloc] init];
  [supernode enableSubtreeRasterization];
  A_SDisplayNode *subnode = [[A_SDisplayNode alloc] init];
  A_SSetDebugNames(supernode, subnode);

  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [window addSubnode:supernode];
  [window makeKeyAndVisible];
  [supernode addSubnode:subnode];
  XCTAssertTrue(A_SHierarchyStateIncludesRasterized(subnode.hierarchyState));
  XCTAssertTrue(subnode.isVisible);
  [subnode removeFromSupernode];
  XCTAssertFalse(A_SHierarchyStateIncludesRasterized(subnode.hierarchyState));
  XCTAssertFalse(subnode.isVisible);
}

- (void)testThatRasterizingWrapperNodesIsNotAllowed
{
  A_SDisplayNode *rasterizedSupernode = [[A_SDisplayNode alloc] init];
  [rasterizedSupernode enableSubtreeRasterization];
  A_SDisplayNode *subnode = [[A_SDisplayNode alloc] initWithViewBlock:^UIView * _Nonnull{
    return [[UIView alloc] init];
  }];
  A_SSetDebugNames(rasterizedSupernode, subnode);
  XCTAssertThrows([rasterizedSupernode addSubnode:subnode]);
}

- (void)testThatSubnodesGetDisplayUpdatesIfRasterized
{
  A_STestDisplayNode *supernode = [[A_STestDisplayNode alloc] init];
  supernode.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
  [supernode enableSubtreeRasterization];
  
  A_STestDisplayNode *subnode = [[A_STestDisplayNode alloc] init];
  A_STestDisplayNode *subSubnode = [[A_STestDisplayNode alloc] init];
  
  A_SSetDebugNames(supernode, subnode);
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [subnode addSubnode:subSubnode];
  [supernode addSubnode:subnode];
  [window addSubnode:supernode];
  [window makeKeyAndVisible];
  
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (subnode.didDisplayCount == 1);
  }));
  
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (subSubnode.didDisplayCount == 1);
  }));
  
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (subnode.displayWillStartCount == 1);
  }));
  
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (subSubnode.displayWillStartCount == 1);
  }));
}

// Underlying issue for: https://github.com/facebook/Async_DisplayKit/issues/2011
- (void)testThatLayerBackedSubnodesAreMarkedInvisibleBeforeDeallocWhenSupernodesViewIsRemovedFromHierarchyWhileBeingRetained
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

  NS_VALID_UNTIL_END_OF_SCOPE UIView *nodeView = nil;
  {
    NS_VALID_UNTIL_END_OF_SCOPE A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
    nodeView = node.view;
    node.debugName = @"Node";

    NS_VALID_UNTIL_END_OF_SCOPE A_SDisplayNode *subnode = [[A_SDisplayNode alloc] init];
    subnode.layerBacked = YES;
    [node addSubnode:subnode];
    subnode.debugName = @"Subnode";
    
    [window addSubview:nodeView];
  }

  // nodeView must continue to be retained across this call, but the nodes must not.
  XCTAssertNoThrow([nodeView removeFromSuperview]);
}

// Running on main thread
// Cause retain count of node to fall to zero synchronously on a background thread (pausing main thread)
// A_SDealloc2MainObject queues actual call to -dealloc to occur on the main thread
// Continue execution on main, before the dealloc can run, to dealloc the host view
// Node is in an invalid state (about to dealloc, not valid to retain) but accesses to sublayer delegates
// causes attempted retain — unless weak variable works correctly
- (void)testThatLayerDelegateDoesntDangleAndCauseCrash
{
  NS_VALID_UNTIL_END_OF_SCOPE UIView *host = [[UIView alloc] init];

  __block NS_VALID_UNTIL_END_OF_SCOPE A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layerBacked = YES;

  [host addSubnode:node];
  [self executeOffThread:^{
    node = nil;
  }];
  host = nil; // <- Would crash here, when UIView accesses its sublayers' delegates in -dealloc.
}

- (void)testThatSubnodeGetsInterfaceStateSetIfRasterized
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  node.debugName = @"Node";
  [node enableSubtreeRasterization];
  
  A_STestDisplayNode *subnode = [[A_STestDisplayNode alloc] init];
  subnode.debugName = @"Subnode";
  [node addSubnode:subnode];
  
  [node view]; // Node needs to be loaded
  
  [node enterInterfaceState:A_SInterfaceStatePreload];
  
  
  XCTAssertTrue((node.interfaceState & A_SInterfaceStatePreload) == A_SInterfaceStatePreload);
  XCTAssertTrue((subnode.interfaceState & A_SInterfaceStatePreload) == A_SInterfaceStatePreload);
  XCTAssertTrue(node.hasPreloaded);
  XCTAssertTrue(subnode.hasPreloaded);
}

// FIXME
// Supernode is measured, subnode isnt, transition starts, UIKit does a layout pass before measurement finishes
- (void)testThatItsSafeToAutomeasureANodeMidTransition
{
  A_SDisplayNode *supernode = [[A_SDisplayNode alloc] init];
  [supernode layoutThatFits:A_SSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.bounds = CGRectMake(0, 0, 50, 50);
  [supernode addSubnode:node];
  
  XCTAssertNil(node.calculatedLayout);
  XCTAssertTrue(node.layer.needsLayout);

  [supernode transitionLayoutWithAnimation:NO shouldMeasureAsync:YES measurementCompletion:nil];

  XCTAssertNoThrow([node.view layoutIfNeeded]);
}

- (void)testThatOnDidLoadThrowsIfCalledOnLoadedOffMain
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  [node view];
  [self executeOffThread:^{
    XCTAssertThrows([node onDidLoad:^(A_SDisplayNode * _Nonnull node) { }]);
  }];
}

- (void)testThatOnDidLoadWorks
{
  A_STestDisplayNode *node = [[A_STestDisplayNode alloc] init];
  NSMutableArray *calls = [NSMutableArray array];
  [node onDidLoad:^(A_STestDisplayNode * _Nonnull node) {
    [calls addObject:@0];
  }];
  [node onDidLoad:^(A_STestDisplayNode * _Nonnull node) {
    [calls addObject:@1];
  }];
  [node onDidLoad:^(A_STestDisplayNode * _Nonnull node) {
    [calls addObject:@2];
  }];
  [node view];
  NSArray *expected = @[ @0, @1, @2 ];
  XCTAssertEqualObjects(calls, expected);
}

- (void)testSettingPropertiesViaStyllableProtocol
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  id<A_SLayoutElement> returnedNode =
   [node styledWithBlock:^(A_SLayoutElementStyle * _Nonnull style) {
     style.width = A_SDimensionMake(100);
     style.flexGrow = 1.0;
     style.flexShrink = 1.0;
   }];
  
  XCTAssertEqualObjects(node, returnedNode);
  A_SXCTAssertEqualDimensions(node.style.width, A_SDimensionMake(100));
  XCTAssertEqual(node.style.flexGrow, 1.0, @"flexGrow should have have the value 1.0");
  XCTAssertEqual(node.style.flexShrink, 1.0, @"flexShrink should have have the value 1.0");
}

- (void)testSubnodesFastEnumeration
{
  DeclareNodeNamed(parentNode);
  DeclareNodeNamed(a);
  DeclareNodeNamed(b);
  DeclareNodeNamed(c);
  DeclareViewNamed(d);

  NSArray *subnodes = @[a, b, c, d];  
  for (A_SDisplayNode *node in subnodes) {
    [parentNode addSubnode:node];
  }
  
  NSInteger i = 0;
  for (A_SDisplayNode *subnode in parentNode.subnodes) {
    XCTAssertEqualObjects(subnode, subnodes[i]);
    i++;
  }
}

- (void)testThatHavingTheSameNodeTwiceInALayoutSpecCausesExceptionOnLayoutCalculation
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  A_SDisplayNode *subnode = [[A_SDisplayNode alloc] init];
  node.layoutSpecBlock = ^A_SLayoutSpec *(A_SDisplayNode *node, A_SSizeRange constrainedSize) {
    return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:[A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:subnode] overlay:subnode];
  };
  XCTAssertThrowsSpecificNamed([node calculateLayoutThatFits:A_SSizeRangeMake(CGSizeMake(100, 100))], NSException, NSInternalInconsistencyException);
}

- (void)testThatOverlaySpecOrdersSubnodesCorrectly
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  A_SDisplayNode *underlay = [[A_SDisplayNode alloc] init];
  underlay.debugName = @"underlay";
  A_SDisplayNode *overlay = [[A_SDisplayNode alloc] init];
  overlay.debugName = @"overlay";
  node.layoutSpecBlock = ^(A_SDisplayNode *node, A_SSizeRange size) {
    // The inset spec here is crucial. If the nodes themselves are children, it passed before the fix.
    return [A_SOverlayLayoutSpec overlayLayoutSpecWithChild:[A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:underlay] overlay:overlay];
  };
  
  A_SDisplayNodeSizeToFitSize(node, CGSizeMake(100, 100));
  [node.view layoutIfNeeded];
  
  NSInteger underlayIndex = [node.subnodes indexOfObjectIdenticalTo:underlay];
  NSInteger overlayIndex = [node.subnodes indexOfObjectIdenticalTo:overlay];
  XCTAssertLessThan(underlayIndex, overlayIndex);
}

- (void)testThatBackgroundLayoutSpecOrdersSubnodesCorrectly
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  A_SDisplayNode *underlay = [[A_SDisplayNode alloc] init];
  underlay.debugName = @"underlay";
  A_SDisplayNode *overlay = [[A_SDisplayNode alloc] init];
  overlay.debugName = @"overlay";
  node.layoutSpecBlock = ^(A_SDisplayNode *node, A_SSizeRange size) {
    // The inset spec here is crucial. If the nodes themselves are children, it passed before the fix.
    return [A_SBackgroundLayoutSpec backgroundLayoutSpecWithChild:overlay background:[A_SInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:underlay]];
  };
  
  A_SDisplayNodeSizeToFitSize(node, CGSizeMake(100, 100));
  [node.view layoutIfNeeded];
  
  NSInteger underlayIndex = [node.subnodes indexOfObjectIdenticalTo:underlay];
  NSInteger overlayIndex = [node.subnodes indexOfObjectIdenticalTo:overlay];
  XCTAssertLessThan(underlayIndex, overlayIndex);
}

- (void)testThatConvertPointGoesToWindowWhenPassedNil
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.frame = CGRectMake(10, 10, 10, 10);
  [window addSubnode:node];
  CGPoint expectedOrigin = CGPointMake(10, 10);
  A_SXCTAssertEqualPoints([node convertPoint:node.bounds.origin toNode:nil], expectedOrigin);
}

- (void)testThatConvertPointGoesToWindowWhenPassedNil_layerBacked
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  node.layerBacked = YES;
  node.frame = CGRectMake(10, 10, 10, 10);
  [window addSubnode:node];
  CGPoint expectedOrigin = CGPointMake(10, 10);
  A_SXCTAssertEqualPoints([node convertPoint:node.bounds.origin toNode:nil], expectedOrigin);
}

- (void)testThatItIsAllowedToRetrieveDebugDescriptionIncludingVCOffMainThread
{
  A_SDisplayNode *node = [[A_SDisplayNode alloc] init];
  UIViewController *vc = [[UIViewController alloc] init];
  [vc.view addSubnode:node];
  dispatch_group_t g = dispatch_group_create();
  __block NSString *debugDescription;
  dispatch_group_async(g, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
    debugDescription = [node debugDescription];
  });
  dispatch_group_wait(g, DISPATCH_TIME_FOREVER);
  // Ensure the debug description contains the VC string.
  // Have to split into two lines because XCTAssert macro can't handle the stringWithFormat:.
  BOOL hasVC = [debugDescription containsString:[NSString stringWithFormat:@"%p", vc]];
  XCTAssert(hasVC);
}

@end
