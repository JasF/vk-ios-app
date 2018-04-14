//
//  A_STestCase.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

NS_ASSUME_NONNULL_BEGIN

@interface A_STestCase : XCTestCase

@property (class, nonatomic, nullable, readonly) A_STestCase *currentTestCase;

@end

NS_ASSUME_NONNULL_END
