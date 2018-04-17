//
//  ViewModelsAssembly.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "ViewModelsAssembly.h"
#import "DialogScreenViewModelImpl.h"
#import "ChatListScreenViewModelImpl.h"

@implementation ViewModelsAssembly

- (id<DialogScreenViewModel>)dialogScreenViewModel:(NSNumber *)userId {
    return [TyphoonDefinition withClass:[DialogScreenViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithDialogService:userId:pythonBridge:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.dialogService];
                    [initializer injectParameterWith:userId];
                    [initializer injectParameterWith:self.coreComponents.pythonBridge];
                }];
            }];
}

- (id<ChatListScreenViewModel>)chatListScreenViewModel {
    return [TyphoonDefinition withClass:[ChatListScreenViewModelImpl class] configuration:^(TyphoonDefinition *definition)
            {
                [definition useInitializer:@selector(initWithHandlersFactory:pythonBridge:chatListService:) parameters:^(TyphoonMethod *initializer) {
                    [initializer injectParameterWith:self.servicesAssembly.handlersFactory];
                    [initializer injectParameterWith:self.coreComponents.pythonBridge];
                    [initializer injectParameterWith:self.servicesAssembly.chatListService];
                }];
            }];
}

@end
