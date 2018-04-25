//
//  SettingsViewModel.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"

@protocol SettingsViewModel <NSObject>
- (void)menuTapped;
- (void)getSettingsWithCompletion:(void(^)(Settings *settings))completion;
- (void)notificationsSettingsChanged:(BOOL)on;
@end
