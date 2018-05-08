//
//  PythonBridgeExtensionImpl.h
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PythonManager.h"
#import "PythonBridgeExtension.h"
#import "PythonBridge.h"

@interface PythonBridgeExtensionImpl : NSObject <PythonManagerExtension, PythonBridgeExtension>
@property (nonatomic) id<PythonBridge> pythonBridge;
@end
