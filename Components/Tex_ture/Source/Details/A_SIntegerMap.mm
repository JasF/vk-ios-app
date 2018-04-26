//
//  A_SIntegerMap.mm
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "A_SIntegerMap.h"
#import <Async_DisplayKit/A_SAssert.h>
#import <unordered_map>
#import <NSIndexSet+A_SHelpers.h>
#import <Async_DisplayKit/A_SObjectDescriptionHelpers.h>

/**
 * This is just a friendly Objective-C interface to unordered_map<NSInteger, NSInteger>
 */
@interface A_SIntegerMap () <A_SDescriptionProvider>
@end

@implementation A_SIntegerMap {
  std::unordered_map<NSInteger, NSInteger> _map;
  BOOL _isIdentity;
  BOOL _isEmpty;
  BOOL _immutable; // identity map and empty mape are immutable.
}

#pragma mark - Singleton

+ (A_SIntegerMap *)identityMap
{
  static A_SIntegerMap *identityMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    identityMap = [[A_SIntegerMap alloc] init];
    identityMap->_isIdentity = YES;
    identityMap->_immutable = YES;
  });
  return identityMap;
}

+ (A_SIntegerMap *)emptyMap
{
  static A_SIntegerMap *emptyMap;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    emptyMap = [[A_SIntegerMap alloc] init];
    emptyMap->_isEmpty = YES;
    emptyMap->_immutable = YES;
  });
  return emptyMap;
}

+ (A_SIntegerMap *)mapForUpdateWithOldCount:(NSInteger)oldCount deleted:(NSIndexSet *)deletions inserted:(NSIndexSet *)insertions
{
  if (oldCount == 0) {
    return A_SIntegerMap.emptyMap;
  }

  if (deletions.count == 0 && insertions.count == 0) {
    return A_SIntegerMap.identityMap;
  }

  A_SIntegerMap *result = [[A_SIntegerMap alloc] init];
  // Start with the old indexes
  NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, oldCount)];

  // Descending order, shift deleted ranges left
  [deletions enumerateRangesWithOptions:NSEnumerationReverse usingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    [indexes shiftIndexesStartingAtIndex:NSMaxRange(range) by:-range.length];
  }];

  // Ascending order, shift inserted ranges right
  [insertions enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    [indexes shiftIndexesStartingAtIndex:range.location by:range.length];
  }];

  __block NSInteger oldIndex = 0;
  [indexes enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
    // Note we advance oldIndex unconditionally, not newIndex
    for (NSInteger newIndex = range.location; newIndex < NSMaxRange(range); oldIndex++) {
      if ([deletions containsIndex:oldIndex]) {
        // index was deleted, do nothing, just let oldIndex advance.
      } else {
        // assign the next index for this item.
        result->_map[oldIndex] = newIndex++;
      }
    }
  }];
  return result;
}

- (NSInteger)integerForKey:(NSInteger)key
{
  if (_isIdentity) {
    return key;
  } else if (_isEmpty) {
    return NSNotFound;
  }

  auto result = _map.find(key);
  return result != _map.end() ? result->second : NSNotFound;
}

- (void)setInteger:(NSInteger)value forKey:(NSInteger)key
{
  if (_immutable) {
    A_SDisplayNodeFailAssert(@"Cannot mutate special integer map: %@", self);
    return;
  }

  _map[key] = value;
}

- (A_SIntegerMap *)inverseMap
{
  if (_isIdentity || _isEmpty) {
    return self;
  }

  auto result = [[A_SIntegerMap alloc] init];
  for (auto it = _map.begin(); it != _map.end(); it++) {
    result->_map[it->second] = it->first;
  }
  return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  if (_immutable) {
    return self;
  }

  auto newMap = [[A_SIntegerMap allocWithZone:zone] init];
  newMap->_map = _map;
  return newMap;
}

#pragma mark - Description

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray *result = [NSMutableArray array];

  if (_isIdentity) {
    [result addObject:@{ @"map": @"<identity>" }];
  } else if (_isEmpty) {
    [result addObject:@{ @"map": @"<empty>" }];
  } else {
    // { 1->2 3->4 5->6 }
    NSMutableString *str = [NSMutableString string];
    for (auto it = _map.begin(); it != _map.end(); it++) {
      [str appendFormat:@" %zd->%zd", it->first, it->second];
    }
    // Remove leading space
    if (str.length > 0) {
      [str deleteCharactersInRange:NSMakeRange(0, 1)];
    }
    [result addObject:@{ @"map": str }];
  }

  return result;
}

- (NSString *)description
{
  return A_SObjectDescriptionMakeWithoutObject([self propertiesForDescription]);
}

- (BOOL)isEqual:(id)object
{
  if ([super isEqual:object]) {
    return YES;
  }

  if (auto otherMap = A_SDynamicCast(object, A_SIntegerMap)) {
    return otherMap->_map == _map;
  }
  return NO;
}

@end
