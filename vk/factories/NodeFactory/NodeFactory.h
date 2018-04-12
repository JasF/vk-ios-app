//
//  NodeFactory.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ASDisplayNode.h"

@protocol NodeFactory <NSObject>
- (ASDisplayNode *)nodeForItem:(id)item;
- (ASDisplayNode *)nodeForItem:(id)item embedded:(BOOL)embedded;
@end
