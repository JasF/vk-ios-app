//
//  A_SScrollNode.mm
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

#import <Async_DisplayKit/A_SScrollNode.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkPrivate.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/_A_SDisplayLayer.h>

@interface A_SScrollView : UIScrollView
@end

@implementation A_SScrollView

// This special +layerClass allows A_SScrollNode to get -layout calls from -layoutSublayers.
+ (Class)layerClass
{
  return [_A_SDisplayLayer class];
}

- (A_SScrollNode *)scrollNode
{
  return (A_SScrollNode *)A_SViewToDisplayNode(self);
}

#pragma mark - _A_SDisplayView behavior substitutions
// Need these to drive interfaceState so we know when we are visible, if not nested in another range-managing element.
// Because our superclass is a true UIKit class, we cannot also subclass _A_SDisplayView.
- (void)willMoveToWindow:(UIWindow *)newWindow
{
  A_SDisplayNode *node = self.scrollNode; // Create strong reference to weak ivar.
  BOOL visible = (newWindow != nil);
  if (visible && !node.inHierarchy) {
    [node __enterHierarchy];
  }
}

- (void)didMoveToWindow
{
  A_SDisplayNode *node = self.scrollNode; // Create strong reference to weak ivar.
  BOOL visible = (self.window != nil);
  if (!visible && node.inHierarchy) {
    [node __exitHierarchy];
  }
}

@end

@implementation A_SScrollNode
{
  A_SScrollDirection _scrollableDirections;
  BOOL _automaticallyManagesContentSize;
  CGSize _contentCalculatedSizeFromLayout;
}
@dynamic view;

- (instancetype)init
{
  if (self = [super init]) {
    [self setViewBlock:^UIView *{ return [[A_SScrollView alloc] init]; }];
  }
  return self;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
                     restrictedToSize:(A_SLayoutElementSize)size
                 relativeToParentSize:(CGSize)parentSize
{
  A_SDN::MutexLocker l(__instanceLock__);  // Lock for using our instance variables.

  A_SSizeRange contentConstrainedSize = constrainedSize;
  if (A_SScrollDirectionContainsVerticalDirection(_scrollableDirections)) {
    contentConstrainedSize.max.height = CGFLOAT_MAX;
  }
  if (A_SScrollDirectionContainsHorizontalDirection(_scrollableDirections)) {
    contentConstrainedSize.max.width = CGFLOAT_MAX;
  }
  
  A_SLayout *layout = [super calculateLayoutThatFits:contentConstrainedSize
                                   restrictedToSize:size
                               relativeToParentSize:parentSize];

  if (_automaticallyManagesContentSize) {
    // To understand this code, imagine we're containing a horizontal stack set within a vertical table node.
    // Our parentSize is fixed ~375pt width, but 0 - INF height.  Our stack measures 1000pt width, 50pt height.
    // In this case, we want our scrollNode.bounds to be 375pt wide, and 50pt high.  ContentSize 1000pt, 50pt.
    // We can achieve this behavior by: 1. Always set contentSize to layout.size.  2. Set bounds to parentSize,
    // unless one dimension is not defined, in which case adopt the contentSize for that dimension.
    _contentCalculatedSizeFromLayout = layout.size;
    CGSize selfSize = parentSize;
    if (A_SPointsValidForLayout(selfSize.width) == NO) {
      selfSize.width = _contentCalculatedSizeFromLayout.width;
    }
    if (A_SPointsValidForLayout(selfSize.height) == NO) {
      selfSize.height = _contentCalculatedSizeFromLayout.height;
    }
    // Don't provide a position, as that should be set by the parent.
    layout = [A_SLayout layoutWithLayoutElement:self
                                          size:selfSize
                                    sublayouts:layout.sublayouts];
  }
  return layout;
}

- (void)layout
{
  [super layout];
  
  A_SDN::MutexLocker l(__instanceLock__);  // Lock for using our two instance variables.
  
  if (_automaticallyManagesContentSize) {
    CGSize contentSize = _contentCalculatedSizeFromLayout;
    if (A_SIsCGSizeValidForLayout(contentSize) == NO) {
      NSLog(@"%@ calculated a size in its layout spec that can't be applied to .contentSize: %@. Applying parentSize (scrollNode's bounds) instead: %@.", self, NSStringFromCGSize(contentSize), NSStringFromCGSize(self.calculatedSize));
      contentSize = self.calculatedSize;
    }
    self.view.contentSize = contentSize;
  }
}

- (BOOL)automaticallyManagesContentSize
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _automaticallyManagesContentSize;
}

- (void)setAutomaticallyManagesContentSize:(BOOL)automaticallyManagesContentSize
{
  A_SDN::MutexLocker l(__instanceLock__);
  _automaticallyManagesContentSize = automaticallyManagesContentSize;
  if (_automaticallyManagesContentSize == YES
      && A_SScrollDirectionContainsVerticalDirection(_scrollableDirections) == NO
      && A_SScrollDirectionContainsHorizontalDirection(_scrollableDirections) == NO) {
    // Set the @default value, for more user-friendly behavior of the most
    // common use cases of .automaticallyManagesContentSize.
    _scrollableDirections = A_SScrollDirectionVerticalDirections;
  }
}

- (A_SScrollDirection)scrollableDirections
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _scrollableDirections;
}

- (void)setScrollableDirections:(A_SScrollDirection)scrollableDirections
{
  A_SDN::MutexLocker l(__instanceLock__);
  _scrollableDirections = scrollableDirections;
}

@end
