//
//  Place.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Place.h"

@implementation Place

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"city", @"country", @"created", @"icon", @"id", @"latitude", @"longitude", @"title"]];
    }];
}

@end
