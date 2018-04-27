//
//  ScreensManagerImpl.h
//  vk
//
//  Created by Jasf on 09.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "ScreensManager.h"
#import "VKSdkManager.h"
#import "PythonBridge.h"
#import "NodeFactory.h"
#import "DialogsManager.h"

@class ScreensAssembly;
@class MainViewController;

@interface ScreensManagerImpl : NSObject <ScreensManager>
@property (strong, nonatomic) MainViewController *mainViewController;
- (id)init NS_UNAVAILABLE;
+ (id)new NS_UNAVAILABLE;
- (id)initWithVKSdkManager:(id<VKSdkManager>)vkSdkManager
              pythonBridge:(id<PythonBridge>)pythonBridge
           screensAssembly:(ScreensAssembly *)screensAssembly;
@end
