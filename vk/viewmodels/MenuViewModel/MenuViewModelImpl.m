//
//  MenuViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
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

- (void)lentaTapped {
    dispatch_python(^{
        [self.handler lentaTapped];
    });
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

- (void)photosTapped {
    dispatch_python(^{
        [self.handler photosTapped];
    });
}

- (void)answersTapped {
    dispatch_python(^{
        [self.handler answersTapped];
    });
}

- (void)groupsTapped {
    dispatch_python(^{
        [self.handler groupsTapped];
    });
}

- (void)bookmarksTapped {
    dispatch_python(^{
        [self.handler bookmarksTapped];
    });
}

- (void)videosTapped {
    dispatch_python(^{
        [self.handler videosTapped];
    });
}

- (void)documentsTapped {
    dispatch_python(^{
        [self.handler documentsTapped];
    });
}

- (void)settingsTapped {
    dispatch_python(^{
        [self.handler settingsTapped];
    });
}

@end
