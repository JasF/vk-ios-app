//
//  A_SLayoutSpec+Subclasses.mm
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

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SLayoutSpec.h>
#import <Async_DisplayKit/A_SLayoutSpecPrivate.h>

#pragma mark - A_SNullLayoutSpec

@interface A_SNullLayoutSpec : A_SLayoutSpec
- (instancetype)init __unavailable;
+ (A_SNullLayoutSpec *)null;
@end

@implementation A_SNullLayoutSpec : A_SLayoutSpec

+ (A_SNullLayoutSpec *)null
{
  static A_SNullLayoutSpec *sharedNullLayoutSpec = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedNullLayoutSpec = [[self alloc] init];
  });
  return sharedNullLayoutSpec;
}

- (BOOL)isMutable
{
  return NO;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SLayout layoutWithLayoutElement:self size:CGSizeZero];
}

@end


#pragma mark - A_SLayoutSpec (Subclassing)

@implementation A_SLayoutSpec (Subclassing)

#pragma mark - Child with index

- (void)setChild:(id<A_SLayoutElement>)child atIndex:(NSUInteger)index
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  
  id<A_SLayoutElement> layoutElement = child ?: [A_SNullLayoutSpec null];
  
  if (child) {
    if (_childrenArray.count < index) {
      // Fill up the array with null objects until the index
      NSInteger i = _childrenArray.count;
      while (i < index) {
        _childrenArray[i] = [A_SNullLayoutSpec null];
        i++;
      }
    }
  }
  
  // Replace object at the given index with the layoutElement
  _childrenArray[index] = layoutElement;
}

- (id<A_SLayoutElement>)childAtIndex:(NSUInteger)index
{
  id<A_SLayoutElement> layoutElement = nil;
  if (index < _childrenArray.count) {
    layoutElement = _childrenArray[index];
  }
  
  // Null layoutElement should not be accessed
  A_SDisplayNodeAssert(layoutElement != [A_SNullLayoutSpec null], @"Access child at index without set a child at that index");

  return layoutElement;
}

@end
