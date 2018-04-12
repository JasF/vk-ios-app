//
//  NodeFactoryImpl.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "NodeFactoryImpl.h"
#import "NodesAssembly.h"
#import "WallPost.h"

@implementation NodeFactoryImpl {
    NodesAssembly *_assembly;
}

#pragma mark - Initialization
- (instancetype)initWithNodesAssembly:(NodesAssembly *)nodesAssembly {
    NSCParameterAssert(nodesAssembly);
    if (self = [super init]) {
        _assembly = nodesAssembly;
    }
    return self;
}

- (ASDisplayNode *)nodeForItem:(id)item {
    return [self nodeForItem:item embedded:NO];
}

- (ASDisplayNode *)nodeForItem:(id)item embedded:(BOOL)embedded {
    if ([item isKindOfClass:[WallPost class]]) {
        return [_assembly wallPostNodeWithData:item embedded:@(embedded)];
    }
    NSCAssert(false, @"Undeterminated item class: %@", item);
    return nil;
}

@end
