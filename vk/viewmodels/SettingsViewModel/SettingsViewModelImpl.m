//
//  SettingsViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SettingsViewModelImpl.h"

@interface SettingsViewModelImpl () <SettingsViewModel>
@property (strong) id<PySettingsViewModel> handler;
@property (strong) id<SettingsService> settingsService;
@end

@implementation SettingsViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                       settingsService:(id<SettingsService>)settingsService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(settingsService);
    if (self) {
        _handler = [handlersFactory settingsViewModelHandler];
        _settingsService = settingsService;
    }
    return self;
}

#pragma mark - SettingsViewModel
- (void)getSettingsWithCompletion:(void(^)(Settings *settings))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getSettings];
        Settings *settings = [self.settingsService parse:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(settings);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

- (void)notificationsSettingsChanged:(BOOL)on {
    dispatch_python(^{
        [self.handler notificationsSettingsChanged:@(on)];
    });
}

@end

