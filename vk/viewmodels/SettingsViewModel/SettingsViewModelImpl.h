//
//  SettingsViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SettingsViewModel.h"
#import "SettingsService.h"
#import "HandlersFactory.h"

@protocol PySettingsViewModel <NSObject>
- (NSDictionary *)getSettings;
- (void)menuTapped;
- (void)notificationsSettingsChanged:(NSNumber *)on;
@end

@interface SettingsViewModelImpl : NSObject <SettingsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        settingsService:(id<SettingsService>)settingsService;
@end
