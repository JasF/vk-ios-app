//
//  A_SHashing.h
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
A_SDISPLAYNODE_EXTERN_C_BEGIN

/**
 * When std::hash is unavailable, this function will hash a bucket o' bits real fast.
 * The hashing algorithm is copied from CoreFoundation's private function CFHashBytes.
 * https://opensource.apple.com/source/CF/CF-1153.18/CFUtilities.c.auto.html
 *
 * Simple example:
 *  CGRect myRect = { ... };
 *  A_SHashBytes(&myRect, sizeof(myRect));
 *
 * Example: 
 *  struct {
 *    NSUInteger imageHash;
 *    CGSize size;
 *  } data = {
 *    _image.hash,
 *    _bounds.size
 *  };
 *  return A_SHashBytes(&data, sizeof(data));
 *
 * @warning: If a struct has padding, any fields that are intiailized in {} 
 *   will have garbage data for their padding, which will break this hash! Either
 *   use `pragma clang diagnostic warning "-Wpadded"` around your struct definition
 *   or manually initialize the fields of your struct (`myStruct.x = 7;` etc).
 */
NSUInteger A_SHashBytes(void *bytes, size_t length);

A_SDISPLAYNODE_EXTERN_C_END
NS_ASSUME_NONNULL_END
