//
//  Reposts.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Reposts.h"

@implementation Reposts

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"count"]];
        [mapping mapKeyPath:@"user_reposted" toProperty:@"userReposted"];
    }];
}

@end
