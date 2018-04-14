//
//  A_STableLayoutController.m
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

#import <Async_DisplayKit/A_STableLayoutController.h>

#import <UIKit/UIKit.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SElementMap.h>

@interface A_STableLayoutController()
@end

@implementation A_STableLayoutController

- (instancetype)initWithTableView:(UITableView *)tableView
{
  if (!(self = [super init])) {
    return nil;
  }
  _tableView = tableView;
  return self;
}

#pragma mark - A_SLayoutController

- (NSHashTable<A_SCollectionElement *> *)elementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode rangeType:(A_SLayoutRangeType)rangeType map:(A_SElementMap *)map
{
  CGRect bounds = _tableView.bounds;

  A_SRangeTuningParameters tuningParameters = [self tuningParametersForRangeMode:rangeMode rangeType:rangeType];
  CGRect rangeBounds = CGRectExpandToRangeWithScrollableDirections(bounds, tuningParameters, A_SScrollDirectionVerticalDirections, scrollDirection);
  NSArray *array = [_tableView indexPathsForRowsInRect:rangeBounds];
  return A_SPointerTableByFlatMapping(array, NSIndexPath *indexPath, [map elementForItemAtIndexPath:indexPath]);
}

- (void)allElementsForScrolling:(A_SScrollDirection)scrollDirection rangeMode:(A_SLayoutRangeMode)rangeMode displaySet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)displaySet preloadSet:(NSHashTable<A_SCollectionElement *> *__autoreleasing  _Nullable *)preloadSet map:(A_SElementMap *)map
{
  if (displaySet == NULL || preloadSet == NULL) {
    return;
  }

  *displaySet = [self elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:A_SLayoutRangeTypeDisplay map:map];
  *preloadSet = [self elementsForScrolling:scrollDirection rangeMode:rangeMode rangeType:A_SLayoutRangeTypePreload map:map];
  return;
}

@end
