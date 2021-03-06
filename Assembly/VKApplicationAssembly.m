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

#import "VKApplicationAssembly.h"
#import "VKCoreComponents.h"
#import "VKThemeAssembly.h"
#import "ScreensAssembly.h"
#import "Oxy_Feed-Swift.h"
#import "NotificationsManagerImpl.h"
#import "ServicesAssembly.h"
@implementation VKApplicationAssembly

//-------------------------------------------------------------------------------------------
#pragma mark - Bootstrapping
//-------------------------------------------------------------------------------------------

- (AppDelegate *)appDelegate
{
    return [TyphoonDefinition withClass:[AppDelegate class] configuration:^(TyphoonDefinition *definition)
            {
                [definition injectProperty:@selector(screensManager) with:[self.screensAssembly screensManager]];
                [definition injectProperty:@selector(pythonBridge) with:[self.coreComponents pythonBridge]];
                [definition injectProperty:@selector(pythonManager) with:[self.coreComponents pythonManager]];
                [definition injectProperty:@selector(notificationsManager) with:[self notificationsManager]];
                [definition injectProperty:@selector(modules) with:[self modules]];
            }];
}

- (UIWindow *)mainWindow
{
    return [TyphoonDefinition withClass:[UIWindow class] configuration:^(TyphoonDefinition *definition)
    {
        [definition useInitializer:@selector(initWithFrame:) parameters:^(TyphoonMethod *initializer)
        {
            [initializer injectParameterWith:[NSValue valueWithCGRect:[[UIScreen mainScreen] bounds]]];
        }];
        [definition injectProperty:@selector(rootViewController) with:[self rootViewController]];
    }];
}

//-------------------------------------------------------------------------------------------

- (UINavigationController *)rootViewController
{
    return [TyphoonDefinition withClass:[UINavigationController class] configuration:^(TyphoonDefinition *definition)
    {
        [definition useInitializer:@selector(init)];
        definition.scope = TyphoonScopeSingleton;
    }];
}

- (id<NotificationsManager>)notificationsManager {
    return [TyphoonDefinition withClass:[NotificationsManagerImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<Analytics>)analytics {
    return [TyphoonDefinition withClass:[AnalyticsImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                }];
            }];
}

- (id<SystemEvents>)systemEvents {
    return [TyphoonDefinition withClass:[SystemEventsImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                }];
            }];
}

- (id<Modules>)modules {
    return [TyphoonDefinition withClass:[ModulesImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(init:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self];
                }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

@end
