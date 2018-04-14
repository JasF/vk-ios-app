//
//  A_STableNode+Beta.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_STableNode.h>

@protocol A_SBatchFetchingDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface A_STableNode (Beta)

@property (nonatomic, weak) id<A_SBatchFetchingDelegate> batchFetchingDelegate;

@end

NS_ASSUME_NONNULL_END
