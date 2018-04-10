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

#pragma mark - Private Methods
/*
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
*/

@end
