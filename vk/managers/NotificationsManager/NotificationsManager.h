//
//  NotificationsManager.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#ifndef NotificationsManager_h
#define NotificationsManager_h

@protocol NotificationsManager <NSObject>
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSString *)token;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)initialize;
- (void)cleanBadgeNumber;
@end

#endif /* NotificationsManager_h */
