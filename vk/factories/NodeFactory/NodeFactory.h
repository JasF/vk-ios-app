//
//  NodeFactory.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@class ASDisplayNode;

@protocol NodeFactory <NSObject>
- (ASDisplayNode *)nodeForItem:(id)item;
- (ASDisplayNode *)nodeForItem:(id)item embedded:(BOOL)embedded;
@end
