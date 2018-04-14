//
//  A_SDisplayLayerTests.m
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

#import <objc/runtime.h>

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <Async_DisplayKit/Async_DisplayKit.h>

#import "A_SDisplayNodeTestsHelper.h"

static UIImage *bogusImage() {
  static UIImage *bogusImage = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{

    UIGraphicsBeginImageContext(CGSizeMake(10, 10));

    bogusImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

  });

  return bogusImage;
}

@interface _A_SDisplayLayerTestContainerLayer : CALayer
@property (nonatomic, assign, readonly) NSUInteger didCompleteTransactionCount;
@end

@implementation _A_SDisplayLayerTestContainerLayer

- (void)asyncdisplaykit_asyncTransactionContainerDidCompleteTransaction:(_A_SAsyncTransaction *)transaction
{
  _didCompleteTransactionCount++;
}

@end


@interface A_SDisplayNode (HackForTests)
- (id)initWithViewClass:(Class)viewClass;
- (id)initWithLayerClass:(Class)layerClass;
@end


@interface _A_SDisplayLayerTestLayer : _A_SDisplayLayer
{
  BOOL _isInCancelAsyncDisplay;
  BOOL _isInDisplay;
}
@property (nonatomic, assign, readonly) NSUInteger displayCount;
@property (nonatomic, assign, readonly) NSUInteger drawInContextCount;
@property (nonatomic, assign, readonly) NSUInteger setContentsAsyncCount;
@property (nonatomic, assign, readonly) NSUInteger setContentsSyncCount;
@property (nonatomic, copy, readonly) NSString *setContentsCounts;
- (BOOL)checkSetContentsCountsWithSyncCount:(NSUInteger)syncCount asyncCount:(NSUInteger)asyncCount;
@end

@implementation _A_SDisplayLayerTestLayer

- (NSString *)setContentsCounts
{
  return [NSString stringWithFormat:@"syncCount:%tu, asyncCount:%tu", _setContentsSyncCount, _setContentsAsyncCount];
}

- (BOOL)checkSetContentsCountsWithSyncCount:(NSUInteger)syncCount asyncCount:(NSUInteger)asyncCount
{
  return ((syncCount == _setContentsSyncCount) &&
          (asyncCount == _setContentsAsyncCount));
}

- (void)setContents:(id)contents
{
  [super setContents:contents];

  if (self.displaysAsynchronously) {
    if (_isInDisplay) {
      [NSException raise:NSInvalidArgumentException format:@"There is no placeholder logic in _A_SDisplayLayer, unknown caller for setContents:"];
    } else if (!_isInCancelAsyncDisplay) {
      _setContentsAsyncCount++;
    }
  } else {
    _setContentsSyncCount++;
  }
}

- (void)display
{
  _isInDisplay = YES;
  [super display];
  _isInDisplay = NO;
  _displayCount++;
}

- (void)cancelAsyncDisplay
{
  _isInCancelAsyncDisplay = YES;
  [super cancelAsyncDisplay];
  _isInCancelAsyncDisplay = NO;
}

// This should never get called. This just records if it is.
- (void)drawInContext:(CGContextRef)context
{
  [super drawInContext:context];
  _drawInContextCount++;
}

@end

typedef NS_ENUM(NSUInteger, _A_SDisplayLayerTestDelegateMode)
{
  _A_SDisplayLayerTestDelegateModeNone                 = 0,
  _A_SDisplayLayerTestDelegateModeDrawParameters       = 1 << 0,
  _A_SDisplayLayerTestDelegateModeWillDisplay          = 1 << 1,
  _A_SDisplayLayerTestDelegateModeDidDisplay           = 1 << 2,
};

typedef NS_ENUM(NSUInteger, _A_SDisplayLayerTestDelegateClassModes) {
  _A_SDisplayLayerTestDelegateClassModeNone                 = 0,
  _A_SDisplayLayerTestDelegateClassModeDisplay              = 1 << 0,
  _A_SDisplayLayerTestDelegateClassModeDrawInContext        = 1 << 1,
};

@interface _A_SDisplayLayerTestDelegate : A_SDisplayNode <_A_SDisplayLayerDelegate>

@property (nonatomic, assign) NSUInteger didDisplayCount;
@property (nonatomic, assign) NSUInteger drawParametersCount;
@property (nonatomic, assign) NSUInteger willDisplayCount;

// for _A_SDisplayLayerTestDelegateModeClassDisplay
@property (nonatomic, assign) NSUInteger displayCount;
@property (nonatomic, copy) UIImage *(^displayLayerBlock)();

// for _A_SDisplayLayerTestDelegateModeClassDrawInContext
@property (nonatomic, assign) NSUInteger drawRectCount;

@end

@implementation _A_SDisplayLayerTestDelegate {
  _A_SDisplayLayerTestDelegateMode _modes;
}

static _A_SDisplayLayerTestDelegateClassModes _class_modes;

+ (void)setClassModes:(_A_SDisplayLayerTestDelegateClassModes)classModes
{
  _class_modes = classModes;
}

- (id)initWithModes:(_A_SDisplayLayerTestDelegateMode)modes
{
  _modes = modes;

  if (!(self = [super initWithLayerClass:[_A_SDisplayLayerTestLayer class]]))
    return nil;

  return self;
}

- (void)didDisplayAsyncLayer:(_A_SDisplayLayer *)layer
{
  _didDisplayCount++;
}

- (NSObject *)drawParametersForAsyncLayer:(_A_SDisplayLayer *)layer
{
  _drawParametersCount++;
  return self;
}

- (void)willDisplayAsyncLayer:(_A_SDisplayLayer *)layer
{
  _willDisplayCount++;
}

- (BOOL)respondsToSelector:(SEL)selector
{
  if (sel_isEqual(selector, @selector(didDisplayAsyncLayer:))) {
    return (_modes & _A_SDisplayLayerTestDelegateModeDidDisplay);
  } else if (sel_isEqual(selector, @selector(drawParametersForAsyncLayer:))) {
    return (_modes & _A_SDisplayLayerTestDelegateModeDrawParameters);
  } else if (sel_isEqual(selector, @selector(willDisplayAsyncLayer:))) {
    return (_modes & _A_SDisplayLayerTestDelegateModeWillDisplay);
  } else {
    return [super respondsToSelector:selector];
  }
}

+ (BOOL)respondsToSelector:(SEL)selector
{
  if (sel_isEqual(selector, @selector(displayWithParameters:isCancelled:))) {
    return _class_modes & _A_SDisplayLayerTestDelegateClassModeDisplay;
  } else if (sel_isEqual(selector, @selector(drawRect:withParameters:isCancelled:isRasterizing:))) {
    return _class_modes & _A_SDisplayLayerTestDelegateClassModeDrawInContext;
  } else {
    return [super respondsToSelector:selector];
  }
}

// DANGER: Don't use the delegate as the parameters in real code; this is not thread-safe and just for accounting in unit tests!
+ (UIImage *)displayWithParameters:(_A_SDisplayLayerTestDelegate *)delegate isCancelled:(asdisplaynode_iscancelled_block_t)sentinelBlock
{
  UIImage *contents = bogusImage();
  if (delegate->_displayLayerBlock != NULL) {
    contents = delegate->_displayLayerBlock();
  }
  delegate->_displayCount++;
  return contents;
}

// DANGER: Don't use the delegate as the parameters in real code; this is not thread-safe and just for accounting in unit tests!
+ (void)drawRect:(CGRect)bounds withParameters:(_A_SDisplayLayerTestDelegate *)delegate isCancelled:(asdisplaynode_iscancelled_block_t)sentinelBlock isRasterizing:(BOOL)isRasterizing
{
  __atomic_add_fetch(&delegate->_drawRectCount, 1, __ATOMIC_SEQ_CST);
}

- (NSUInteger)drawRectCount
{
  return(__atomic_load_n(&_drawRectCount, __ATOMIC_SEQ_CST));
}

@end

@interface _A_SDisplayLayerTests : XCTestCase
@end

@implementation _A_SDisplayLayerTests

- (void)setUp {
  [super setUp];
  // Force bogusImage() to create+cache its image. This impacts any time-sensitive tests which call the method from
  // within the timed portion of the test. It seems that, in rare cases, this image creation can take a bit too long,
  // causing a test failure.
  bogusImage();
}

// since we're not running in an application, we need to force this display on layer the hierarchy
- (void)displayLayerRecursively:(CALayer *)layer
{
  if (layer.needsDisplay) {
    [layer displayIfNeeded];
  }
  for (CALayer *sublayer in layer.sublayers) {
    [self displayLayerRecursively:sublayer];
  }
}

- (void)waitForDisplayQueue
{
  // make sure we don't lock up the tests indefinitely; fail after 1 sec by using an async barrier
  __block BOOL didHitBarrier = NO;
  dispatch_barrier_async([_A_SDisplayLayer displayQueue], ^{
    __atomic_store_n(&didHitBarrier, YES, __ATOMIC_SEQ_CST);
  });
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{ return __atomic_load_n(&didHitBarrier, __ATOMIC_SEQ_CST); }));
}

- (void)waitForLayer:(_A_SDisplayLayerTestLayer *)layer asyncDisplayCount:(NSUInteger)count
{
  // make sure we don't lock up the tests indefinitely; fail after 1 sec of waiting for the setContents async count to increment
  // NOTE: the layer sets its contents async back on the main queue, so we need to wait for main
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (layer.setContentsAsyncCount == count);
  }));
}

- (void)waitForAsyncDelegate:(_A_SDisplayLayerTestDelegate *)asyncDelegate
{
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (asyncDelegate.didDisplayCount == 1);
  }));
}

- (void)checkDelegateDisplay:(BOOL)displaysAsynchronously
{
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDisplay];
  _A_SDisplayLayerTestDelegate *asyncDelegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:_A_SDisplayLayerTestDelegateModeDidDisplay | _A_SDisplayLayerTestDelegateModeDrawParameters];

  _A_SDisplayLayerTestLayer *layer = (_A_SDisplayLayerTestLayer *)asyncDelegate.layer;
  layer.displaysAsynchronously = displaysAsynchronously;

  if (displaysAsynchronously) {
    dispatch_suspend([_A_SDisplayLayer displayQueue]);
  }
  layer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
  [layer setNeedsDisplay];
  [layer displayIfNeeded];

  if (displaysAsynchronously) {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
    XCTAssertEqual(layer.displayCount, 1u);
    XCTAssertEqual(layer.drawInContextCount, 0u);
    dispatch_resume([_A_SDisplayLayer displayQueue]);
    [self waitForDisplayQueue];
    [self waitForAsyncDelegate:asyncDelegate];
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer.setContentsCounts);
  } else {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:1 asyncCount:0], @"%@", layer.setContentsCounts);
  }

  XCTAssertFalse(layer.needsDisplay);
  XCTAssertEqual(layer.displayCount, 1u);
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.didDisplayCount, 1u);
  XCTAssertEqual(asyncDelegate.displayCount, 1u);
}

- (void)testDelegateDisplaySync
{
  [self checkDelegateDisplay:NO];
}

- (void)testDelegateDisplayAsync
{
  [self checkDelegateDisplay:YES];
}

- (void)checkDelegateDrawInContext:(BOOL)displaysAsynchronously
{
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDrawInContext];
  _A_SDisplayLayerTestDelegate *asyncDelegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:_A_SDisplayLayerTestDelegateModeDidDisplay | _A_SDisplayLayerTestDelegateModeDrawParameters];

  _A_SDisplayLayerTestLayer *layer = (_A_SDisplayLayerTestLayer *)asyncDelegate.layer;
  layer.displaysAsynchronously = displaysAsynchronously;

  if (displaysAsynchronously) {
    dispatch_suspend([_A_SDisplayLayer displayQueue]);
  }
  layer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
  [layer setNeedsDisplay];
  [layer displayIfNeeded];

  if (displaysAsynchronously) {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
    XCTAssertEqual(layer.displayCount, 1u);
    XCTAssertEqual(layer.drawInContextCount, 0u);
    XCTAssertEqual(asyncDelegate.drawRectCount, 0u);
    dispatch_resume([_A_SDisplayLayer displayQueue]);
    [self waitForLayer:layer asyncDisplayCount:1];
    [self waitForAsyncDelegate:asyncDelegate];
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer.setContentsCounts);
  } else {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:1 asyncCount:0], @"%@", layer.setContentsCounts);
  }

  XCTAssertFalse(layer.needsDisplay);
  XCTAssertEqual(layer.displayCount, 1u);
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.didDisplayCount, 1u);
  XCTAssertEqual(asyncDelegate.displayCount, 0u);
  XCTAssertEqual(asyncDelegate.drawParametersCount, 1u);
  XCTAssertEqual(asyncDelegate.drawRectCount, 1u);
}

- (void)testDelegateDrawInContextSync
{
  [self checkDelegateDrawInContext:NO];
}

- (void)testDelegateDrawInContextAsync
{
  [self checkDelegateDrawInContext:YES];
}

- (void)checkDelegateDisplayAndDrawInContext:(BOOL)displaysAsynchronously
{
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDisplay | _A_SDisplayLayerTestDelegateClassModeDrawInContext];
  _A_SDisplayLayerTestDelegate *asyncDelegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:_A_SDisplayLayerTestDelegateModeDidDisplay | _A_SDisplayLayerTestDelegateModeDrawParameters];

  _A_SDisplayLayerTestLayer *layer = (_A_SDisplayLayerTestLayer *)asyncDelegate.layer;
  layer.displaysAsynchronously = displaysAsynchronously;

  if (displaysAsynchronously) {
    dispatch_suspend([_A_SDisplayLayer displayQueue]);
  }
  layer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
  [layer setNeedsDisplay];
  [layer displayIfNeeded];

  if (displaysAsynchronously) {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
    XCTAssertEqual(layer.displayCount, 1u);
    XCTAssertEqual(asyncDelegate.drawParametersCount, 1u);
    XCTAssertEqual(asyncDelegate.drawRectCount, 0u);
    dispatch_resume([_A_SDisplayLayer displayQueue]);
    [self waitForDisplayQueue];
    [self waitForAsyncDelegate:asyncDelegate];
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer.setContentsCounts);
  } else {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:1 asyncCount:0], @"%@", layer.setContentsCounts);
  }

  XCTAssertFalse(layer.needsDisplay);
  XCTAssertEqual(layer.displayCount, 1u);
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.didDisplayCount, 1u);
  XCTAssertEqual(asyncDelegate.displayCount, 1u);
  XCTAssertEqual(asyncDelegate.drawParametersCount, 1u);
  XCTAssertEqual(asyncDelegate.drawRectCount, 0u);
}

- (void)testDelegateDisplayAndDrawInContextSync
{
  [self checkDelegateDisplayAndDrawInContext:NO];
}

- (void)testDelegateDisplayAndDrawInContextAsync
{
  [self checkDelegateDisplayAndDrawInContext:YES];
}

- (void)testCancelAsyncDisplay
{
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDisplay];
  _A_SDisplayLayerTestDelegate *asyncDelegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:_A_SDisplayLayerTestDelegateModeDidDisplay];
  _A_SDisplayLayerTestLayer *layer = (_A_SDisplayLayerTestLayer *)asyncDelegate.layer;

  dispatch_suspend([_A_SDisplayLayer displayQueue]);
  layer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);
  [layer setNeedsDisplay];
  XCTAssertTrue(layer.needsDisplay);
  [layer displayIfNeeded];

  XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
  XCTAssertFalse(layer.needsDisplay);
  XCTAssertEqual(layer.displayCount, 1u);
  XCTAssertEqual(layer.drawInContextCount, 0u);

  [layer cancelAsyncDisplay];

  dispatch_resume([_A_SDisplayLayer displayQueue]);
  [self waitForDisplayQueue];
  XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
  XCTAssertEqual(layer.displayCount, 1u);
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.didDisplayCount, 0u);
  XCTAssertEqual(asyncDelegate.displayCount, 0u);
  XCTAssertEqual(asyncDelegate.drawParametersCount, 0u);
}

- (void)DISABLED_testTransaction
{
  _A_SDisplayLayerTestDelegateMode delegateModes = _A_SDisplayLayerTestDelegateModeDidDisplay | _A_SDisplayLayerTestDelegateModeDrawParameters;
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDisplay];

  // Setup
  _A_SDisplayLayerTestContainerLayer *containerLayer = [[_A_SDisplayLayerTestContainerLayer alloc] init];
  containerLayer.asyncdisplaykit_asyncTransactionContainer = YES;
  containerLayer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);

  _A_SDisplayLayerTestDelegate *layer1Delegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:delegateModes];
  _A_SDisplayLayerTestLayer *layer1 = (_A_SDisplayLayerTestLayer *)layer1Delegate.layer;
  layer1.displaysAsynchronously = YES;

  dispatch_semaphore_t displayAsyncLayer1Sema = dispatch_semaphore_create(0);
  layer1Delegate.displayLayerBlock = ^(_A_SDisplayLayer *asyncLayer) {
    dispatch_semaphore_wait(displayAsyncLayer1Sema, DISPATCH_TIME_FOREVER);
    return bogusImage();
  };
  layer1.backgroundColor = [UIColor blackColor].CGColor;
  layer1.frame = CGRectMake(0.0, 0.0, 333.0, 123.0);
  [containerLayer addSublayer:layer1];

  _A_SDisplayLayerTestDelegate *layer2Delegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:delegateModes];
  _A_SDisplayLayerTestLayer *layer2 = (_A_SDisplayLayerTestLayer *)layer2Delegate.layer;
  layer2.displaysAsynchronously = YES;
  layer2.backgroundColor = [UIColor blackColor].CGColor;
  layer2.frame = CGRectMake(0.0, 50.0, 97.0, 50.0);
  [containerLayer addSublayer:layer2];

  dispatch_suspend([_A_SDisplayLayer displayQueue]);

  // display below if needed
  [layer1 setNeedsDisplay];
  [layer2 setNeedsDisplay];
  [containerLayer setNeedsDisplay];
  [self displayLayerRecursively:containerLayer];

  // check state before running displayQueue
  XCTAssertTrue([layer1 checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer1.setContentsCounts);
  XCTAssertEqual(layer1.displayCount, 1u);
  XCTAssertEqual(layer1Delegate.displayCount, 0u);
  XCTAssertTrue([layer2 checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer2.setContentsCounts);
  XCTAssertEqual(layer2.displayCount, 1u);
  XCTAssertEqual(layer1Delegate.displayCount, 0u);
  XCTAssertEqual(containerLayer.didCompleteTransactionCount, 0u);

  // run displayQueue until async display for layer2 has been run
  dispatch_resume([_A_SDisplayLayer displayQueue]);
  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (layer2Delegate.displayCount == 1);
  }));

  // check layer1 has not had async display run
  XCTAssertTrue([layer1 checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer1.setContentsCounts);
  XCTAssertEqual(layer1.displayCount, 1u);
  XCTAssertEqual(layer1Delegate.displayCount, 0u);
  // check layer2 has had async display run
  XCTAssertTrue([layer2 checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer2.setContentsCounts);
  XCTAssertEqual(layer2.displayCount, 1u);
  XCTAssertEqual(layer2Delegate.displayCount, 1u);
  XCTAssertEqual(containerLayer.didCompleteTransactionCount, 0u);


  // allow layer1 to complete display
  dispatch_semaphore_signal(displayAsyncLayer1Sema);
  [self waitForLayer:layer1 asyncDisplayCount:1];

  // check that both layers have completed display
  XCTAssertTrue([layer1 checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer1.setContentsCounts);
  XCTAssertEqual(layer1.displayCount, 1u);
  XCTAssertEqual(layer1Delegate.displayCount, 1u);
  XCTAssertTrue([layer2 checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer2.setContentsCounts);
  XCTAssertEqual(layer2.displayCount, 1u);
  XCTAssertEqual(layer2Delegate.displayCount, 1u);

  XCTAssertTrue(A_SDisplayNodeRunRunLoopUntilBlockIsTrue(^BOOL{
    return (containerLayer.didCompleteTransactionCount == 1);
  }));
}

- (void)checkSuspendResume:(BOOL)displaysAsynchronously
{
  [_A_SDisplayLayerTestDelegate setClassModes:_A_SDisplayLayerTestDelegateClassModeDrawInContext];
  _A_SDisplayLayerTestDelegate *asyncDelegate = [[_A_SDisplayLayerTestDelegate alloc] initWithModes:_A_SDisplayLayerTestDelegateModeDidDisplay | _A_SDisplayLayerTestDelegateModeDrawParameters];

  _A_SDisplayLayerTestLayer *layer = (_A_SDisplayLayerTestLayer *)asyncDelegate.layer;
  layer.displaysAsynchronously = displaysAsynchronously;
  layer.frame = CGRectMake(0.0, 0.0, 100.0, 100.0);

  if (displaysAsynchronously) {
    dispatch_suspend([_A_SDisplayLayer displayQueue]);
  }

  // Layer shouldn't display because display is suspended
  layer.displaySuspended = YES;
  [layer setNeedsDisplay];
  [layer displayIfNeeded];
  XCTAssertEqual(layer.displayCount, 0u, @"Should not have displayed because display is suspended, thus -setNeedsDisplay is a no-op");
  XCTAssertFalse(layer.needsDisplay, @"Should not need display");
  if (displaysAsynchronously) {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
    dispatch_resume([_A_SDisplayLayer displayQueue]);
    [self waitForDisplayQueue];
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
  } else {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
  }
  XCTAssertFalse(layer.needsDisplay);
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.drawRectCount, 0u);

  // Layer should display because display is resumed
  if (displaysAsynchronously) {
    dispatch_suspend([_A_SDisplayLayer displayQueue]);
  }
  layer.displaySuspended = NO;
  XCTAssertTrue(layer.needsDisplay);
  [layer displayIfNeeded];
  XCTAssertEqual(layer.displayCount, 1u);
  if (displaysAsynchronously) {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:0], @"%@", layer.setContentsCounts);
    XCTAssertEqual(layer.drawInContextCount, 0u);
    XCTAssertEqual(asyncDelegate.drawRectCount, 0u);
    dispatch_resume([_A_SDisplayLayer displayQueue]);
    [self waitForLayer:layer asyncDisplayCount:1];
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:0 asyncCount:1], @"%@", layer.setContentsCounts);
  } else {
    XCTAssertTrue([layer checkSetContentsCountsWithSyncCount:1 asyncCount:0], @"%@", layer.setContentsCounts);
  }
  XCTAssertEqual(layer.drawInContextCount, 0u);
  XCTAssertEqual(asyncDelegate.drawParametersCount, 1u);
  XCTAssertEqual(asyncDelegate.drawRectCount, 1u);
  XCTAssertFalse(layer.needsDisplay);
}

- (void)testSuspendResumeAsync
{
  [self checkSuspendResume:YES];
}

- (void)testSuspendResumeSync
{
  [self checkSuspendResume:NO];
}

@end
