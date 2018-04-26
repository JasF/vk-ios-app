//
//  A_SAssert.h
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

#pragma once

#import <Foundation/NSException.h>
#import <pthread.h>
#import <Async_DisplayKit/A_SBaseDefines.h>

#define A_SDISPLAYNODE_A_SSERTIONS_ENABLED (!defined(NS_BLOCK_A_SSERTIONS))

/**
 * Note: In some cases it would be sufficient to do e.g.:
 *  A_SDisplayNodeAssert(...) NSAssert(__VA_ARGS__)
 * but we prefer not to, because we want to match the autocomplete behavior of NSAssert.
 * The construction listed above does not show the user what arguments are required and what are optional.
 */

#define A_SDisplayNodeAssert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define A_SDisplayNodeCAssert(condition, desc, ...) NSCAssert(condition, desc, ##__VA_ARGS__)

#define A_SDisplayNodeAssertNil(condition, desc, ...) A_SDisplayNodeAssert((condition) == nil, desc, ##__VA_ARGS__)
#define A_SDisplayNodeCAssertNil(condition, desc, ...) A_SDisplayNodeCAssert((condition) == nil, desc, ##__VA_ARGS__)

#define A_SDisplayNodeAssertNotNil(condition, desc, ...) A_SDisplayNodeAssert((condition) != nil, desc, ##__VA_ARGS__)
#define A_SDisplayNodeCAssertNotNil(condition, desc, ...) A_SDisplayNodeCAssert((condition) != nil, desc, ##__VA_ARGS__)

#define A_SDisplayNodeAssertImplementedBySubclass() A_SDisplayNodeAssert(NO, @"This method must be implemented by subclass %@", [self class]);
#define A_SDisplayNodeAssertNotInstantiable() A_SDisplayNodeAssert(NO, nil, @"This class is not instantiable.");
#define A_SDisplayNodeAssertNotSupported() A_SDisplayNodeAssert(NO, nil, @"This method is not supported by class %@", [self class]);

#define A_SDisplayNodeAssertMainThread() A_SDisplayNodeAssert(A_SMainThreadAssertionsAreDisabled() || 0 != pthread_main_np(), @"This method must be called on the main thread")
#define A_SDisplayNodeCAssertMainThread() A_SDisplayNodeCAssert(A_SMainThreadAssertionsAreDisabled() || 0 != pthread_main_np(), @"This function must be called on the main thread")

#define A_SDisplayNodeAssertNotMainThread() A_SDisplayNodeAssert(0 == pthread_main_np(), @"This method must be called off the main thread")
#define A_SDisplayNodeCAssertNotMainThread() A_SDisplayNodeCAssert(0 == pthread_main_np(), @"This function must be called off the main thread")

#define A_SDisplayNodeAssertFlag(X, desc, ...) A_SDisplayNodeAssert((1 == __builtin_popcount(X)), desc, ##__VA_ARGS__)
#define A_SDisplayNodeCAssertFlag(X, desc, ...) A_SDisplayNodeCAssert((1 == __builtin_popcount(X)), desc, ##__VA_ARGS__)

#define A_SDisplayNodeAssertTrue(condition) A_SDisplayNodeAssert((condition), @"Expected %s to be true.", #condition)
#define A_SDisplayNodeCAssertTrue(condition) A_SDisplayNodeCAssert((condition), @"Expected %s to be true.", #condition)

#define A_SDisplayNodeAssertFalse(condition) A_SDisplayNodeAssert(!(condition), @"Expected %s to be false.", #condition)
#define A_SDisplayNodeCAssertFalse(condition) A_SDisplayNodeCAssert(!(condition), @"Expected %s to be false.", #condition)

#define A_SDisplayNodeFailAssert(desc, ...) A_SDisplayNodeAssert(NO, desc, ##__VA_ARGS__)
#define A_SDisplayNodeCFailAssert(desc, ...) A_SDisplayNodeCAssert(NO, desc, ##__VA_ARGS__)

#define A_SDisplayNodeConditionalAssert(shouldTestCondition, condition, desc, ...) A_SDisplayNodeAssert((!(shouldTestCondition) || (condition)), desc, ##__VA_ARGS__)
#define A_SDisplayNodeConditionalCAssert(shouldTestCondition, condition, desc, ...) A_SDisplayNodeCAssert((!(shouldTestCondition) || (condition)), desc, ##__VA_ARGS__)

#define A_SDisplayNodeCAssertPositiveReal(description, num) A_SDisplayNodeCAssert(num >= 0 && num <= CGFLOAT_MAX, @"%@ must be a real positive integer: %f.", description, (CGFloat)num)
#define A_SDisplayNodeCAssertInfOrPositiveReal(description, num) A_SDisplayNodeCAssert(isinf(num) || (num >= 0 && num <= CGFLOAT_MAX), @"%@ must be infinite or a real positive integer: %f.", description, (CGFloat)num)

#define A_SDisplayNodeErrorDomain @"A_SDisplayNodeErrorDomain"
#define A_SDisplayNodeNonFatalErrorCode 1

/**
 * In debug methods, it can be useful to disable main thread assertions to get valuable information,
 * even if it means violating threading requirements. These functions are used in -debugDescription and let
 * threads decide to suppress/re-enable main thread assertions.
 */
#pragma mark - Main Thread Assertions Disabling

A_SDISPLAYNODE_EXTERN_C_BEGIN
BOOL A_SMainThreadAssertionsAreDisabled(void);

void A_SPushMainThreadAssertionsDisabled(void);

void A_SPopMainThreadAssertionsDisabled(void);
A_SDISPLAYNODE_EXTERN_C_END

#pragma mark - Non-Fatal Assertions

/// Returns YES if assertion passed, NO otherwise.
#define A_SDisplayNodeAssertNonFatal(condition, desc, ...) ({                                                                      \
  BOOL __evaluated = condition;                                                                                                   \
  if (__evaluated == NO) {                                                                                                        \
    A_SDisplayNodeFailAssert(desc, ##__VA_ARGS__);                                                                                 \
    A_SDisplayNodeNonFatalErrorBlock block = [A_SDisplayNode nonFatalErrorBlock];                                                   \
    if (block != nil) {                                                                                                           \
      NSDictionary *userInfo = nil;                                                                                               \
      if (desc.length > 0) {                                                                                                      \
        userInfo = @{ NSLocalizedDescriptionKey : desc };                                                                         \
      }                                                                                                                           \
      NSError *error = [NSError errorWithDomain:A_SDisplayNodeErrorDomain code:A_SDisplayNodeNonFatalErrorCode userInfo:userInfo];  \
      block(error);                                                                                                               \
    }                                                                                                                             \
  }                                                                                                                               \
  __evaluated;                                                                                                                    \
})                                                                                                                                \
