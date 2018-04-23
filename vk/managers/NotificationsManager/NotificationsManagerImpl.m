//
//  NotificationsManagerImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "NotificationsManagerImpl.h"

@import UserNotifications;

@interface NotificationsManagerImpl () <UNUserNotificationCenterDelegate>
@property (strong, nonatomic) id<PyNotificationsManager> handler;
@property (strong, nonatomic) id<HandlersFactory> handlersFactory;
@end

@implementation NotificationsManagerImpl

- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory {
    NSCParameterAssert(handlersFactory);
    if (self = [super init]) {
        _handlersFactory = handlersFactory;
    }
    return self;
}

#pragma mark - NotificationsManager
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token {
    dispatch_python(^{
        [self.handler didRegisterForRemoteNotificationsWithDeviceToken:token];
    });
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    dispatch_python(^{
        [self.handler didFailToRegisterForRemoteNotifications:[NSString stringWithFormat:@"%@", error]];
    });
}

- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo {
    dispatch_python(^{
        [self.handler didReceiveRemoteNotification:userInfo];
    });
}

- (void)initialize {
    if (@available (iOS 11, *)) {
        [self currentNotificationCenter].delegate = self;
        [self registerForUserNotification];
    }
    else if (@available (iOS 10, *)) {
        [self currentNotificationCenter].delegate = self;
        [self registerForRemoteNotifications]; // ios10 ipad support
        [self registerForUserNotification];
    }
}

- (void)cleanBadgeNumber {
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

#pragma mark - Private Methods
- (UNUserNotificationCenter *)currentNotificationCenter {
    if (@available (iOS 10, *)) {
        static BOOL g_exception_handled = NO;
        id result = nil;
        if (g_exception_handled) {
            return nil;
        }
        @try {
            result = [UNUserNotificationCenter currentNotificationCenter];
        }
        @catch (NSException *exception) {
            g_exception_handled = YES;
        }
        if (g_exception_handled) {
            return nil;
        }
        return result;
    }
    return nil;
}

- (void)registerForRemoteNotifications {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIApplication *application = [UIApplication sharedApplication];
        [application registerForRemoteNotifications];
    });
}

- (void)registerForUserNotification {
    [[self currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound |
                                                                  UNAuthorizationOptionAlert)
                                               completionHandler:^(BOOL granted, NSError *_Nullable error) {
                                                   if (granted) {
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self registerForRemoteNotifications];
                                                       });
                                                   }
                                               }];
}

#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBadge | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void(^)(void))completionHandler {
    NSDictionary *json = response.notification.request.content.userInfo;
    [self didReceiveRemoteNotification:json];
}

#pragma mark - Accessors
- (id<PyNotificationsManager>)handler {
    if (!_handler) {
        _handler = [self.handlersFactory notificationsManagerHandler];
    }
    return _handler;
}
@end
