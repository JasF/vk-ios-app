//
//  SettingsServiceImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SettingsServiceImpl.h"

@implementation SettingsServiceImpl

- (Settings *)parse:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        NSCAssert(false, @"unknown settings source data");
        return nil;
    }
    
    Settings *settings = [EKMapper objectFromExternalRepresentation:data
                                                        withMapping:[Settings objectMapping]];
    return settings;
}

@end
