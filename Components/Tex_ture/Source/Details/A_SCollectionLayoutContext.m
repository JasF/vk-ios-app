//
//  A_SCollectionLayoutContext.m
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SCollectionLayoutContext.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext+Private.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SCollectionLayoutDelegate.h>
#import <Async_DisplayKit/A_SCollectionLayoutCache.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SHashing.h>

@implementation A_SCollectionLayoutContext {
  Class<A_SCollectionLayoutDelegate> _layoutDelegateClass;
  __weak A_SCollectionLayoutCache *_layoutCache;
}

- (instancetype)initWithViewportSize:(CGSize)viewportSize
                initialContentOffset:(CGPoint)initialContentOffset
                scrollableDirections:(A_SScrollDirection)scrollableDirections
                            elements:(A_SElementMap *)elements
                 layoutDelegateClass:(Class<A_SCollectionLayoutDelegate>)layoutDelegateClass
                         layoutCache:(A_SCollectionLayoutCache *)layoutCache
                      additionalInfo:(id)additionalInfo
{
  self = [super init];
  if (self) {
    _viewportSize = viewportSize;
    _initialContentOffset = initialContentOffset;
    _scrollableDirections = scrollableDirections;
    _elements = elements;
    _layoutDelegateClass = layoutDelegateClass;
    _layoutCache = layoutCache;
    _additionalInfo = additionalInfo;
  }
  return self;
}

- (Class<A_SCollectionLayoutDelegate>)layoutDelegateClass
{
  return _layoutDelegateClass;
}

- (A_SCollectionLayoutCache *)layoutCache
{
  return _layoutCache;
}

// NOTE: Some properties, like initialContentOffset and layoutCache are ignored in -isEqualToContext: and -hash.
// That is because contexts can be equal regardless of the content offsets or layout caches.
- (BOOL)isEqualToContext:(A_SCollectionLayoutContext *)context
{
  if (context == nil) {
    return NO;
  }

  // NOTE: A_SObjectIsEqual returns YES when both objects are nil.
  // So don't use A_SObjectIsEqual on _elements.
  // It is a weak property and 2 layouts generated from different sets of elements
  // should never be considered the same even if they are nil now.
  return CGSizeEqualToSize(_viewportSize, context.viewportSize)
  && _scrollableDirections == context.scrollableDirections
  && [_elements isEqual:context.elements]
  && _layoutDelegateClass == context.layoutDelegateClass
  && A_SObjectIsEqual(_additionalInfo, context.additionalInfo);
}

- (BOOL)isEqual:(id)other
{
  if (self == other) {
    return YES;
  }
  if (! [other isKindOfClass:[A_SCollectionLayoutContext class]]) {
    return NO;
  }
  return [self isEqualToContext:other];
}

- (NSUInteger)hash
{
  struct {
    CGSize viewportSize;
    A_SScrollDirection scrollableDirections;
    NSUInteger elementsHash;
    NSUInteger layoutDelegateClassHash;
    NSUInteger additionalInfoHash;
  } data = {
    _viewportSize,
    _scrollableDirections,
    _elements.hash,
    _layoutDelegateClass.hash,
    [_additionalInfo hash]
  };
  return A_SHashBytes(&data, sizeof(data));
}

@end
