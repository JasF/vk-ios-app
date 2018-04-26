//
//  A_SRelativeLayoutSpec.mm
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

#import <Async_DisplayKit/A_SRelativeLayoutSpec.h>

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SInternalHelpers.h>

@implementation A_SRelativeLayoutSpec

- (instancetype)initWithHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition verticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition sizingOption:(A_SRelativeLayoutSpecSizingOption)sizingOption child:(id<A_SLayoutElement>)child
{
  if (!(self = [super init])) {
    return nil;
  }
  A_SDisplayNodeAssertNotNil(child, @"Child cannot be nil");
  _horizontalPosition = horizontalPosition;
  _verticalPosition = verticalPosition;
  _sizingOption = sizingOption;
  [self setChild:child];
  return self;
}

+ (instancetype)relativePositionLayoutSpecWithHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition verticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition sizingOption:(A_SRelativeLayoutSpecSizingOption)sizingOption child:(id<A_SLayoutElement>)child
{
  return [[self alloc] initWithHorizontalPosition:horizontalPosition verticalPosition:verticalPosition sizingOption:sizingOption child:child];
}

- (void)setHorizontalPosition:(A_SRelativeLayoutSpecPosition)horizontalPosition
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _horizontalPosition = horizontalPosition;
}

- (void)setVerticalPosition:(A_SRelativeLayoutSpecPosition)verticalPosition {
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _verticalPosition = verticalPosition;
}

- (void)setSizingOption:(A_SRelativeLayoutSpecSizingOption)sizingOption
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _sizingOption = sizingOption;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  // If we have a finite size in any direction, pass this so that the child can resolve percentages against it.
  // Otherwise pass A_SLayoutElementParentDimensionUndefined as the size will depend on the content
  CGSize size = {
    A_SPointsValidForSize(constrainedSize.max.width) == NO ? A_SLayoutElementParentDimensionUndefined : constrainedSize.max.width,
    A_SPointsValidForSize(constrainedSize.max.height) == NO ? A_SLayoutElementParentDimensionUndefined : constrainedSize.max.height
  };
  
  // Layout the child
  const CGSize minChildSize = {
    (_horizontalPosition != A_SRelativeLayoutSpecPositionNone) ? 0 : constrainedSize.min.width,
    (_verticalPosition != A_SRelativeLayoutSpecPositionNone) ? 0 : constrainedSize.min.height,
  };
  A_SLayout *sublayout = [self.child layoutThatFits:A_SSizeRangeMake(minChildSize, constrainedSize.max) parentSize:size];
  
  // If we have an undetermined height or width, use the child size to define the layout size
  size = A_SSizeRangeClamp(constrainedSize, {
    isfinite(size.width) == NO ? sublayout.size.width : size.width,
    isfinite(size.height) == NO ? sublayout.size.height : size.height
  });
  
  // If minimum size options are set, attempt to shrink the size to the size of the child
  size = A_SSizeRangeClamp(constrainedSize, {
    MIN(size.width, (_sizingOption & A_SRelativeLayoutSpecSizingOptionMinimumWidth) != 0 ? sublayout.size.width : size.width),
    MIN(size.height, (_sizingOption & A_SRelativeLayoutSpecSizingOptionMinimumHeight) != 0 ? sublayout.size.height : size.height)
  });
  
  // Compute the position for the child on each axis according to layout parameters
  CGFloat xPosition = [self proportionOfAxisForAxisPosition:_horizontalPosition];
  CGFloat yPosition = [self proportionOfAxisForAxisPosition:_verticalPosition];
  
  sublayout.position = {
    A_SRoundPixelValue((size.width - sublayout.size.width) * xPosition),
    A_SRoundPixelValue((size.height - sublayout.size.height) * yPosition)
  };
  
  return [A_SLayout layoutWithLayoutElement:self size:size sublayouts:@[sublayout]];
}

- (CGFloat)proportionOfAxisForAxisPosition:(A_SRelativeLayoutSpecPosition)position
{
  if (position == A_SRelativeLayoutSpecPositionCenter) {
    return 0.5f;
  } else if (position == A_SRelativeLayoutSpecPositionEnd) {
    return 1.0f;
  } else {
    return 0.0f;
  }
}

@end
