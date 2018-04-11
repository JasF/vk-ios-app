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

@interface ScreensAssembly : TyphoonAssembly
@property(nonatomic, strong, readonly) VKCoreComponents *coreComponents;
@property(nonatomic, strong, readonly) VKThemeAssembly *themeProvider;
- (id<ScreensManager>)screensManager;
- (UIViewController *)createViewController;
- (UIViewController *)createMainViewController;
- (UIViewController *)newsViewController;
- (UIWindow *)window;
- (UINavigationController *)rootNavigationController;
@end
