//
//  A_SCollectionElement.h
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

#import <Async_DisplayKit/A_SDataController.h>
#import <Async_DisplayKit/A_STraitCollection.h>

@class A_SDisplayNode;
@protocol A_SRangeManagingNode;

NS_ASSUME_NONNULL_BEGIN

A_S_SUBCLASSING_RESTRICTED
@interface A_SCollectionElement : NSObject

@property (nonatomic, readonly, copy, nullable) NSString *supplementaryElementKind;
@property (nonatomic, assign) A_SSizeRange constrainedSize;
@property (nonatomic, readonly, weak) id<A_SRangeManagingNode> owningNode;
@property (nonatomic, assign) A_SPrimitiveTraitCollection traitCollection;
@property (nonatomic, readonly, nullable) id nodeModel;

- (instancetype)initWithNodeModel:(nullable id)nodeModel
                        nodeBlock:(A_SCellNodeBlock)nodeBlock
         supplementaryElementKind:(nullable NSString *)supplementaryElementKind
                  constrainedSize:(A_SSizeRange)constrainedSize
                       owningNode:(id<A_SRangeManagingNode>)owningNode
                  traitCollection:(A_SPrimitiveTraitCollection)traitCollection;

/**
 * @return The node, running the node block if necessary. The node block will be discarded
 * after the first time it is run.
 */
@property (strong, readonly) A_SCellNode *node;

/**
 * @return The node, if the node block has been run already.
 */
@property (strong, readonly, nullable) A_SCellNode *nodeIfAllocated;

@end

NS_ASSUME_NONNULL_END
