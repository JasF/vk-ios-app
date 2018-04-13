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


@implementation VKApplicationAssembly

//-------------------------------------------------------------------------------------------
#pragma mark - Bootstrapping
//-------------------------------------------------------------------------------------------

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

@end
