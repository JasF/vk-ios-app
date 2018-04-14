//
//  NodeFactory.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@class A_SDisplayNode;

@protocol NodeFactory <NSObject>
- (A_SDisplayNode *)nodeForItem:(id)item;
- (A_SDisplayNode *)nodeForItem:(id)item embedded:(BOOL)embedded;
@end
