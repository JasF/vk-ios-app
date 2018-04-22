//
//  MenuViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "MenuViewModelImpl.h"

@interface MenuViewModelImpl ()
@property (strong, nonatomic) id<PyMenuViewModel> handler;
@end

@implementation MenuViewModelImpl

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

- (void)friendsTapped {
    dispatch_python(^{
        [self.handler friendsTapped];
    });
}

@end