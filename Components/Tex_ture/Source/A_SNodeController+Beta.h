//
//  A_SNodeController+Beta.h
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

#import <Async_DisplayKit/A_SDisplayNode.h>
#import <Async_DisplayKit/A_SDisplayNode+Subclasses.h> // for A_SInterfaceState protocol

/* A_SNodeController is currently beta and open to change in the future */
@interface A_SNodeController<__covariant DisplayNodeType : A_SDisplayNode *> : NSObject <A_SInterfaceStateDelegate>

@property (nonatomic, strong /* may be weak! */) DisplayNodeType node;

// Until an A_SNodeController can be provided in place of an A_SCellNode, some apps may prefer to have
// nodes keep their controllers alive (and a weak reference from controller to node)

@property (nonatomic, assign) BOOL shouldInvertStrongReference;

- (void)loadNode;

// for descriptions see <A_SInterfaceState> definition
- (void)didEnterVisibleState A_SDISPLAYNODE_REQUIRES_SUPER;
- (void)didExitVisibleState  A_SDISPLAYNODE_REQUIRES_SUPER;

- (void)didEnterDisplayState A_SDISPLAYNODE_REQUIRES_SUPER;
- (void)didExitDisplayState  A_SDISPLAYNODE_REQUIRES_SUPER;

- (void)didEnterPreloadState A_SDISPLAYNODE_REQUIRES_SUPER;
- (void)didExitPreloadState  A_SDISPLAYNODE_REQUIRES_SUPER;

- (void)interfaceStateDidChange:(A_SInterfaceState)newState
                      fromState:(A_SInterfaceState)oldState A_SDISPLAYNODE_REQUIRES_SUPER;

@end

@interface A_SDisplayNode (A_SNodeController)

@property(nonatomic, readonly) A_SNodeController *nodeController;

@end
