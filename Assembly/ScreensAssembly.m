//
//  ScreensAssembly.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "ScreensAssembly.h"
#import "ViewController.h"
#import "VKCoreComponents.h"
#import "VKThemeAssembly.h"
#import "ScreensManagerImpl.h"
#import "NewsViewController.h"
#import "DialogsViewController.h"
#import "BaseNavigationController.h"
#import "NodesAssembly.h"
#import "ServicesAssembly.h"

@implementation ScreensAssembly

#pragma mark - Public Methods

- (id<ScreensManager>)screensManager {
    return [TyphoonDefinition withClass:[ScreensManagerImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithVKSdkManager:pythonBridge:screensAssembly:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:[self.coreComponents vkManager]];
                     [initializer injectParameterWith:[self.coreComponents pythonBridge]];
                     [initializer injectParameterWith:self];
                 }];
                [definition injectProperty:@selector(window) with:[self window]];
                [definition injectProperty:@selector(mainViewController) with:[self createMainViewController]];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (UIWindow *)window {
    return [TyphoonDefinition withClass:[UIWindow class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithFrame:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:[NSValue valueWithCGRect:[[UIScreen mainScreen] bounds]]];
                 }];
                [definition injectProperty:@selector(rootViewController) with:[self rootNavigationController]];
            }];
}

- (UINavigationController *)rootNavigationController {
    return [TyphoonDefinition withClass:[UINavigationController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init)];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (UIViewController *)createViewController
{
    return [TyphoonDefinition withClass:[ViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init)];
                [definition injectProperty:@selector(vkManager) with:self.coreComponents.vkManager];
                [definition injectProperty:@selector(pythonBridge) with:self.coreComponents.pythonBridge];
            }];
}

- (UIViewController *)createMainViewController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"MainViewController"];
                               }
                            configuration:^(TyphoonFactoryDefinition *definition) {
                                [definition injectProperty:@selector(rootViewController) with:[self mainNavigationController]];
                               }];
}

- (UIViewController *)newsViewController {
    return [TyphoonDefinition withClass:[NewsViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:nodeFactory:wallService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                    [initializer injectParameterWith:self.servicesAssembly.wallService];
                }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (UIViewController *)dialogsViewController {
    return [TyphoonDefinition withClass:[DialogsViewController class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:nodeFactory:dialogsService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.nodesAssembly.nodeFactory];
                    [initializer injectParameterWith:self.servicesAssembly.dialogsService];
                }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (BaseNavigationController *)mainNavigationController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"NavigationController"];
                               }
                            configuration:^(TyphoonFactoryDefinition *definition) {
                                [definition injectProperty:@selector(viewControllers) with:@[[self mainChildViewController]]];
                            }];
}

- (BaseNavigationController *)mainChildViewController {
    return [TyphoonDefinition withFactory:[self mainStoryboard]
                                 selector:@selector(instantiateViewControllerWithIdentifier:)
                               parameters:^(TyphoonMethod *factoryMethod) {
                                   [factoryMethod injectParameterWith:@"ViewController"];
                               }];
}

#pragma mark - Private Methods
- (UIStoryboard *)mainStoryboard {
    return [TyphoonDefinition withClass:[TyphoonStoryboard class] configuration:^(TyphoonDefinition* definition) {
                [definition useInitializer:@selector(storyboardWithName:factory:bundle:) parameters:^(TyphoonMethod *initializer) {
                     [initializer injectParameterWith:@"Main"];
                     [initializer injectParameterWith:self];
                     [initializer injectParameterWith:[NSBundle mainBundle]];
                }];
                 definition.scope = TyphoonScopeSingleton; //Let's make this a singleton
            }];
}

- (UIStoryboard *)storyboardWithName:(NSString *)storyboardName {
    return [TyphoonDefinition withClass:[TyphoonStoryboard class] configuration:^(TyphoonDefinition* definition) {
        [definition useInitializer:@selector(storyboardWithName:factory:bundle:) parameters:^(TyphoonMethod *initializer) {
            [initializer injectParameterWith:storyboardName];
            [initializer injectParameterWith:self];
            [initializer injectParameterWith:[NSBundle mainBundle]];
        }];
    }];
}

@end
