//
//  PhotoAlbum.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbum.h"

@implementation PhotoAlbum
+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"thumb_id", @"owner_id", @"title", @"size", @"thumb_src"]];
    }];
}
@end