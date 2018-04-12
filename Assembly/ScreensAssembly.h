//
//  ScreensAssembly.h
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TyphoonAssembly.h"
#import "ScreensManager.h"

@class VKCoreComponents;
@class VKThemeAssembly;
@class NodesAssembly;

@interface ScreensAssembly : TyphoonAssembly
@property(nonatomic, strong, readonly) VKCoreComponents *coreComponents;
@property(nonatomic, strong, readonly) VKThemeAssembly *themeProvider;
@property(nonatomic, strong, readonly) NodesAssembly *nodesAssembly;
- (id<ScreensManager>)screensManager;
- (UIViewController *)createViewController;
- (UIViewController *)createMainViewController;
- (UIViewController *)newsViewController;
- (UIViewController *)dialogsViewController;
- (UIWindow *)window;
- (UINavigationController *)rootNavigationController;
@end
