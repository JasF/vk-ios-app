//
//  Photo.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Photo.h"

@implementation Photo

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"date", @"height", @"width", @"text"]];
        [mapping mapKeyPath:@"access_key" toProperty:@"accessKey"];
        [mapping mapKeyPath:@"album_id" toProperty:@"albumId"];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        [mapping mapKeyPath:@"owner_id" toProperty:@"ownerId"];
        [mapping mapKeyPath:@"photo_130" toProperty:@"photo130"];
        [mapping mapKeyPath:@"photo_604" toProperty:@"photo604"];
        [mapping mapKeyPath:@"photo_75" toProperty:@"photo75"];
        [mapping mapKeyPath:@"post_id" toProperty:@"postId"];
        [mapping mapKeyPath:@"user_id" toProperty:@"userId"];
    }];
}

@end
