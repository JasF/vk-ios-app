//
//  MenuScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "MenuScreenViewModelImpl.h"

@interface MenuScreenViewModelImpl ()
@property (strong, nonatomic) id<PyMenuScreenViewModel> handler;
@end

@implementation MenuScreenViewModelImpl

- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [super init]) {
        _handler = [handlersFactory menuViewModelHandler];
    }
    return self;
}

- (void)newsTapped {
    dispatch_python(^{
        [self.handler newsTapped];
    });
}

- (void)dialogsTapped {
    dispatch_python(^{
        [self.handler dialogsTapped];
    });
}

@end
