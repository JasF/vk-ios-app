//
//  Photo.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Photo.h"

@implementation Photo

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"album_id", @"owner_id", @"photo_75", @"photo_130", @"photo_604", @"photo_807", @"photo_1280", @"photo_2560", @"width", @"height", @"text", @"date", @"likes", @"reposts", @"comments", @"can_comment", @"tags", @"access_key"]];
    }];
}

@end
