//
//  A_SLayoutElementPrivate.h
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

#import <Async_DisplayKit/A_SDimension.h>
#import <UIKit/UIGeometry.h>

@protocol A_SLayoutElement;
@class A_SLayoutElementStyle;

#pragma mark - A_SLayoutElementContext

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED
@interface A_SLayoutElementContext : NSObject
@property (nonatomic) int32_t transitionID;
@end

extern int32_t const A_SLayoutElementContextInvalidTransitionID;

extern int32_t const A_SLayoutElementContextDefaultTransitionID;

// Does not currently support nesting – there must be no current context.
extern void A_SLayoutElementPushContext(A_SLayoutElementContext * context);

extern A_SLayoutElementContext * _Nullable A_SLayoutElementGetCurrentContext(void);

extern void A_SLayoutElementPopContext(void);

NS_ASSUME_NONNULL_END

#pragma mark - A_SLayoutElementLayoutDefaults

#define A_SLayoutElementLayoutCalculationDefaults \
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize\
{\
  return [self layoutThatFits:constrainedSize parentSize:constrainedSize.max];\
}\
\
- (A_SLayout *)layoutThatFits:(A_SSizeRange)constrainedSize parentSize:(CGSize)parentSize\
{\
  return [self calculateLayoutThatFits:constrainedSize restrictedToSize:self.style.size relativeToParentSize:parentSize];\
}\
\
- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize\
                     restrictedToSize:(A_SLayoutElementSize)size\
                 relativeToParentSize:(CGSize)parentSize\
{\
  const A_SSizeRange resolvedRange = A_SSizeRangeIntersect(constrainedSize, A_SLayoutElementSizeResolve(self.style.size, parentSize));\
  return [self calculateLayoutThatFits:resolvedRange];\
}\


#pragma mark - A_SLayoutElementExtensibility

// Provides extension points for elments that comply to A_SLayoutElement like A_SLayoutSpec to add additional
// properties besides the default one provided in A_SLayoutElementStyle

static const int kMaxLayoutElementBoolExtensions = 1;
static const int kMaxLayoutElementStateIntegerExtensions = 4;
static const int kMaxLayoutElementStateEdgeInsetExtensions = 1;

typedef struct A_SLayoutElementStyleExtensions {
  // Values to store extensions
  BOOL boolExtensions[kMaxLayoutElementBoolExtensions];
  NSInteger integerExtensions[kMaxLayoutElementStateIntegerExtensions];
  UIEdgeInsets edgeInsetsExtensions[kMaxLayoutElementStateEdgeInsetExtensions];
} A_SLayoutElementStyleExtensions;

#define A_SLayoutElementStyleExtensibilityForwarding \
- (void)setLayoutOptionExtensionBool:(BOOL)value atIndex:(int)idx\
{\
  [self.style setLayoutOptionExtensionBool:value atIndex:idx];\
}\
\
- (BOOL)layoutOptionExtensionBoolAtIndex:(int)idx\
{\
  return [self.style layoutOptionExtensionBoolAtIndex:idx];\
}\
\
- (void)setLayoutOptionExtensionInteger:(NSInteger)value atIndex:(int)idx\
{\
  [self.style setLayoutOptionExtensionInteger:value atIndex:idx];\
}\
\
- (NSInteger)layoutOptionExtensionIntegerAtIndex:(int)idx\
{\
  return [self.style layoutOptionExtensionIntegerAtIndex:idx];\
}\
\
- (void)setLayoutOptionExtensionEdgeInsets:(UIEdgeInsets)value atIndex:(int)idx\
{\
  [self.style setLayoutOptionExtensionEdgeInsets:value atIndex:idx];\
}\
\
- (UIEdgeInsets)layoutOptionExtensionEdgeInsetsAtIndex:(int)idx\
{\
  return [self.style layoutOptionExtensionEdgeInsetsAtIndex:idx];\
}\

