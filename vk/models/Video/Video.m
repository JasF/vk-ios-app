//
//  Video.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Video.h"

@implementation Video

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"owner_id", @"title", @"duration", @"date", @"comments", @"views", @"width", @"height", @"photo_130", @"photo_320", @"photo_800", @"adding_date", @"first_frame_320", @"first_frame_160", @"first_frame_130", @"first_frame_800", @"player", @"can_add"]];
        [mapping mapKeyPath:@"description" toProperty:@"videoDescription"];
    }];
}

- (NSString *)imageURL {
    NSString *imageURL = _photo_320;
    if (!imageURL) {
        imageURL = _photo_130;
    }
    return imageURL;
}

@end
