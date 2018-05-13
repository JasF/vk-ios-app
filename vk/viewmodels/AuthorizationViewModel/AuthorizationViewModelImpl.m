//
//  AuthorizationViewModelImpl.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AuthorizationViewModelImpl.h"
#import <VK-ios-sdk/VKSdk.h>

@interface AuthorizationViewModelImpl () <AuthorizationViewModel>
@property id<PyAuthorizationViewModel> handler;
@property id<VKSdkManager> vkManager;
@property id<NotificationsManager> notificationsManager;
@end

@implementation AuthorizationViewModelImpl
    
@synthesize viewController = _viewController;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                              vkManager:(id<VKSdkManager>)vkManager
                   notificationsManager:(id<NotificationsManager>)notificationsManager {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(vkManager);
    NSCParameterAssert(notificationsManager);
    if (self = [super init]) {
        _handler = [handlersFactory authorizationViewModelHandler];
        _vkManager = vkManager;
        _notificationsManager = notificationsManager;
    }
    return self;
}

#pragma mark - Accessors
- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;
    if (_viewController) {
        [self initializeVkSdkManager];
    }
}

#pragma mark - Private Methods
- (void)initializeVkSdkManager {
    _vkManager.viewController = self.viewController;
    @weakify(self);
    _vkManager.getTokenSuccess = ^(VKAccessToken *token) {
        @strongify(self);
        dispatch_python(^{
            @strongify(self);
            NSLog(@"received vk token: %@", token.accessToken);
            dispatch_python(^{
                [self.handler accessTokenGathered:token.accessToken userId:[NSNumberFormatter.new numberFromString:token.userId]];
            });
        });
    };
    _vkManager.getTokenFailed = ^(NSError *error, BOOL cancelled) {
        // @strongify(self);
        
    };
    /*
    dispatch_block_t simulateBlock = ^{
        VKAccessToken *token = [VKAccessToken tokenWithToken:@"4c0638c47d2fb5c57fadfc995d123a1337c41781af7b1521e8d5fbd8d972ba0e63a9387677cb91cf8538e"
                                                      secret:@""
                                                      userId:@"7162990"];
        self.vkManager.getTokenSuccess(token);
    };
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self.vkManager authorize];
        
#ifdef DEBUG
        simulateBlock();
        
        //[self.vkManager authorize];
#else
        
        // simulateBlock();
        [self.vkManager authorize];
#endif
    });
     */
}

- (void)authorizeByApp {
    [self.vkManager authorizeByApp];
}

- (void)authorizeByLogin {
    [self.vkManager authorizeByLogin];
}

- (BOOL)isAuthorizationOverAppAvailable {
    return [VKSdk vkAppMayExists];
}

@end
