//
//  ServicesAssembly.m
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ServicesAssembly.h"
#import "WallServiceImpl.h"
#import "DialogsServiceImpl.h"
#import "DialogServiceImpl.h"
#import "HandlersFactoryImpl.h"

@implementation ServicesAssembly

- (id<HandlersFactory>)handlersFactory {
    return [TyphoonDefinition withClass:[HandlersFactoryImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithPythonBridge:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:self.coreComponents.pythonBridge];
                 }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<WallService>)wallService {
    return [TyphoonDefinition withClass:[WallServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:self.handlersFactory];
                 }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<DialogsService>)dialogsService {
    return [TyphoonDefinition withClass:[DialogsServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:self.handlersFactory];
                 }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

- (id<DialogService>)dialogService {
    return [TyphoonDefinition withClass:[DialogServiceImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:) parameters:^(TyphoonMethod *initializer)
                 {
                     [initializer injectParameterWith:self.handlersFactory];
                 }];
                definition.scope = TyphoonScopeSingleton;
            }];
}

@end