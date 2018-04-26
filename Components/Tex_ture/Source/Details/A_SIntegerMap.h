//
//  A_SIntegerMap.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An objective-C wrapper for unordered_map.
 */
A_S_SUBCLASSING_RESTRICTED
@interface A_SIntegerMap : NSObject <NSCopying>

/**
 * Creates a map based on the specified update to an array.
 *
 * If oldCount is 0, returns the empty map.
 * If deleted and inserted are empty, returns the identity map.
 */
+ (A_SIntegerMap *)mapForUpdateWithOldCount:(NSInteger)oldCount
                                   deleted:(nullable NSIndexSet *)deleted
                                  inserted:(nullable NSIndexSet *)inserted;

/**
 * A singleton that maps each integer to itself. Its inverse is itself.
 *
 * Note: You cannot mutate this.
 */
@property (class, atomic, readonly) A_SIntegerMap *identityMap;

/**
 * A singleton that returns NSNotFound for all keys. Its inverse is itself.
 *
 * Note: You cannot mutate this.
 */
@property (class, atomic, readonly) A_SIntegerMap *emptyMap;

/**
 * Retrieves the integer for a given key, or NSNotFound if the key is not found.
 *
 * @param key A key to lookup the value for.
 */
- (NSInteger)integerForKey:(NSInteger)key;

/**
 * Sets the value for a given key.
 *
 * @param value The new value.
 * @param key The key to store the value for.
 */
- (void)setInteger:(NSInteger)value forKey:(NSInteger)key;

/**
 * Create and return a map with the inverse mapping.
 */
- (A_SIntegerMap *)inverseMap;

@end

NS_ASSUME_NONNULL_END
