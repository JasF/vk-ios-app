//
//  A_SCollectionLayoutState+Private.h
//  Tex_ture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SCollectionLayoutState.h>
#import <Async_DisplayKit/A_SPageTable.h>

NS_ASSUME_NONNULL_BEGIN

@interface A_SCollectionLayoutState (Private)

/**
 * Remove and returns layout attributes for unmeasured elements that intersect the specified rect
 *
 * @discussion This method is atomic and thread-safe
 */
- (nullable A_SPageToLayoutAttributesTable *)getAndRemoveUnmeasuredLayoutAttributesPageTableInRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
