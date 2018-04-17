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
#import "ServicesAssembly.h"

@class VKCoreComponents;
@class VKThemeAssembly;
@class NodesAssembly;
@class ViewModelsAssembly;

@interface ScreensAssembly : TyphoonAssembly
@property (nonatomic, strong, readonly) VKCoreComponents *coreComponents;
@property (nonatomic, strong, readonly) VKThemeAssembly *themeProvider;
@property (nonatomic, strong, readonly) NodesAssembly *nodesAssembly;
@property (readonly) ServicesAssembly *servicesAssembly;
@property (readonly) ViewModelsAssembly *viewModelsAssembly;
- (id<ScreensManager>)screensManager;
- (UIViewController *)createViewController;
- (UIViewController *)createMainViewController;
- (UIViewController *)newsViewController;
- (UIViewController *)dialogsViewController;
- (UIViewController *)dialogViewController:(NSNumber *)userId;
- (UIWindow *)window;
- (UINavigationController *)rootNavigationController;
@end
