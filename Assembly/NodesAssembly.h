//
//  NodesAssembly.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"
#import "ASDisplayNode.h"
#import "NodeFactory.h"

@class WallPostNode;

@interface NodesAssembly : TyphoonAssembly
- (id<NodeFactory>)nodeFactory;
- (ASDisplayNode *)wallPostNodeWithData:(id)data embedded:(NSNumber *)embedded;
@end
