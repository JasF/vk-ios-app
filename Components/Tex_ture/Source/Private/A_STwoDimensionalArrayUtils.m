//
//  A_STwoDimensionalArrayUtils.m
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

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_STwoDimensionalArrayUtils.h>

// Import UIKit to get [NSIndexPath indexPathForItem:inSection:] which uses
// tagged pointers.
#import <UIKit/UIKit.h>

#pragma mark - Public Methods

NSMutableArray<NSMutableArray *> *A_STwoDimensionalArrayDeepMutableCopy(NSArray<NSArray *> *array)
{
  NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
  NSInteger i = 0;
  for (NSArray *subarray in array) {
    A_SDisplayNodeCAssert([subarray isKindOfClass:[NSArray class]], @"This function expects NSArray<NSArray *> *");
    newArray[i++] = [subarray mutableCopy];
  }
  return newArray;
}

void A_SDeleteElementsInTwoDimensionalArrayAtIndexPaths(NSMutableArray *mutableArray, NSArray<NSIndexPath *> *indexPaths)
{
  if (indexPaths.count == 0) {
    return;
  }

#if A_SDISPLAYNODE_A_SSERTIONS_ENABLED
  NSArray *sortedIndexPaths = [indexPaths sortedArrayUsingSelector:@selector(asdk_inverseCompare:)];
  A_SDisplayNodeCAssert([sortedIndexPaths isEqualToArray:indexPaths], @"Expected array of index paths to be sorted in descending order.");
#endif

  /**
   * It is tempting to do something clever here and collect indexes into ranges or NSIndexSets
   * but deep down, __NSArrayM only implements removeObjectAtIndex: and so doing all that extra
   * work ends up running the same code.
   */
  for (NSIndexPath *indexPath in indexPaths) {
    NSInteger section = indexPath.section;
    if (section >= mutableArray.count) {
      A_SDisplayNodeCFailAssert(@"Invalid section index %zd – only %zd sections", section, mutableArray.count);
      continue;
    }

    NSMutableArray *subarray = mutableArray[section];
    NSInteger item = indexPath.item;
    if (item >= subarray.count) {
      A_SDisplayNodeCFailAssert(@"Invalid item index %zd – only %zd items in section %zd", item, subarray.count, section);
      continue;
    }
    [subarray removeObjectAtIndex:item];
  }
}

NSArray<NSIndexPath *> *A_SIndexPathsForTwoDimensionalArray(NSArray <NSArray *>* twoDimensionalArray)
{
  NSMutableArray *result = [NSMutableArray array];
  NSInteger section = 0;
  NSInteger i = 0;
  for (NSArray *subarray in twoDimensionalArray) {
    A_SDisplayNodeCAssert([subarray isKindOfClass:[NSArray class]], @"This function expects NSArray<NSArray *> *");
    NSInteger itemCount = subarray.count;
    for (NSInteger item = 0; item < itemCount; item++) {
      result[i++] = [NSIndexPath indexPathForItem:item inSection:section];
    }
    section++;
  }
  return result;
}

NSArray *A_SElementsInTwoDimensionalArray(NSArray <NSArray *>* twoDimensionalArray)
{
  NSMutableArray *result = [NSMutableArray array];
  NSInteger i = 0;
  for (NSArray *subarray in twoDimensionalArray) {
    A_SDisplayNodeCAssert([subarray isKindOfClass:[NSArray class]], @"This function expects NSArray<NSArray *> *");
    for (id element in subarray) {
      result[i++] = element;
    }
  }
  return result;
}

id A_SGetElementInTwoDimensionalArray(NSArray *array, NSIndexPath *indexPath)
{
  A_SDisplayNodeCAssertNotNil(indexPath, @"Expected non-nil index path");
  A_SDisplayNodeCAssert(indexPath.length == 2, @"Expected index path of length 2. Index path: %@", indexPath);
  NSInteger section = indexPath.section;
  if (array.count <= section) {
    return nil;
  }

  NSArray *innerArray = array[section];
  NSInteger item = indexPath.item;
  if (innerArray.count <= item) {
    return nil;
  }
  return innerArray[item];
}
