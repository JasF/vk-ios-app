//
//  Audio.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Audio.h"

@implementation Audio

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"owner_id", @"artist", @"title", @"duration", @"date", @"url", @"is_hq", @"content_restricted"]];
    }];
}

@end
