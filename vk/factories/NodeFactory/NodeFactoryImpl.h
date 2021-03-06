//
//  NodeFactoryImpl.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NodeFactory.h"
#import "PostsService.h"

@class NodesAssembly;

@interface NodeFactoryImpl : NSObject <NodeFactory>
- (instancetype)initWithNodesAssembly:(NodesAssembly *)nodesAssembly;
@end
