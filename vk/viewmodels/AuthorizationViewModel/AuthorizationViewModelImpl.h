//
//  AuthorizationViewModelImpl.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AuthorizationViewModel.h"
#import "HandlersFactory.h"
#import "VKSdkManager.h"
#import "NotificationsManager.h"

@protocol PyAuthorizationViewModel <NSObject>
- (void)accessTokenGathered:(NSString *)accessToken
                     userId:(NSNumber *)userId;
@end

@interface AuthorizationViewModelImpl : NSObject <AuthorizationViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                              vkManager:(id<VKSdkManager>)vkManager
                   notificationsManager:(id<NotificationsManager>)notificationsManager;
@end
