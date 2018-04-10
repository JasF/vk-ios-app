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


#import "VKCoreComponents.h"
#import "VKSdkManagerImpl.h"
#import "PythonBridgeImpl.h"
#import "Typhoon.h"

@implementation VKCoreComponents
- (id<VKSdkManager>)vkManager {
    return [TyphoonDefinition withClass:[VKSdkManagerImpl class] configuration:^(TyphoonDefinition *definition)
            {
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<PythonBridge>)pythonBridge {
    return [TyphoonDefinition withClass:[PythonBridgeImpl class] configuration:^(TyphoonDefinition *definition)
            {
                definition.scope = TyphoonScopeSingleton;
            }];
}
@end
