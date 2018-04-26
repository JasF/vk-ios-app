//
//  A_SControlNode.mm
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

#import <Async_DisplayKit/A_SControlNode.h>
#import <Async_DisplayKit/A_SControlNode+Subclasses.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h>
#import <Async_DisplayKit/A_SImageNode.h>
#import <Async_DisplayKit/Async_DisplayKit+Debug.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SControlTargetAction.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SThread.h>

// UIControl allows dragging some distance outside of the control itself during
// tracking. This value depends on the device idiom (25 or 70 points), so
// so replicate that effect with the same values here for our own controls.
#define kA_SControlNodeExpandedInset (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) ? -25.0f : -70.0f)

// Initial capacities for dispatch tables.
#define kA_SControlNodeEventDispatchTableInitialCapacity 4
#define kA_SControlNodeActionDispatchTableInitialCapacity 4

@interface A_SControlNode ()
{
@private
  A_SDN::RecursiveMutex _controlLock;
  
  // Control Attributes
  BOOL _enabled;
  BOOL _highlighted;

  // Tracking
  BOOL _tracking;
  BOOL _touchInside;

  // Target action pairs stored in an array for each event type
  // A_SControlEvent -> [A_STargetAction0, A_STargetAction1]
  NSMutableDictionary<id<NSCopying>, NSMutableArray<A_SControlTargetAction *> *> *_controlEventDispatchTable;
}

// Read-write overrides.
@property (nonatomic, readwrite, assign, getter=isTracking) BOOL tracking;
@property (nonatomic, readwrite, assign, getter=isTouchInside) BOOL touchInside;

/**
  @abstract Returns a key to be used in _controlEventDispatchTable that identifies the control event.
  @param controlEvent A control event.
  @result A key for use in _controlEventDispatchTable.
 */
id<NSCopying> _A_SControlNodeEventKeyForControlEvent(A_SControlNodeEvent controlEvent);

/**
  @abstract Enumerates the A_SControlNode events included mask, invoking the block for each event.
  @param mask An A_SControlNodeEvent mask.
  @param block The block to be invoked for each A_SControlNodeEvent included in mask.
 */
void _A_SEnumerateControlEventsIncludedInMaskWithBlock(A_SControlNodeEvent mask, void (^block)(A_SControlNodeEvent anEvent));

/**
 @abstract Returns the expanded bounds used to determine if a touch is considered 'inside' during tracking.
 @param controlNode A control node.
 @result The expanded bounds of the node.
 */
CGRect _A_SControlNodeGetExpandedBounds(A_SControlNode *controlNode);


@end

@implementation A_SControlNode
{
  A_SImageNode *_debugHighlightOverlay;
}

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  _enabled = YES;

  // As we have no targets yet, we start off with user interaction off. When a target is added, it'll get turned back on.
  self.userInteractionEnabled = NO;
  
  return self;
}

#if TARGET_OS_TV
- (void)didLoad
{
  // On tvOS all controls, such as buttons, interact with the focus system even if they don't have a target set on them.
  // Here we add our own internal tap gesture to handle this behaviour.
  self.userInteractionEnabled = YES;
  UITapGestureRecognizer *tapGestureRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(pressDown)];
  tapGestureRec.allowedPressTypes = @[@(UIPressTypeSelect)];
  [self.view addGestureRecognizer:tapGestureRec];
}
#endif

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
  [super setUserInteractionEnabled:userInteractionEnabled];
  self.isAccessibilityElement = userInteractionEnabled;
}

- (void)__exitHierarchy
{
  [super __exitHierarchy];
  
  // If a control node is exit the hierarchy and is tracking we have to cancel it
  if (self.tracking) {
    [self _cancelTrackingWithEvent:nil];
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-missing-super-calls"

#pragma mark - A_SDisplayNode Overrides

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  // If we're not interested in touches, we have nothing to do.
  if (!self.enabled) {
    return;
  }
  
  // Check if the tracking should start
  UITouch *theTouch = [touches anyObject];
  if (![self beginTrackingWithTouch:theTouch withEvent:event]) {
    return;
  }

  // If we get more than one touch down on us, cancel.
  // Additionally, if we're already tracking a touch, a second touch beginning is cause for cancellation.
  if (touches.count > 1 || self.tracking) {
    [self _cancelTrackingWithEvent:event];
  } else {
    // Otherwise, begin tracking.
    self.tracking = YES;

    // No need to check bounds on touchesBegan as we wouldn't get the call if it wasn't in our bounds.
    self.touchInside = YES;
    self.highlighted = YES;

    // Send the appropriate touch-down control event depending on how many times we've been tapped.
    A_SControlNodeEvent controlEventMask = (theTouch.tapCount == 1) ? A_SControlNodeEventTouchDown : A_SControlNodeEventTouchDownRepeat;
    [self sendActionsForControlEvents:controlEventMask withEvent:event];
  }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
  // If we're not interested in touches, we have nothing to do.
  if (!self.enabled) {
    return;
  }

  NSParameterAssert(touches.count == 1);
  UITouch *theTouch = [touches anyObject];
  
  // Check if tracking should continue
  if (!self.tracking || ![self continueTrackingWithTouch:theTouch withEvent:event]) {
    self.tracking = NO;
    return;
  }
  
  CGPoint touchLocation = [theTouch locationInView:self.view];

  // Update our touchInside state.
  BOOL dragIsInsideBounds = [self pointInside:touchLocation withEvent:nil];

  // Update our highlighted state.
  CGRect expandedBounds = _A_SControlNodeGetExpandedBounds(self);
  BOOL dragIsInsideExpandedBounds = CGRectContainsPoint(expandedBounds, touchLocation);
  self.touchInside = dragIsInsideExpandedBounds;
  self.highlighted = dragIsInsideExpandedBounds;

  [self sendActionsForControlEvents:(dragIsInsideBounds ? A_SControlNodeEventTouchDragInside : A_SControlNodeEventTouchDragOutside)
                          withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
  // If we're not interested in touches, we have nothing to do.
  if (!self.enabled) {
    return;
  }

  // Note that we've cancelled tracking.
  [self _cancelTrackingWithEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
  // If we're not interested in touches, we have nothing to do.
  if (!self.enabled) {
    return;
  }

  // On iPhone 6s, iOS 9.2 (and maybe other versions) sometimes calls -touchesEnded:withEvent:
  // twice on the view for one call to -touchesBegan:withEvent:. On A_SControlNode, it used to
  // trigger an action twice unintentionally. Now, we ignore that event if we're not in a tracking
  // state in order to have a correct behavior.
  // It might be related to that issue: http://www.openradar.me/22910171
  if (!self.tracking) {
    return;
  }

  NSParameterAssert([touches count] == 1);
  UITouch *theTouch = [touches anyObject];
  CGPoint touchLocation = [theTouch locationInView:self.view];

  // Update state.
  self.tracking = NO;
  self.touchInside = NO;
  self.highlighted = NO;

  // Note that we've ended tracking.
  [self endTrackingWithTouch:theTouch withEvent:event];

  // Send the appropriate touch-up control event.
  CGRect expandedBounds = _A_SControlNodeGetExpandedBounds(self);
  BOOL touchUpIsInsideExpandedBounds = CGRectContainsPoint(expandedBounds, touchLocation);

  [self sendActionsForControlEvents:(touchUpIsInsideExpandedBounds ? A_SControlNodeEventTouchUpInside : A_SControlNodeEventTouchUpOutside)
                          withEvent:event];
}

- (void)_cancelTrackingWithEvent:(UIEvent *)event
{
  // We're no longer tracking and there is no touch to be inside.
  self.tracking = NO;
  self.touchInside = NO;
  self.highlighted = NO;
  
  // Send the cancel event.
  [self sendActionsForControlEvents:A_SControlNodeEventTouchCancel withEvent:event];
}

#pragma clang diagnostic pop

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread();

  // If not enabled we should not care about receving touches
  if (! self.enabled) {
    return nil;
  }

  return [super hitTest:point withEvent:event];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
  // If we're interested in touches, this is a tap (the only gesture we care about) and passed -hitTest for us, then no, you may not begin. Sir.
  if (self.enabled && [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && gestureRecognizer.view != self.view) {
    UITapGestureRecognizer *tapRecognizer = (UITapGestureRecognizer *)gestureRecognizer;
    // Allow double-tap gestures
    return tapRecognizer.numberOfTapsRequired != 1;
  }

  // Otherwise, go ahead. :]
  return YES;
}

- (BOOL)supportsLayerBacking
{
  return super.supportsLayerBacking && !self.userInteractionEnabled;
}

#pragma mark - Action Messages

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(A_SControlNodeEvent)controlEventMask
{
  NSParameterAssert(action);
  NSParameterAssert(controlEventMask != 0);
  
  // A_SControlNode cannot be layer backed if adding a target
  A_SDisplayNodeAssert(!self.isLayerBacked, @"A_SControlNode is layer backed, will never be able to call target in target:action: pair.");
  
  A_SDN::MutexLocker l(_controlLock);

  if (!_controlEventDispatchTable) {
    _controlEventDispatchTable = [[NSMutableDictionary alloc] initWithCapacity:kA_SControlNodeEventDispatchTableInitialCapacity]; // enough to handle common types without re-hashing the dictionary when adding entries.
    
    // only show tap-able areas for views with 1 or more addTarget:action: pairs
    if ([A_SControlNode enableHitTestDebug] && _debugHighlightOverlay == nil) {
      A_SPerformBlockOnMainThread(^{
        // add a highlight overlay node with area of A_SControlNode + UIEdgeInsets
        self.clipsToBounds = NO;
        _debugHighlightOverlay = [[A_SImageNode alloc] init];
        _debugHighlightOverlay.zPosition = 1000;  // ensure we're over the top of any siblings
        _debugHighlightOverlay.layerBacked = YES;
        [self addSubnode:_debugHighlightOverlay];
      });
    }
  }
  
  // Create new target action pair
  A_SControlTargetAction *targetAction = [[A_SControlTargetAction alloc] init];
  targetAction.action = action;
  targetAction.target = target;

  // Enumerate the events in the mask, adding the target-action pair for each control event included in controlEventMask
  _A_SEnumerateControlEventsIncludedInMaskWithBlock(controlEventMask, ^
    (A_SControlNodeEvent controlEvent)
    {
      // Do we already have an event table for this control event?
      id<NSCopying> eventKey = _A_SControlNodeEventKeyForControlEvent(controlEvent);
      NSMutableArray *eventTargetActionArray = _controlEventDispatchTable[eventKey];
      
      if (!eventTargetActionArray) {
        eventTargetActionArray = [[NSMutableArray alloc] init];
      }
      
      // Remove any prior target-action pair for this event, as UIKit does.
      [eventTargetActionArray removeObject:targetAction];
      
      // Register the new target-action as the last one to be sent.
      [eventTargetActionArray addObject:targetAction];
      
      if (eventKey) {
        [_controlEventDispatchTable setObject:eventTargetActionArray forKey:eventKey];
      }
    });

  self.userInteractionEnabled = YES;
}

- (NSArray *)actionsForTarget:(id)target forControlEvent:(A_SControlNodeEvent)controlEvent
{
  NSParameterAssert(target);
  NSParameterAssert(controlEvent != 0 && controlEvent != A_SControlNodeEventAllEvents);

  A_SDN::MutexLocker l(_controlLock);
  
  // Grab the event target action array for this event.
  NSMutableArray *eventTargetActionArray = _controlEventDispatchTable[_A_SControlNodeEventKeyForControlEvent(controlEvent)];
  if (!eventTargetActionArray) {
    return nil;
  }

  NSMutableArray *actions = [[NSMutableArray alloc] init];
  
  // Collect all actions for this target.
  for (A_SControlTargetAction *targetAction in eventTargetActionArray) {
    if ((target == nil && targetAction.createdWithNoTarget) || (target != nil && target == targetAction.target)) {
      [actions addObject:NSStringFromSelector(targetAction.action)];
    }
  }
  
  return actions;
}

- (NSSet *)allTargets
{
  A_SDN::MutexLocker l(_controlLock);
  
  NSMutableSet *targets = [[NSMutableSet alloc] init];

  // Look at each event...
  for (NSMutableArray *eventTargetActionArray in [_controlEventDispatchTable objectEnumerator]) {
    // and each event's targets...
    for (A_SControlTargetAction *targetAction in eventTargetActionArray) {
      [targets addObject:targetAction.target];
    }
  }

  return targets;
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(A_SControlNodeEvent)controlEventMask
{
  NSParameterAssert(controlEventMask != 0);
  
  A_SDN::MutexLocker l(_controlLock);

  // Enumerate the events in the mask, removing the target-action pair for each control event included in controlEventMask.
  _A_SEnumerateControlEventsIncludedInMaskWithBlock(controlEventMask, ^
    (A_SControlNodeEvent controlEvent)
    {
      // Grab the dispatch table for this event (if we have it).
      id<NSCopying> eventKey = _A_SControlNodeEventKeyForControlEvent(controlEvent);
      NSMutableArray *eventTargetActionArray = _controlEventDispatchTable[eventKey];
      if (!eventTargetActionArray) {
        return;
      }
      
      NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(A_SControlTargetAction *_Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (!target || evaluatedObject.target == target) {
          if (!action) {
            return NO;
          } else if (evaluatedObject.action == action) {
            return NO;
          }
        }
        
        return YES;
      }];
      [eventTargetActionArray filterUsingPredicate:filterPredicate];
      
      if (eventTargetActionArray.count == 0) {
        // If there are no targets for this event anymore, remove it.
        [_controlEventDispatchTable removeObjectForKey:eventKey];
      }
    });
}

#pragma mark -

- (void)sendActionsForControlEvents:(A_SControlNodeEvent)controlEvents withEvent:(UIEvent *)event
{
  A_SDisplayNodeAssertMainThread(); //We access self.view below, it's not safe to call this off of main.
  NSParameterAssert(controlEvents != 0);
  
  NSMutableArray *resolvedEventTargetActionArray = [[NSMutableArray<A_SControlTargetAction *> alloc] init];
  
  _controlLock.lock();

  // Enumerate the events in the mask, invoking the target-action pairs for each.
  _A_SEnumerateControlEventsIncludedInMaskWithBlock(controlEvents, ^
    (A_SControlNodeEvent controlEvent)
    {
      // Iterate on each target action pair
      for (A_SControlTargetAction *targetAction in _controlEventDispatchTable[_A_SControlNodeEventKeyForControlEvent(controlEvent)]) {
        A_SControlTargetAction *resolvedTargetAction = [[A_SControlTargetAction alloc] init];
        resolvedTargetAction.action = targetAction.action;
        resolvedTargetAction.target = targetAction.target;
        
        // NSNull means that a nil target was set, so start at self and travel the responder chain
        if (!resolvedTargetAction.target && targetAction.createdWithNoTarget) {
          // if the target cannot perform the action, travel the responder chain to try to find something that does
          resolvedTargetAction.target = [self.view targetForAction:resolvedTargetAction.action withSender:self];
        }
        
        if (resolvedTargetAction.target) {
          [resolvedEventTargetActionArray addObject:resolvedTargetAction];
        }
      }
    });
  
  _controlLock.unlock();
  
  //We don't want to hold the lock while calling out, we could potentially walk up the ownership tree causing a deadlock.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
  for (A_SControlTargetAction *targetAction in resolvedEventTargetActionArray) {
    [targetAction.target performSelector:targetAction.action withObject:self withObject:event];
  }
#pragma clang diagnostic pop
}

#pragma mark - Convenience

id<NSCopying> _A_SControlNodeEventKeyForControlEvent(A_SControlNodeEvent controlEvent)
{
  return @(controlEvent);
}

void _A_SEnumerateControlEventsIncludedInMaskWithBlock(A_SControlNodeEvent mask, void (^block)(A_SControlNodeEvent anEvent))
{
  if (block == nil) {
    return;
  }
  // Start with our first event (touch down) and work our way up to the last event (PrimaryActionTriggered)
  for (A_SControlNodeEvent thisEvent = A_SControlNodeEventTouchDown; thisEvent <= A_SControlNodeEventPrimaryActionTriggered; thisEvent <<= 1) {
    // If it's included in the mask, invoke the block.
    if ((mask & thisEvent) == thisEvent)
      block(thisEvent);
  }
}

CGRect _A_SControlNodeGetExpandedBounds(A_SControlNode *controlNode) {
  return CGRectInset(UIEdgeInsetsInsetRect(controlNode.view.bounds, controlNode.hitTestSlop), kA_SControlNodeExpandedInset, kA_SControlNodeExpandedInset);
}

#pragma mark - For Subclasses

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)touchEvent
{
  return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)touchEvent
{
  return YES;
}

- (void)cancelTrackingWithEvent:(UIEvent *)touchEvent
{
  // Subclass hook
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)touchEvent
{
  // Subclass hook
}

#pragma mark - Debug
- (A_SImageNode *)debugHighlightOverlay
{
  return _debugHighlightOverlay;
}
@end
