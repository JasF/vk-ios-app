//
//  A_SCenterLayoutSpec.mm
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

#import <Async_DisplayKit/A_SCenterLayoutSpec.h>

#import <Async_DisplayKit/A_SLayout.h>

@implementation A_SCenterLayoutSpec
{
  A_SCenterLayoutSpecCenteringOptions _centeringOptions;
  A_SCenterLayoutSpecSizingOptions _sizingOptions;
}

- (instancetype)initWithCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
                           sizingOptions:(A_SCenterLayoutSpecSizingOptions)sizingOptions
                                   child:(id<A_SLayoutElement>)child;
{
  A_SRelativeLayoutSpecPosition verticalPosition = [self verticalPositionFromCenteringOptions:centeringOptions];
  A_SRelativeLayoutSpecPosition horizontalPosition = [self horizontalPositionFromCenteringOptions:centeringOptions];
  
  if (!(self = [super initWithHorizontalPosition:horizontalPosition verticalPosition:verticalPosition sizingOption:sizingOptions child:child])) {
    return nil;
  }
  _centeringOptions = centeringOptions;
  _sizingOptions = sizingOptions;
  return self;
}

+ (instancetype)centerLayoutSpecWithCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
                                       sizingOptions:(A_SCenterLayoutSpecSizingOptions)sizingOptions
                                               child:(id<A_SLayoutElement>)child
{
  return [[self alloc] initWithCenteringOptions:centeringOptions sizingOptions:sizingOptions child:child];
}

- (void)setCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _centeringOptions = centeringOptions;
  
  [self setHorizontalPosition:[self horizontalPositionFromCenteringOptions:centeringOptions]];
  [self setVerticalPosition:[self verticalPositionFromCenteringOptions:centeringOptions]];
}

- (void)setSizingOptions:(A_SCenterLayoutSpecSizingOptions)sizingOptions
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _sizingOptions = sizingOptions;
  [self setSizingOption:sizingOptions];
}

- (A_SRelativeLayoutSpecPosition)horizontalPositionFromCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
{
  if ((centeringOptions & A_SCenterLayoutSpecCenteringX) != 0) {
    return A_SRelativeLayoutSpecPositionCenter;
  } else {
    return A_SRelativeLayoutSpecPositionNone;
  }
}

- (A_SRelativeLayoutSpecPosition)verticalPositionFromCenteringOptions:(A_SCenterLayoutSpecCenteringOptions)centeringOptions
{
  if ((centeringOptions & A_SCenterLayoutSpecCenteringY) != 0) {
    return A_SRelativeLayoutSpecPositionCenter;
  } else {
    return A_SRelativeLayoutSpecPositionNone;
  }
}

@end
