//
//  PythonBridgeHandler.h
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PythonBridge.h"

@interface PythonBridgeHandler : NSProxy
- (id)initWithPythonBridge:(id<PythonBridge>)bridge
                      name:(NSString *)name
                   actions:(NSDictionary *)actions;
- (id)init NS_UNAVAILABLE;
+ (id)new NS_UNAVAILABLE;
@end
