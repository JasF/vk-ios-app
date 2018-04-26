//
//  _A_SDisplayLayer.mm
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

#import <Async_DisplayKit/_A_SDisplayLayer.h>

#import <objc/runtime.h>

#import <Async_DisplayKit/_A_SAsyncTransactionContainer.h>
#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SDisplayNodeInternal.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

@implementation _A_SDisplayLayer
{
  BOOL _attemptedDisplayWhileZeroSized;

  struct {
    BOOL delegateDidChangeBounds:1;
  } _delegateFlags;
}

@dynamic displaysAsynchronously;

#pragma mark - Properties

- (void)setDelegate:(id)delegate
{
  [super setDelegate:delegate];
  _delegateFlags.delegateDidChangeBounds = [delegate respondsToSelector:@selector(layer:didChangeBoundsWithOldValue:newValue:)];
}

- (void)setDisplaySuspended:(BOOL)displaySuspended
{
  A_SDisplayNodeAssertMainThread();
  if (_displaySuspended != displaySuspended) {
    _displaySuspended = displaySuspended;
    if (!displaySuspended) {
      // If resuming display, trigger a display now.
      [self setNeedsDisplay];
    } else {
      // If suspending display, cancel any current async display so that we don't have contents set on us when it's finished.
      [self cancelAsyncDisplay];
    }
  }
}

- (void)setBounds:(CGRect)bounds
{
  BOOL valid = A_SDisplayNodeAssertNonFatal(A_SIsCGRectValidForLayout(bounds), @"Caught attempt to set invalid bounds %@ on %@.", NSStringFromCGRect(bounds), self);
  if (!valid) {
    return;
  }
  if (_delegateFlags.delegateDidChangeBounds) {
    CGRect oldBounds = self.bounds;
    [super setBounds:bounds];
    self.asyncdisplaykit_node.threadSafeBounds = bounds;
    [(id<A_SCALayerExtendedDelegate>)self.delegate layer:self didChangeBoundsWithOldValue:oldBounds newValue:bounds];
    
  } else {
    [super setBounds:bounds];
    self.asyncdisplaykit_node.threadSafeBounds = bounds;
  }

  if (_attemptedDisplayWhileZeroSized && CGRectIsEmpty(bounds) == NO && self.needsDisplayOnBoundsChange == NO) {
    _attemptedDisplayWhileZeroSized = NO;
    [self setNeedsDisplay];
  }
}

#if DEBUG // These override is strictly to help detect application-level threading errors.  Avoid method overhead in release.
- (void)setContents:(id)contents
{
  A_SDisplayNodeAssertMainThread();
  [super setContents:contents];
}

- (void)setNeedsLayout
{
  A_SDisplayNodeAssertMainThread();
  [super setNeedsLayout];
}
#endif

- (void)layoutSublayers
{
  A_SDisplayNodeAssertMainThread();
  [super layoutSublayers];

  [self.asyncdisplaykit_node __layout];
}

- (void)setNeedsDisplay
{
  A_SDisplayNodeAssertMainThread();
  
  // FIXME: Reconsider whether we should cancel a display in progress.
  // We should definitely cancel a display that is scheduled, but unstarted display.
  [self cancelAsyncDisplay];

  // Short circuit if display is suspended. When resumed, we will setNeedsDisplay at that time.
  if (!_displaySuspended) {
    [super setNeedsDisplay];
  }
}

#pragma mark -

+ (dispatch_queue_t)displayQueue
{
  static dispatch_queue_t displayQueue = NULL;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    displayQueue = dispatch_queue_create("org.Async_DisplayKit.A_SDisplayLayer.displayQueue", DISPATCH_QUEUE_CONCURRENT);
    // we use the highpri queue to prioritize UI rendering over other async operations
    dispatch_set_target_queue(displayQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
  });

  return displayQueue;
}

+ (id)defaultValueForKey:(NSString *)key
{
  if ([key isEqualToString:@"displaysAsynchronously"]) {
    return @YES;
  } else if ([key isEqualToString:@"opaque"]) {
    return @YES;
  } else {
    return [super defaultValueForKey:key];
  }
}

#pragma mark - Display

- (void)displayImmediately
{
  // This method is a low-level bypass that avoids touching CA, including any reset of the
  // needsDisplay flag, until the .contents property is set with the result.
  // It is designed to be able to block the thread of any caller and fully execute the display.

  A_SDisplayNodeAssertMainThread();
  [self display:NO];
}

- (void)_hackResetNeedsDisplay
{
  A_SDisplayNodeAssertMainThread();
  // Don't listen to our subclasses crazy ideas about setContents by going through super
  super.contents = super.contents;
}

- (void)display
{
  A_SDisplayNodeAssertMainThread();
  [self _hackResetNeedsDisplay];

  if (self.displaySuspended) {
    return;
  }

  [self display:self.displaysAsynchronously];
}

- (void)display:(BOOL)asynchronously
{
  if (CGRectIsEmpty(self.bounds)) {
    _attemptedDisplayWhileZeroSized = YES;
  }
  
  [self.asyncDelegate displayAsyncLayer:self asynchronously:asynchronously];
}

- (void)cancelAsyncDisplay
{
  A_SDisplayNodeAssertMainThread();

  [self.asyncDelegate cancelDisplayAsyncLayer:self];
}

// e.g. <MYTextNodeLayer: 0xFFFFFF; node = <MYTextNode: 0xFFFFFFE; name = "Username node for user 179">>
- (NSString *)description
{
  NSMutableString *description = [[super description] mutableCopy];
  A_SDisplayNode *node = self.asyncdisplaykit_node;
  if (node != nil) {
    NSString *classString = [NSString stringWithFormat:@"%s-", object_getClassName(node)];
    [description replaceOccurrencesOfString:@"_A_SDisplay" withString:classString options:kNilOptions range:NSMakeRange(0, description.length)];
    NSUInteger insertionIndex = [description rangeOfString:@">"].location;
    if (insertionIndex != NSNotFound) {
      NSString *nodeString = [NSString stringWithFormat:@"; node = %@", node];
      [description insertString:nodeString atIndex:insertionIndex];
    }
  }
  return description;
}

@end
