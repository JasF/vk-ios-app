//
//  NotificationsManagerImpl.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NotificationsManager.h"
#import "HandlersFactory.h"

@protocol PyNotificationsManager <NSObject>
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token deviceId:(NSString *)deviceId;
- (void)didFailToRegisterForRemoteNotifications:(NSString *)error;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;
@end

@interface NotificationsManagerImpl : NSObject <NotificationsManager>
- (id)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory;
@end
