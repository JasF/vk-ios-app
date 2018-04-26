//
//  A_SRangeManagingNode.h
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
#import <Async_DisplayKit/A_STraitCollection.h>

@class A_SCellNode;

NS_ASSUME_NONNULL_BEGIN

/**
 * Basically A_STableNode or A_SCollectionNode.
 */
@protocol A_SRangeManagingNode <NSObject, A_STraitEnvironment>

/**
 * Retrieve the index path for the given node, if it's a member of this container.
 *
 * @param node The node.
 * @return The index path, or nil if the node is not part of this container.
 */
- (nullable NSIndexPath *)indexPathForNode:(A_SCellNode *)node;

@end

NS_ASSUME_NONNULL_END
