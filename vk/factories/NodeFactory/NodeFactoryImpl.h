//
//  NodeFactoryImpl.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NodeFactory.h"

@class NodesAssembly;

@interface NodeFactoryImpl : NSObject <NodeFactory>
- (instancetype)initWithNodesAssembly:(NodesAssembly *)nodesAssembly;
@end
