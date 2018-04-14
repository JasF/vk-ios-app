//
//  A_SStackLayoutSpec.mm
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

#import <Async_DisplayKit/A_SStackLayoutSpec.h>

#import <numeric>
#import <vector>

#import <Async_DisplayKit/A_SDimension.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SLayoutElement.h>
#import <Async_DisplayKit/A_SLayoutElementStylePrivate.h>
#import <Async_DisplayKit/A_SLayoutSpecUtilities.h>
#import <Async_DisplayKit/A_SLog.h>
#import <Async_DisplayKit/A_SStackPositionedLayout.h>
#import <Async_DisplayKit/A_SStackUnpositionedLayout.h>

@implementation A_SStackLayoutSpec

- (instancetype)init
{
  return [self initWithDirection:A_SStackLayoutDirectionHorizontal spacing:0.0 justifyContent:A_SStackLayoutJustifyContentStart alignItems:A_SStackLayoutAlignItemsStretch flexWrap:A_SStackLayoutFlexWrapNoWrap alignContent:A_SStackLayoutAlignContentStart lineSpacing:0.0 children:nil];
}

+ (instancetype)stackLayoutSpecWithDirection:(A_SStackLayoutDirection)direction spacing:(CGFloat)spacing justifyContent:(A_SStackLayoutJustifyContent)justifyContent alignItems:(A_SStackLayoutAlignItems)alignItems children:(NSArray *)children
{
  return [[self alloc] initWithDirection:direction spacing:spacing justifyContent:justifyContent alignItems:alignItems flexWrap:A_SStackLayoutFlexWrapNoWrap alignContent:A_SStackLayoutAlignContentStart lineSpacing: 0.0 children:children];
}

+ (instancetype)stackLayoutSpecWithDirection:(A_SStackLayoutDirection)direction spacing:(CGFloat)spacing justifyContent:(A_SStackLayoutJustifyContent)justifyContent alignItems:(A_SStackLayoutAlignItems)alignItems flexWrap:(A_SStackLayoutFlexWrap)flexWrap alignContent:(A_SStackLayoutAlignContent)alignContent children:(NSArray<id<A_SLayoutElement>> *)children
{
  return [[self alloc] initWithDirection:direction spacing:spacing justifyContent:justifyContent alignItems:alignItems flexWrap:flexWrap alignContent:alignContent lineSpacing:0.0 children:children];
}

+ (instancetype)stackLayoutSpecWithDirection:(A_SStackLayoutDirection)direction spacing:(CGFloat)spacing justifyContent:(A_SStackLayoutJustifyContent)justifyContent alignItems:(A_SStackLayoutAlignItems)alignItems flexWrap:(A_SStackLayoutFlexWrap)flexWrap alignContent:(A_SStackLayoutAlignContent)alignContent lineSpacing:(CGFloat)lineSpacing children:(NSArray<id<A_SLayoutElement>> *)children
{
  return [[self alloc] initWithDirection:direction spacing:spacing justifyContent:justifyContent alignItems:alignItems flexWrap:flexWrap alignContent:alignContent lineSpacing:lineSpacing children:children];
}

+ (instancetype)verticalStackLayoutSpec
{
  A_SStackLayoutSpec *stackLayoutSpec = [[self alloc] init];
  stackLayoutSpec.direction = A_SStackLayoutDirectionVertical;
  return stackLayoutSpec;
}

+ (instancetype)horizontalStackLayoutSpec
{
  A_SStackLayoutSpec *stackLayoutSpec = [[self alloc] init];
  stackLayoutSpec.direction = A_SStackLayoutDirectionHorizontal;
  return stackLayoutSpec;
}

- (instancetype)initWithDirection:(A_SStackLayoutDirection)direction spacing:(CGFloat)spacing justifyContent:(A_SStackLayoutJustifyContent)justifyContent alignItems:(A_SStackLayoutAlignItems)alignItems flexWrap:(A_SStackLayoutFlexWrap)flexWrap alignContent:(A_SStackLayoutAlignContent)alignContent lineSpacing:(CGFloat)lineSpacing children:(NSArray *)children
{
  if (!(self = [super init])) {
    return nil;
  }
  _direction = direction;
  _spacing = spacing;
  _horizontalAlignment = A_SHorizontalAlignmentNone;
  _verticalAlignment = A_SVerticalAlignmentNone;
  _alignItems = alignItems;
  _justifyContent = justifyContent;
  _flexWrap = flexWrap;
  _alignContent = alignContent;
  _lineSpacing = lineSpacing;
  
  [self setChildren:children];
  return self;
}

- (void)setDirection:(A_SStackLayoutDirection)direction
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  if (_direction != direction) {
    _direction = direction;
    [self resolveHorizontalAlignment];
    [self resolveVerticalAlignment];
  }
}

- (void)setHorizontalAlignment:(A_SHorizontalAlignment)horizontalAlignment
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  if (_horizontalAlignment != horizontalAlignment) {
    _horizontalAlignment = horizontalAlignment;
    [self resolveHorizontalAlignment];
  }
}

- (void)setVerticalAlignment:(A_SVerticalAlignment)verticalAlignment
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  if (_verticalAlignment != verticalAlignment) {
    _verticalAlignment = verticalAlignment;
    [self resolveVerticalAlignment];
  }
}

- (void)setAlignItems:(A_SStackLayoutAlignItems)alignItems
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  A_SDisplayNodeAssert(_horizontalAlignment == A_SHorizontalAlignmentNone, @"Cannot set this property directly because horizontalAlignment is being used");
  A_SDisplayNodeAssert(_verticalAlignment == A_SVerticalAlignmentNone, @"Cannot set this property directly because verticalAlignment is being used");
  _alignItems = alignItems;
}

- (void)setJustifyContent:(A_SStackLayoutJustifyContent)justifyContent
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  A_SDisplayNodeAssert(_horizontalAlignment == A_SHorizontalAlignmentNone, @"Cannot set this property directly because horizontalAlignment is being used");
  A_SDisplayNodeAssert(_verticalAlignment == A_SVerticalAlignmentNone, @"Cannot set this property directly because verticalAlignment is being used");
  _justifyContent = justifyContent;
}

- (void)setSpacing:(CGFloat)spacing
{
  A_SDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _spacing = spacing;
}

- (A_SLayout *)calculateLayoutThatFits:(A_SSizeRange)constrainedSize
{
  NSArray *children = self.children;
  if (children.count == 0) {
    return [A_SLayout layoutWithLayoutElement:self size:constrainedSize.min];
  }
 
  as_activity_scope_verbose(as_activity_create("Calculate stack layout", A_S_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT));
  as_log_verbose(A_SLayoutLog(), "Stack layout %@", self);
  // Accessing the style and size property is pretty costly we create layout spec children we use to figure
  // out the layout for each child
  const auto stackChildren = A_S::map(children, [&](const id<A_SLayoutElement> child) -> A_SStackLayoutSpecChild {
    A_SLayoutElementStyle *style = child.style;
    return {child, style, style.size};
  });
  
  const A_SStackLayoutSpecStyle style = {.direction = _direction, .spacing = _spacing, .justifyContent = _justifyContent, .alignItems = _alignItems, .flexWrap = _flexWrap, .alignContent = _alignContent, .lineSpacing = _lineSpacing};
  
  const auto unpositionedLayout = A_SStackUnpositionedLayout::compute(stackChildren, style, constrainedSize, _concurrent);
  const auto positionedLayout = A_SStackPositionedLayout::compute(unpositionedLayout, style, constrainedSize);
  
  if (style.direction == A_SStackLayoutDirectionVertical) {
    self.style.ascender = stackChildren.front().style.ascender;
    self.style.descender = stackChildren.back().style.descender;
  }
  
  NSMutableArray *sublayouts = [NSMutableArray array];
  for (const auto &item : positionedLayout.items) {
    [sublayouts addObject:item.layout];
  }

  return [A_SLayout layoutWithLayoutElement:self size:positionedLayout.size sublayouts:sublayouts];
}

- (void)resolveHorizontalAlignment
{
  if (_direction == A_SStackLayoutDirectionHorizontal) {
    _justifyContent = justifyContent(_horizontalAlignment, _justifyContent);
  } else {
    _alignItems = alignment(_horizontalAlignment, _alignItems);
  }
}

- (void)resolveVerticalAlignment
{
  if (_direction == A_SStackLayoutDirectionHorizontal) {
    _alignItems = alignment(_verticalAlignment, _alignItems);
  } else {
    _justifyContent = justifyContent(_verticalAlignment, _justifyContent);
  }
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  auto result = [super propertiesForDescription];

  // Add our direction
  switch (self.direction) {
    case A_SStackLayoutDirectionVertical:
      [result insertObject:@{ (id)kCFNull: @"vertical" } atIndex:0];
      break;
    case A_SStackLayoutDirectionHorizontal:
      [result insertObject:@{ (id)kCFNull: @"horizontal" } atIndex:0];
      break;
  }

  return result;
}

@end

@implementation A_SStackLayoutSpec (Debugging)

#pragma mark - A_SLayoutElementAsciiArtProtocol

- (NSString *)asciiArtString
{
  return [A_SLayoutSpec asciiArtStringForChildren:self.children parentName:[self asciiArtName] direction:self.direction];
}

@end
