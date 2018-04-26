//
//  A_SInternalHelpers.h
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

#import "A_SAvailability.h"

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

A_SDISPLAYNODE_EXTERN_C_BEGIN

BOOL A_SSubclassOverridesSelector(Class superclass, Class subclass, SEL selector);
BOOL A_SSubclassOverridesClassSelector(Class superclass, Class subclass, SEL selector);

/// Replace a method from the given class with a block and returns the original method IMP
IMP A_SReplaceMethodWithBlock(Class c, SEL origSEL, id block);

/// Dispatches the given block to the main queue if not already running on the main thread
void A_SPerformBlockOnMainThread(void (^block)(void));

/// Dispatches the given block to a background queue with priority of DISPATCH_QUEUE_PRIORITY_DEFAULT if not already run on a background queue
void A_SPerformBlockOnBackgroundThread(void (^block)(void)); // DISPATCH_QUEUE_PRIORITY_DEFAULT

/// For deallocation of objects on a background thread without GCD overhead / thread explosion
void A_SPerformBackgroundDeallocation(id __strong _Nullable * _Nonnull object);

CGFloat A_SScreenScale(void);

CGSize A_SFloorSizeValues(CGSize s);

CGFloat A_SFloorPixelValue(CGFloat f);

CGPoint A_SCeilPointValues(CGPoint p);

CGSize A_SCeilSizeValues(CGSize s);

CGFloat A_SCeilPixelValue(CGFloat f);

CGFloat A_SRoundPixelValue(CGFloat f);

BOOL A_SClassRequiresMainThreadDeallocation(Class _Nullable c);

Class _Nullable A_SGetClassFromType(const char * _Nullable type);

A_SDISPLAYNODE_EXTERN_C_END

A_SDISPLAYNODE_INLINE BOOL A_SImageAlphaInfoIsOpaque(CGImageAlphaInfo info) {
  switch (info) {
    case kCGImageAlphaNone:
    case kCGImageAlphaNoneSkipLast:
    case kCGImageAlphaNoneSkipFirst:
      return YES;
    default:
      return NO;
  }
}

/**
 @summary Conditionally performs UIView geometry changes in the given block without animation.
 
 Used primarily to circumvent UITableView forcing insertion animations when explicitly told not to via
 `UITableViewRowAnimationNone`. More info: https://github.com/facebook/Async_DisplayKit/pull/445
 
 @param withoutAnimation Set to `YES` to perform given block without animation
 @param block Perform UIView geometry changes within the passed block
 */
A_SDISPLAYNODE_INLINE void A_SPerformBlockWithoutAnimation(BOOL withoutAnimation, void (^block)(void)) {
  if (withoutAnimation) {
    [UIView performWithoutAnimation:block];
  } else {
    block();
  }
}

A_SDISPLAYNODE_INLINE void A_SBoundsAndPositionForFrame(CGRect rect, CGPoint origin, CGPoint anchorPoint, CGRect *bounds, CGPoint *position)
{
  *bounds   = (CGRect){ origin, rect.size };
  *position = CGPointMake(rect.origin.x + rect.size.width * anchorPoint.x,
                          rect.origin.y + rect.size.height * anchorPoint.y);
}

@interface NSIndexPath (A_SInverseComparison)
- (NSComparisonResult)asdk_inverseCompare:(NSIndexPath *)otherIndexPath;
@end

NS_ASSUME_NONNULL_END
