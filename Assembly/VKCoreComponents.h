////////////////////////////////////////////////////////////////////////////////
//
//  TYPHOON FRAMEWORK
//  Copyright 2015, Typhoon Framework Contributors
//  All Rights Reserved.
//
//  NOTICE: The authors permit you to use, modify, and distribute this file
//  in accordance with the terms of the license agreement accompanying it.
//
////////////////////////////////////////////////////////////////////////////////


#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"

@protocol ScreensManager;
@protocol VKSdkManager;
@protocol PythonBridge;
@protocol PythonManager;
@interface VKCoreComponents : TyphoonAssembly
- (id<VKSdkManager>)vkManager;
- (id<PythonBridge>)pythonBridge;
- (id<PythonManager>)pythonManager;
@end
