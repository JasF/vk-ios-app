//
//  A_SInsetLayoutSpec.mm
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

#import <Async_DisplayKit/A_SInsetLayoutSpec.h>

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>

@interface A_SInsetLayoutSpec ()
{
  UIEdgeInsets _insets;
}
@end

/* Returns f if f is finite, substitute otherwise */
static CGFloat finite(CGFloat f, CGFloat substitute)
{
  return isinf(f) ? substitute : f;
}

/* Returns f if f is finite, 0 otherwise */
static CGFloat finiteOrZero(CGFloat f)
{
  return finite(f, 0);
}

/* Returns the inset required to center 'inner' in 'outer' */
static CGFloat centerInset(CGFloat outer, CGFloat inner)
{
  return A_SRoundPixelValue((outer - inner) / 2);
}

@implementation A_SInsetLayoutSpec

- (instancetype)initWithInsets:(UIEdgeInsets)insets child:(id<A_SLayoutElement>)child;
{
  if (!(self = [super init])) {
    return nil;
  }
  A_SDisplayNodeAssertNotNil(child, @"Child cannot be nil");
  _insets = insets;
  [self setChild:child];
  return self;
}

+ (instancetype)insetLayoutSpecWithInsets:(UIEdgeInsets)insets child:(id<A_SLayoutElement>)child
{
  return [[self alloc] initWithInsets:insets child:child];
}

- (void)setInsets:(UIEdgeInsets)insets
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _insets = insets;
}

/**
 Inset will compute a new constrained size for it's child after applying insets and re-positioning
 the child to respect the inset.
 */
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize
{
  if (self.child == nil) {
    A_SDisplayNodeAssert(NO, @"Inset spec measured without a child. The spec will do nothing.");
    return [A_SLayout layoutWithLayoutElement:self size:CGSizeZero];
  }
  
  const CGFloat insetsX = (finiteOrZero(_insets.left) + finiteOrZero(_insets.right));
  const CGFloat insetsY = (finiteOrZero(_insets.top) + finiteOrZero(_insets.bottom));

  // if either x-axis inset is infinite, let child be intrinsic width
  const CGFloat minWidth = (isinf(_insets.left) || isinf(_insets.right)) ? 0 : constrainedSize.min.width;
  // if either y-axis inset is infinite, let child be intrinsic height
  const CGFloat minHeight = (isinf(_insets.top) || isinf(_insets.bottom)) ? 0 : constrainedSize.min.height;

  const A_SSizeRange insetConstrainedSize = {
    {
      MAX(0, minWidth - insetsX),
      MAX(0, minHeight - insetsY),
    },
    {
      MAX(0, constrainedSize.max.width - insetsX),
      MAX(0, constrainedSize.max.height - insetsY),
    }
  };
  
  const CGSize insetParentSize = {
    MAX(0, parentSize.width - insetsX),
    MAX(0, parentSize.height - insetsY)
  };
  
  A_SLayout *sublayout = [self.child layoutThatFits:insetConstrainedSize parentSize:insetParentSize];

  const CGSize computedSize = A_SSizeRangeClamp(constrainedSize, {
    finite(sublayout.size.width + _insets.left + _insets.right, constrainedSize.max.width),
    finite(sublayout.size.height + _insets.top + _insets.bottom, constrainedSize.max.height),
  });

  const CGFloat x = finite(_insets.left, constrainedSize.max.width -
                           (finite(_insets.right,
                                   centerInset(constrainedSize.max.width, sublayout.size.width)) + sublayout.size.width));

  const CGFloat y = finite(_insets.top,
                           constrainedSize.max.height -
                           (finite(_insets.bottom,
                                   centerInset(constrainedSize.max.height, sublayout.size.height)) + sublayout.size.height));
  
  sublayout.position = CGPointMake(x, y);
  
  return [A_SLayout layoutWithLayoutElement:self size:computedSize sublayouts:@[sublayout]];
}

@end
