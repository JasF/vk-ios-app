//
//  Video.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Video.h"

@implementation Video

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"identifier", @"owner_id", @"title", @"duration", @"date", @"comments", @"views", @"photo_130", @"photo_320", @"photo_800", @"photo_640", @"access_key", @"platform", @"can_edit", @"can_add"]];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        [mapping mapKeyPath:@"description" toProperty:@"videoDescription"];
    }];
}

@end
