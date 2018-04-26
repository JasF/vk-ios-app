//
//  A_SYogaLayoutSpec.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SAvailability.h>

#if YOGA /* YOGA */

#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SLayoutSpec.h>

@interface A_SYogaLayoutSpec : A_SLayoutSpec
@property (nonatomic, strong, nonnull) A_SDisplayNode *rootNode;
@end

#endif /* YOGA */
