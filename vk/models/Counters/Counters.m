//
//  Counters.m
//  vk
//
//  Created by Jasf on 08.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Counters.h"

@implementation Counters
+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"photos", @"albums", @"topics", @"videos", @"audios"]];
    }];
}
@end
