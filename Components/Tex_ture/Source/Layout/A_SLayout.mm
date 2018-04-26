//
//  A_SLayout.mm
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

#import <Async_DisplayKit/A_SLayout.h>

#import <queue>

#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SLayoutSpec+Subclasses.h>

#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>
#import <Async_DisplayKit/A_SRectTable.h>

CGPoint const A_SPointNull = {NAN, NAN};

extern BOOL A_SPointIsNull(CGPoint point)
{
  return isnan(point.x) && isnan(point.y);
}

/**
 * Creates an defined number of "    |" indent blocks for the recursive description.
 */
A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT NSString * descriptionIndents(NSUInteger indents)
{
  NSMutableString *description = [NSMutableString string];
  for (NSUInteger i = 0; i < indents; i++) {
    [description appendString:@"    |"];
  }
  if (indents > 0) {
    [description appendString:@" "];
  }
  return description;
}

A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SLayoutIsDisplayNodeType(A_SLayout *layout)
{
  return layout.type == A_SLayoutElementTypeDisplayNode;
}

A_SDISPLAYNODE_INLINE A_S_WARN_UNUSED_RESULT BOOL A_SLayoutIsFlattened(A_SLayout *layout)
{
  // A layout is flattened if its position is null, and all of its sublayouts are of type displaynode with no sublayouts.
  if (! A_SPointIsNull(layout.position)) {
    return NO;
  }
  
  for (A_SLayout *sublayout in layout.sublayouts) {
    if (A_SLayoutIsDisplayNodeType(sublayout) == NO || sublayout.sublayouts.count > 0) {
      return NO;
    }
  }
  
  return YES;
}

@interface A_SLayout () <A_SDescriptionProvider>
{
  A_SLayoutElementType _layoutElementType;
}

/*
 * Caches all sublayouts if set to YES or destroys the sublayout cache if set to NO. Defaults to NO
 */
@property (nonatomic, assign) BOOL retainSublayoutLayoutElements;

/**
 * Array for explicitly retain sublayout layout elements in case they are created and references in layoutSpecThatFits: and no one else will hold a strong reference on it
 */
@property (nonatomic, strong) NSMutableArray<id<A_SLayoutElement>> *sublayoutLayoutElements;

@property (nonatomic, strong, readonly) A_SRectTable<id<A_SLayoutElement>, id> *elementToRectTable;

@end

@implementation A_SLayout

@dynamic frame, type;

static std::atomic_bool static_retainsSublayoutLayoutElements = ATOMIC_VAR_INIT(NO);

+ (void)setShouldRetainSublayoutLayoutElements:(BOOL)shouldRetain
{
  static_retainsSublayoutLayoutElements.store(shouldRetain);
}

+ (BOOL)shouldRetainSublayoutLayoutElements
{
  return static_retainsSublayoutLayoutElements.load();
}

- (instancetype)initWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                 size:(CGSize)size
                             position:(CGPoint)position
                           sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts
{
  NSParameterAssert(layoutElement);
  
  self = [super init];
  if (self) {
#if DEBUG
    for (A_SLayout *sublayout in sublayouts) {
      A_SDisplayNodeAssert(A_SPointIsNull(sublayout.position) == NO, @"Invalid position is not allowed in sublayout.");
    }
#endif
    
    _layoutElement = layoutElement;
    
    // Read this now to avoid @c weak overhead later.
    _layoutElementType = layoutElement.layoutElementType;
    
    if (!A_SIsCGSizeValidForSize(size)) {
      A_SDisplayNodeAssert(NO, @"layoutSize is invalid and unsafe to provide to Core Animation! Release configurations will force to 0, 0.  Size = %@, node = %@", NSStringFromCGSize(size), layoutElement);
      size = CGSizeZero;
    } else {
      size = CGSizeMake(A_SCeilPixelValue(size.width), A_SCeilPixelValue(size.height));
    }
    _size = size;
    
    if (A_SPointIsNull(position) == NO) {
      _position = A_SCeilPointValues(position);
    } else {
      _position = position;
    }

    _sublayouts = sublayouts != nil ? [sublayouts copy] : @[];

    if (_sublayouts.count > 0) {
      _elementToRectTable = [A_SRectTable rectTableForWeakObjectPointers];
      for (A_SLayout *layout in sublayouts) {
        [_elementToRectTable setRect:layout.frame forKey:layout.layoutElement];
      }
    }
    
    self.retainSublayoutLayoutElements = [A_SLayout shouldRetainSublayoutLayoutElements];
  }
  
  return self;
}

- (instancetype)init
{
  A_SDisplayNodeAssert(NO, @"Use the designated initializer");
  return [self init];
}

#pragma mark - Class Constructors

+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                   size:(CGSize)size
                               position:(CGPoint)position
                             sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts
{
  return [[self alloc] initWithLayoutElement:layoutElement
                                        size:size
                                    position:position
                                  sublayouts:sublayouts];
}

+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement
                                   size:(CGSize)size
                             sublayouts:(nullable NSArray<A_SLayout *> *)sublayouts
{
  return [self layoutWithLayoutElement:layoutElement
                                  size:size
                              position:A_SPointNull
                            sublayouts:sublayouts];
}

+ (instancetype)layoutWithLayoutElement:(id<A_SLayoutElement>)layoutElement size:(CGSize)size
{
  return [self layoutWithLayoutElement:layoutElement
                                  size:size
                              position:A_SPointNull
                            sublayouts:nil];
}

#pragma mark - Sublayout Elements Caching

- (void)setRetainSublayoutLayoutElements:(BOOL)retainSublayoutLayoutElements
{
  if (_retainSublayoutLayoutElements != retainSublayoutLayoutElements) {
    _retainSublayoutLayoutElements = retainSublayoutLayoutElements;
    
    if (retainSublayoutLayoutElements == NO) {
      _sublayoutLayoutElements = nil;
    } else {
      // Add sublayouts layout elements to an internal array to retain it while the layout lives
      NSUInteger sublayoutCount = _sublayouts.count;
      if (sublayoutCount > 0) {
        _sublayoutLayoutElements = [NSMutableArray arrayWithCapacity:sublayoutCount];
        for (A_SLayout *sublayout in _sublayouts) {
          [_sublayoutLayoutElements addObject:sublayout.layoutElement];
        }
      }
    }
  }
}

#pragma mark - Layout Flattening

- (A_SLayout *)filteredNodeLayoutTree
{
  if (A_SLayoutIsFlattened(self)) {
    // All flattened layouts must have this flag enabled
    // to ensure sublayout elements are retained until the layouts are applied.
    self.retainSublayoutLayoutElements = YES;
    return self;
  }
  
  struct Context {
    A_SLayout *layout;
    CGPoint absolutePosition;
  };
  
  // Queue used to keep track of sublayouts while traversing this layout in a DFS fashion.
  std::deque<Context> queue;
  for (A_SLayout *sublayout in self.sublayouts) {
    queue.push_back({sublayout, sublayout.position});
  }
  
  NSMutableArray *flattenedSublayouts = [NSMutableArray array];
  
  while (!queue.empty()) {
    const Context context = queue.front();
    queue.pop_front();
    
    A_SLayout *layout = context.layout;
    const NSArray<A_SLayout *> *sublayouts = layout.sublayouts;
    const NSUInteger sublayoutsCount = sublayouts.count;
    const CGPoint absolutePosition = context.absolutePosition;
    
    if (A_SLayoutIsDisplayNodeType(layout)) {
      if (sublayoutsCount > 0 || CGPointEqualToPoint(A_SCeilPointValues(absolutePosition), layout.position) == NO) {
        // Only create a new layout if the existing one can't be reused, which means it has either some sublayouts or an invalid absolute position.
        layout = [A_SLayout layoutWithLayoutElement:layout.layoutElement
                                              size:layout.size
                                          position:absolutePosition
                                        sublayouts:@[]];
      }
      [flattenedSublayouts addObject:layout];
    } else if (sublayoutsCount > 0){
      std::vector<Context> sublayoutContexts;
      for (A_SLayout *sublayout in sublayouts) {
        sublayoutContexts.push_back({sublayout, absolutePosition + sublayout.position});
      }
      queue.insert(queue.cbegin(), sublayoutContexts.begin(), sublayoutContexts.end());
    }
  }
  
  A_SLayout *layout = [A_SLayout layoutWithLayoutElement:_layoutElement size:_size sublayouts:flattenedSublayouts];
  // All flattened layouts must have this flag enabled
  // to ensure sublayout elements are retained until the layouts are applied.
  layout.retainSublayoutLayoutElements = YES;
  return layout;
}

#pragma mark - Equality Checking

- (BOOL)isEqual:(id)object
{
  A_SLayout *layout = A_SDynamicCast(object, A_SLayout);
  if (layout == nil) {
    return NO;
  }

  if (!CGSizeEqualToSize(_size, layout.size)) return NO;
  if (!CGPointEqualToPoint(_position, layout.position)) return NO;
  if (_layoutElement != layout.layoutElement) return NO;

  NSArray *sublayouts = layout.sublayouts;
  if (sublayouts != _sublayouts && (sublayouts == nil || _sublayouts == nil || ![_sublayouts isEqual:sublayouts])) {
    return NO;
  }

  return YES;
}

#pragma mark - Accessors

- (A_SLayoutElementType)type
{
  return _layoutElementType;
}

- (CGRect)frameForElement:(id<A_SLayoutElement>)layoutElement
{
  return _elementToRectTable ? [_elementToRectTable rectForKey:layoutElement] : CGRectNull;
}

- (CGRect)frame
{
  CGRect subnodeFrame = CGRectZero;
  CGPoint adjustedOrigin = _position;
  if (isfinite(adjustedOrigin.x) == NO) {
    A_SDisplayNodeAssert(0, @"Layout has an invalid position");
    adjustedOrigin.x = 0;
  }
  if (isfinite(adjustedOrigin.y) == NO) {
    A_SDisplayNodeAssert(0, @"Layout has an invalid position");
    adjustedOrigin.y = 0;
  }
  subnodeFrame.origin = adjustedOrigin;
  
  CGSize adjustedSize = _size;
  if (isfinite(adjustedSize.width) == NO) {
    A_SDisplayNodeAssert(0, @"Layout has an invalid size");
    adjustedSize.width = 0;
  }
  if (isfinite(adjustedSize.height) == NO) {
    A_SDisplayNodeAssert(0, @"Layout has an invalid position");
    adjustedSize.height = 0;
  }
  subnodeFrame.size = adjustedSize;
  
  return subnodeFrame;
}

#pragma mark - Description

- (NSMutableArray <NSDictionary *> *)propertiesForDescription
{
  NSMutableArray *result = [NSMutableArray array];
  [result addObject:@{ @"size" : [NSValue valueWithCGSize:self.size] }];

  if (auto layoutElement = self.layoutElement) {
    [result addObject:@{ @"layoutElement" : layoutElement }];
  }

  auto pos = self.position;
  if (!A_SPointIsNull(pos)) {
    [result addObject:@{ @"position" : [NSValue valueWithCGPoint:pos] }];
  }
  return result;
}

- (NSString *)description
{
  return A_SObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSString *)recursiveDescription
{
  return [self _recursiveDescriptionForLayout:self level:0];
}

- (NSString *)_recursiveDescriptionForLayout:(A_SLayout *)layout level:(NSUInteger)level
{
  NSMutableString *description = [NSMutableString string];
  [description appendString:descriptionIndents(level)];
  [description appendString:[layout description]];
  for (A_SLayout *sublayout in layout.sublayouts) {
    [description appendString:@"\n"];
    [description appendString:[self _recursiveDescriptionForLayout:sublayout level:level + 1]];
  }
  return description;
}

@end

A_SLayout *A_SCalculateLayout(id<A_SLayoutElement> layoutElement, const A_SSizeRange sizeRange, const CGSize parentSize)
{
  A_SDisplayNodeCAssertNotNil(layoutElement, @"Not valid layoutElement passed in.");
  
  return [layoutElement layoutThatFits:sizeRange parentSize:parentSize];
}

A_SLayout *A_SCalculateRootLayout(id<A_SLayoutElement> rootLayoutElement, const A_SSizeRange sizeRange)
{
  A_SLayout *layout = A_SCalculateLayout(rootLayoutElement, sizeRange, sizeRange.max);
  // Here could specific verfication happen
  return layout;
}
