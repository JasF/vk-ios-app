//
//  A_STraitCollection.m
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
#import <Async_DisplayKit/A_STraitCollection.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <Async_DisplayKit/A_SLayoutElement.h>

#pragma mark - A_SPrimitiveTraitCollection

extern void A_STraitCollectionPropagateDown(id<A_SLayoutElement> element, A_SPrimitiveTraitCollection traitCollection) {
  if (element) {
    element.primitiveTraitCollection = traitCollection;
  }
  
  for (id<A_SLayoutElement> subelement in element.sublayoutElements) {
    A_STraitCollectionPropagateDown(subelement, traitCollection);
  }
}

A_SPrimitiveTraitCollection A_SPrimitiveTraitCollectionMakeDefault()
{
  return (A_SPrimitiveTraitCollection) {
    // Default values can be defined in here
    .userInterfaceIdiom = UIUserInterfaceIdiomUnspecified,
    .containerSize = CGSizeZero,
  };
}

A_SPrimitiveTraitCollection A_SPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection *traitCollection)
{
  A_SPrimitiveTraitCollection environmentTraitCollection = A_SPrimitiveTraitCollectionMakeDefault();
  environmentTraitCollection.displayScale = traitCollection.displayScale;
  environmentTraitCollection.horizontalSizeClass = traitCollection.horizontalSizeClass;
  environmentTraitCollection.verticalSizeClass = traitCollection.verticalSizeClass;
  environmentTraitCollection.userInterfaceIdiom = traitCollection.userInterfaceIdiom;
  if (A_S_AT_LEA_ST_IOS9) {
    environmentTraitCollection.forceTouchCapability = traitCollection.forceTouchCapability;
  }
  return environmentTraitCollection;
}

BOOL A_SPrimitiveTraitCollectionIsEqualToA_SPrimitiveTraitCollection(A_SPrimitiveTraitCollection lhs, A_SPrimitiveTraitCollection rhs)
{
  return
    lhs.verticalSizeClass == rhs.verticalSizeClass &&
    lhs.horizontalSizeClass == rhs.horizontalSizeClass &&
    lhs.displayScale == rhs.displayScale &&
    lhs.userInterfaceIdiom == rhs.userInterfaceIdiom &&
    lhs.forceTouchCapability == rhs.forceTouchCapability &&
    CGSizeEqualToSize(lhs.containerSize, rhs.containerSize);
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
A_SDISPLAYNODE_INLINE NSString *A_S_NSStringFromUIUserInterfaceIdiom(UIUserInterfaceIdiom idiom) {
  switch (idiom) {
    case UIUserInterfaceIdiomTV:
      return @"TV";
    case UIUserInterfaceIdiomPad:
      return @"Pad";
    case UIUserInterfaceIdiomPhone:
      return @"Phone";
    case UIUserInterfaceIdiomCarPlay:
      return @"CarPlay";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
A_SDISPLAYNODE_INLINE NSString *A_S_NSStringFromUIForceTouchCapability(UIForceTouchCapability capability) {
  switch (capability) {
    case UIForceTouchCapabilityAvailable:
      return @"Available";
    case UIForceTouchCapabilityUnavailable:
      return @"Unavailable";
    default:
      return @"Unknown";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
A_SDISPLAYNODE_INLINE NSString *A_S_NSStringFromUIUserInterfaceSizeClass(UIUserInterfaceSizeClass sizeClass) {
  switch (sizeClass) {
    case UIUserInterfaceSizeClassCompact:
      return @"Compact";
    case UIUserInterfaceSizeClassRegular:
      return @"Regular";
    default:
      return @"Unspecified";
  }
}

NSString *NSStringFromA_SPrimitiveTraitCollection(A_SPrimitiveTraitCollection traits)
{
  NSMutableArray<NSDictionary *> *props = [NSMutableArray array];
  [props addObject:@{ @"userInterfaceIdiom": A_S_NSStringFromUIUserInterfaceIdiom(traits.userInterfaceIdiom) }];
  [props addObject:@{ @"containerSize": NSStringFromCGSize(traits.containerSize) }];
  [props addObject:@{ @"horizontalSizeClass": A_S_NSStringFromUIUserInterfaceSizeClass(traits.horizontalSizeClass) }];
  [props addObject:@{ @"verticalSizeClass": A_S_NSStringFromUIUserInterfaceSizeClass(traits.verticalSizeClass) }];
  [props addObject:@{ @"forceTouchCapability": A_S_NSStringFromUIForceTouchCapability(traits.forceTouchCapability) }];
  return A_SObjectDescriptionMakeWithoutObject(props);
}

#pragma mark - A_STraitCollection

@implementation A_STraitCollection

- (instancetype)initWithDisplayScale:(CGFloat)displayScale
                  userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                 horizontalSizeClass:(UIUserInterfaceSizeClass)horizontalSizeClass
                   verticalSizeClass:(UIUserInterfaceSizeClass)verticalSizeClass
                forceTouchCapability:(UIForceTouchCapability)forceTouchCapability
                       containerSize:(CGSize)windowSize
{
    self = [super init];
    if (self) {
      _displayScale = displayScale;
      _userInterfaceIdiom = userInterfaceIdiom;
      _horizontalSizeClass = horizontalSizeClass;
      _verticalSizeClass = verticalSizeClass;
      _forceTouchCapability = forceTouchCapability;
      _containerSize = windowSize;
    }
    return self;
}

+ (instancetype)traitCollectionWithDisplayScale:(CGFloat)displayScale
                             userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                            horizontalSizeClass:(UIUserInterfaceSizeClass)horizontalSizeClass
                              verticalSizeClass:(UIUserInterfaceSizeClass)verticalSizeClass
                           forceTouchCapability:(UIForceTouchCapability)forceTouchCapability
                                  containerSize:(CGSize)windowSize
{
  return [[self alloc] initWithDisplayScale:displayScale
                         userInterfaceIdiom:userInterfaceIdiom
                        horizontalSizeClass:horizontalSizeClass
                          verticalSizeClass:verticalSizeClass
                       forceTouchCapability:forceTouchCapability
                              containerSize:windowSize];
}

+ (instancetype)traitCollectionWithA_SPrimitiveTraitCollection:(A_SPrimitiveTraitCollection)traits
{
  return [self traitCollectionWithDisplayScale:traits.displayScale
                            userInterfaceIdiom:traits.userInterfaceIdiom
                           horizontalSizeClass:traits.horizontalSizeClass
                             verticalSizeClass:traits.verticalSizeClass
                          forceTouchCapability:traits.forceTouchCapability
                                 containerSize:traits.containerSize];
}

+ (instancetype)traitCollectionWithUITraitCollection:(UITraitCollection *)traitCollection
                                        containerSize:(CGSize)windowSize
{
  UIForceTouchCapability forceTouch = A_S_AT_LEA_ST_IOS9 ? traitCollection.forceTouchCapability : UIForceTouchCapabilityUnknown;
  return [self traitCollectionWithDisplayScale:traitCollection.displayScale
                            userInterfaceIdiom:traitCollection.userInterfaceIdiom
                           horizontalSizeClass:traitCollection.horizontalSizeClass
                             verticalSizeClass:traitCollection.verticalSizeClass
                          forceTouchCapability:forceTouch
                                 containerSize:windowSize];
}

- (A_SPrimitiveTraitCollection)primitiveTraitCollection
{
  return (A_SPrimitiveTraitCollection) {
    .displayScale = self.displayScale,
    .horizontalSizeClass = self.horizontalSizeClass,
    .userInterfaceIdiom = self.userInterfaceIdiom,
    .verticalSizeClass = self.verticalSizeClass,
    .forceTouchCapability = self.forceTouchCapability,
    .containerSize = self.containerSize,
  };
}

- (BOOL)isEqualToTraitCollection:(A_STraitCollection *)traitCollection
{
  if (self == traitCollection) {
    return YES;
  }

  return self.displayScale == traitCollection.displayScale &&
  self.horizontalSizeClass == traitCollection.horizontalSizeClass &&
  self.verticalSizeClass == traitCollection.verticalSizeClass &&
  self.userInterfaceIdiom == traitCollection.userInterfaceIdiom &&
  CGSizeEqualToSize(self.containerSize, traitCollection.containerSize) &&
  self.forceTouchCapability == traitCollection.forceTouchCapability;
}

@end
