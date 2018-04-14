//
//  A_SCollectionFlowLayoutDelegate.m
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

#import <Async_DisplayKit/A_SCollectionFlowLayoutDelegate.h>

#import <Async_DisplayKit/A_SCellNode+Internal.h>
#import <Async_DisplayKit/A_SCollectionLayoutState.h>
#import <Async_DisplayKit/A_SCollectionElement.h>
#import <Async_DisplayKit/A_SCollectionLayoutContext.h>
#import <Async_DisplayKit/A_SCollectionLayoutDefines.h>
#import <Async_DisplayKit/A_SElementMap.h>
#import <Async_DisplayKit/A_SLayout.h>
#import <Async_DisplayKit/A_SStackLayoutSpec.h>

@implementation A_SCollectionFlowLayoutDelegate {
  A_SScrollDirection _scrollableDirections;
}

- (instancetype)init
{
  return [self initWithScrollableDirections:A_SScrollDirectionVerticalDirections];
}

- (instancetype)initWithScrollableDirections:(A_SScrollDirection)scrollableDirections
{
  self = [super init];
  if (self) {
    _scrollableDirections = scrollableDirections;
  }
  return self;
}

- (A_SScrollDirection)scrollableDirections
{
  A_SDisplayNodeAssertMainThread();
  return _scrollableDirections;
}

- (id)additionalInfoForLayoutWithElements:(A_SElementMap *)elements
{
  A_SDisplayNodeAssertMainThread();
  return nil;
}

+ (A_SCollectionLayoutState *)calculateLayoutWithContext:(A_SCollectionLayoutContext *)context
{
  A_SElementMap *elements = context.elements;
  NSMutableArray<A_SCellNode *> *children = A_SArrayByFlatMapping(elements.itemElements, A_SCollectionElement *element, element.node);
  if (children.count == 0) {
    return [[A_SCollectionLayoutState alloc] initWithContext:context];
  }
  
  A_SStackLayoutSpec *stackSpec = [A_SStackLayoutSpec stackLayoutSpecWithDirection:A_SStackLayoutDirectionHorizontal
                                                                         spacing:0
                                                                  justifyContent:A_SStackLayoutJustifyContentStart
                                                                      alignItems:A_SStackLayoutAlignItemsStart
                                                                        flexWrap:A_SStackLayoutFlexWrapWrap
                                                                    alignContent:A_SStackLayoutAlignContentStart
                                                                        children:children];
  stackSpec.concurrent = YES;

  A_SSizeRange sizeRange = A_SSizeRangeForCollectionLayoutThatFitsViewportSize(context.viewportSize, context.scrollableDirections);
  A_SLayout *layout = [stackSpec layoutThatFits:sizeRange];

  return [[A_SCollectionLayoutState alloc] initWithContext:context layout:layout getElementBlock:^A_SCollectionElement * _Nullable(A_SLayout * _Nonnull sublayout) {
    A_SCellNode *node = A_SDynamicCast(sublayout.layoutElement, A_SCellNode);
    return node ? node.collectionElement : nil;
  }];
}

@end
