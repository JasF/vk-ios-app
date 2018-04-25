//
//  SettingsService.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Settings.h"

@protocol SettingsService <NSObject>
- (Settings *)parse:(NSDictionary *)data;
@end
