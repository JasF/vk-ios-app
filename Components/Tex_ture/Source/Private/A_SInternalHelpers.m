//
//  A_SInternalHelpers.m
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

#import <Async_DisplayKit/A_SInternalHelpers.h>

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <tgmath.h>

#import <Async_DisplayKit/A_SRunLoopQueue.h>
#import <Async_DisplayKit/A_SThread.h>

BOOL A_SSubclassOverridesSelector(Class superclass, Class subclass, SEL selector)
{
  if (superclass == subclass) return NO; // Even if the class implements the selector, it doesn't override itself.
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  return (superclassMethod != subclassMethod);
}

BOOL A_SSubclassOverridesClassSelector(Class superclass, Class subclass, SEL selector)
{
  if (superclass == subclass) return NO; // Even if the class implements the selector, it doesn't override itself.
  Method superclassMethod = class_getClassMethod(superclass, selector);
  Method subclassMethod = class_getClassMethod(subclass, selector);
  return (superclassMethod != subclassMethod);
}

IMP A_SReplaceMethodWithBlock(Class c, SEL origSEL, id block)
{
  NSCParameterAssert(block);
  
  // Get original method
  Method origMethod = class_getInstanceMethod(c, origSEL);
  NSCParameterAssert(origMethod);
  
  // Convert block to IMP trampoline and replace method implementation
  IMP newIMP = imp_implementationWithBlock(block);
  
  // Try adding the method if not yet in the current class
  if (!class_addMethod(c, origSEL, newIMP, method_getTypeEncoding(origMethod))) {
    return method_setImplementation(origMethod, newIMP);
  } else {
    return method_getImplementation(origMethod);
  }
}

void A_SPerformBlockOnMainThread(void (^block)(void))
{
  if (block == nil){
    return;
  }
  if (A_SDisplayNodeThreadIsMain()) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

void A_SPerformBlockOnBackgroundThread(void (^block)(void))
{
  if (block == nil){
    return;
  }
  if (A_SDisplayNodeThreadIsMain()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
  } else {
    block();
  }
}

void A_SPerformBackgroundDeallocation(id __strong _Nullable * _Nonnull object)
{
  [[A_SDeallocQueue sharedDeallocationQueue] releaseObjectInBackground:object];
}

BOOL A_SClassRequiresMainThreadDeallocation(Class c)
{
  // Specific classes
  if (c == [UIImage class] || c == [UIColor class]) {
    return NO;
  }
  
  if ([c isSubclassOfClass:[UIResponder class]]
      || [c isSubclassOfClass:[CALayer class]]
      || [c isSubclassOfClass:[UIGestureRecognizer class]]) {
    return YES;
  }

  // Apple classes with prefix
  const char *name = class_getName(c);
  if (strncmp(name, "UI", 2) == 0 || strncmp(name, "AV", 2) == 0 || strncmp(name, "CA", 2) == 0) {
    return YES;
  }
  
  // Specific Tex_ture classes
  if (strncmp(name, "A_STextKitComponents", 19) == 0) {
    return YES;
  }

  return NO;
}

Class _Nullable A_SGetClassFromType(const char  * _Nullable type)
{
  // Class types all start with @"
  if (type == NULL || strncmp(type, "@\"", 2) != 0) {
    return Nil;
  }

  // Ensure length >= 3
  size_t typeLength = strlen(type);
  if (typeLength < 3) {
    A_SDisplayNodeCFailAssert(@"Got invalid type-encoding: %s", type);
    return Nil;
  }

  // Copy type[2..(end-1)]. So @"UIImage" -> UIImage
  size_t resultLength = typeLength - 3;
  char className[resultLength + 1];
  strncpy(className, type + 2, resultLength);
  className[resultLength] = '\0';
  return objc_getClass(className);
}

CGFloat A_SScreenScale()
{
  static CGFloat __scale = 0.0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    A_SDisplayNodeCAssertMainThread();
    __scale = [[UIScreen mainScreen] scale];
  });
  return __scale;
}

CGSize A_SFloorSizeValues(CGSize s)
{
  return CGSizeMake(A_SFloorPixelValue(s.width), A_SFloorPixelValue(s.height));
}

CGFloat A_SFloorPixelValue(CGFloat f)
{
  CGFloat scale = A_SScreenScale();
  return floor(f * scale) / scale;
}

CGPoint A_SCeilPointValues(CGPoint p)
{
  return CGPointMake(A_SCeilPixelValue(p.x), A_SCeilPixelValue(p.y));
}

CGSize A_SCeilSizeValues(CGSize s)
{
  return CGSizeMake(A_SCeilPixelValue(s.width), A_SCeilPixelValue(s.height));
}

CGFloat A_SCeilPixelValue(CGFloat f)
{
  CGFloat scale = A_SScreenScale();
  return ceil(f * scale) / scale;
}

CGFloat A_SRoundPixelValue(CGFloat f)
{
  CGFloat scale = A_SScreenScale();
  return round(f * scale) / scale;
}

@implementation NSIndexPath (A_SInverseComparison)

- (NSComparisonResult)asdk_inverseCompare:(NSIndexPath *)otherIndexPath
{
  return [otherIndexPath compare:self];
}

@end
