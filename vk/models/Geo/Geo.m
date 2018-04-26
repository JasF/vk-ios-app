//
//  Geo.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Geo.h"

@implementation Geo

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"coordinates", @"type"]];
        [mapping mapKeyPath:@"place" toProperty:@"place" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Place *place = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Place objectMapping]];
            return place;
        }];
    }];
}

@end
