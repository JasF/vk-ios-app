//
//  A_SLayoutSpec.mm
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

#import <Async_DisplayKit/A_SLayoutSpec.h>
#import <Async_DisplayKit/A_SLayoutSpecPrivate.h>

#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>
#import <Async_DisplayKit/A_STraitCollection.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>

#import <objc/runtime.h>
#import <map>
#import <vector>

@implementation A_SLayoutSpec

// Dynamic properties for A_SLayoutElements
@dynamic layoutElementType;
@synthesize debugName = _debugName;

#pragma mark - Lifecycle

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _isMutable = YES;
  _primitiveTraitCollection = A_SPrimitiveTraitCollectionMakeDefault();
  _childrenArray = [[NSMutableArray alloc] init];
  
  return self;
}

- (A_SLayoutElementType)layoutElementType
{
  return A_SLayoutElementTypeLayoutSpec;
}

- (BOOL)canLayoutAsynchronous
{
  return YES;
}

- (BOOL)implementsLayoutMethod
{
  return YES;
}

#pragma mark - Style

- (A_SLayoutElementStyle *)style
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (_style == nil) {
    _style = [[A_SLayoutElementStyle alloc] init];
  }
  return _style;
}

- (instancetype)styledWithBlock:(A_S_NOESCAPE void (^)(__kindof A_SLayoutElementStyle *style))styleBlock
{
  styleBlock(self.style);
  return self;
}

#pragma mark - Layout

A_SLayoutElementLayoutCalculationDefaults

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  return [A_SLayout layoutWithLayoutElement:self size:constrainedSize.min];
}

#pragma mark - Child

- (void)setChild:(id<A_SLayoutElement>)child
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  A_SDisplayNodeAssert(_childrenArray.count < 2, @"This layout spec does not support more than one child. Use the setChildren: or the setChild:AtIndex: API");
 
  if (child) {
    _childrenArray[0] = child;
  } else {
    if (_childrenArray.count) {
      [_childrenArray removeObjectAtIndex:0];
    }
  }
}

- (id<A_SLayoutElement>)child
{
  A_SDisplayNodeAssert(_childrenArray.count < 2, @"This layout spec does not support more than one child. Use the setChildren: or the setChild:AtIndex: API");
  
  return _childrenArray.firstObject;
}

#pragma mark - Children

- (void)setChildren:(NSArray<id<A_SLayoutElement>> *)children
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");

  [_childrenArray removeAllObjects];
  
  NSUInteger i = 0;
  for (id<A_SLayoutElement> child in children) {
    A_SDisplayNodeAssert([child conformsToProtocol:NSProtocolFromString(@"A_SLayoutElement")], @"Child %@ of spec %@ is not an A_SLayoutElement!", child, self);
    _childrenArray[i] = child;
    i += 1;
  }
}

- (nullable NSArray<id<A_SLayoutElement>> *)children
{
  return [_childrenArray copy];
}

- (NSArray<id<A_SLayoutElement>> *)sublayoutElements
{
  return [_childrenArray copy];
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained _Nullable [_Nonnull])buffer count:(NSUInteger)len
{
  return [_childrenArray countByEnumeratingWithState:state objects:buffer count:len];
}

#pragma mark - A_STraitEnvironment

- (A_STraitCollection *)asyncTraitCollection
{
  A_SDN::MutexLocker l(__instanceLock__);
  return [A_STraitCollection traitCollectionWithA_SPrimitiveTraitCollection:self.primitiveTraitCollection];
}

A_SPrimitiveTraitCollectionDefaults

#pragma mark - A_SLayoutElementStyleExtensibility

A_SLayoutElementStyleExtensibilityForwarding

#pragma mark - A_SDescriptionProvider

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  auto result = [NSMutableArray<NSDictionary *> array];
  if (NSArray *children = self.children) {
    // Use tiny descriptions because these trees can get nested very deep.
    auto tinyDescriptions = A_SArrayByFlatMapping(children, id object, A_SObjectDescriptionMakeTiny(object));
    [result addObject:@{ @"children": tinyDescriptions }];
  }
  return result;
}

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

#pragma mark - Framework Private

#if A_S_DEDUPE_LAYOUT_SPEC_TREE
- (nullable NSHashTable<id<A_SLayoutElement>> *)findDuplicatedElementsInSubtree
{
  NSHashTable *result = nil;
  NSUInteger count = 0;
  [self _findDuplicatedElementsInSubtreeWithWorkingSet:[NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality] workingCount:&count result:&result];
  return result;
}

/**
 * This method is extremely performance-sensitive, so we do some strange things.
 *
 * @param workingSet A working set of elements for use in the recursion.
 * @param workingCount The current count of the set for use in the recursion.
 * @param result The set into which to put the result. This initially points to @c nil to save time if no duplicates exist.
 */
- (void)_findDuplicatedElementsInSubtreeWithWorkingSet:(NSHashTable<id<A_SLayoutElement>> *)workingSet workingCount:(NSUInteger *)workingCount result:(NSHashTable<id<A_SLayoutElement>>  * _Nullable *)result
{
  Class layoutSpecClass = [A_SLayoutSpec class];

  for (id<A_SLayoutElement> child in self) {
    // Add the object into the set.
    [workingSet addObject:child];

    // Check that addObject: caused the count to increase.
    // This is faster than using containsObject.
    NSUInteger oldCount = *workingCount;
    NSUInteger newCount = workingSet.count;
    BOOL objectAlreadyExisted = (newCount != oldCount + 1);
    if (objectAlreadyExisted) {
      if (*result == nil) {
        *result = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
      }
      [*result addObject:child];
    } else {
      *workingCount = newCount;
      // If child is a layout spec we haven't visited, recurse its children.
      if ([child isKindOfClass:layoutSpecClass]) {
        [(A_SLayoutSpec *)child _findDuplicatedElementsInSubtreeWithWorkingSet:workingSet workingCount:workingCount result:result];
      }
    }
  }
}
#endif

#pragma mark - Debugging

- (NSString *)debugName
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _debugName;
}

- (void)setDebugName:(NSString *)debugName
{
  A_SDN::MutexLocker l(__instanceLock__);
  if (!A_SObjectIsEqual(_debugName, debugName)) {
    _debugName = [debugName copy];
  }
}

#pragma mark - A_SLayoutElementAsciiArtProtocol

- (NSString *)asciiArtString
{
  NSArray *children = self.children.count < 2 && self.child ? @[self.child] : self.children;
  return [A_SLayoutSpec asciiArtStringForChildren:children parentName:[self asciiArtName]];
}

- (NSString *)asciiArtName
{
  NSMutableString *result = [NSMutableString stringWithCString:object_getClassName(self) encoding:NSASCIIStringEncoding];
  if (_debugName) {
    [result appendFormat:@" (%@)", _debugName];
  }
  return result;
}

@end

#pragma mark - A_SWrapperLayoutSpec

@implementation A_SWrapperLayoutSpec

+ (instancetype)wrapperWithLayoutElement:(id<A_SLayoutElement>)layoutElement
{
  return [[self alloc] initWithLayoutElement:layoutElement];
}

- (instancetype)initWithLayoutElement:(id<A_SLayoutElement>)layoutElement
{
  self = [super init];
  if (self) {
    self.child = layoutElement;
  }
  return self;
}

+ (instancetype)wrapperWithLayoutElements:(NSArray<id<A_SLayoutElement>> *)layoutElements
{
  return [[self alloc] initWithLayoutElements:layoutElements];
}

- (instancetype)initWithLayoutElements:(NSArray<id<A_SLayoutElement>> *)layoutElements
{
  self = [super init];
  if (self) {
    self.children = layoutElements;
  }
  return self;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  NSArray *children = self.children;
  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:children.count];
  
  CGSize size = constrainedSize.min;
  for (id<A_SLayoutElement> child in children) {
    A_SLayout *sublayout = [child layoutThatFits:constrainedSize parentSize:constrainedSize.max];
    sublayout.position = CGPointZero;
    
    size.width = MAX(size.width,  sublayout.size.width);
    size.height = MAX(size.height, sublayout.size.height);
    
    [sublayouts addObject:sublayout];
  }
  
  return [A_SLayout layoutWithLayoutElement:self size:size sublayouts:sublayouts];
}

@end

#pragma mark - A_SLayoutSpec (Debugging)

@implementation A_SLayoutSpec (Debugging)

#pragma mark - ASCII Art Helpers

+ (NSString *)asciiArtStringForChildren:(NSArray *)children parentName:(NSString *)parentName direction:(A_SStackLayoutDirection)direction
{
  NSMutableArray *childStrings = [NSMutableArray array];
  for (id<A_SLayoutElementAsciiArtProtocol> layoutChild in children) {
    NSString *childString = [layoutChild asciiArtString];
    if (childString) {
      [childStrings addObject:childString];
    }
  }
  if (direction == A_SStackLayoutDirectionHorizontal) {
    return [A_SAsciiArtBoxCreator horizontalBoxStringForChildren:childStrings parent:parentName];
  }
  return [A_SAsciiArtBoxCreator verticalBoxStringForChildren:childStrings parent:parentName];
}

+ (NSString *)asciiArtStringForChildren:(NSArray *)children parentName:(NSString *)parentName
{
  return [self asciiArtStringForChildren:children parentName:parentName direction:A_SStackLayoutDirectionHorizontal];
}

@end
