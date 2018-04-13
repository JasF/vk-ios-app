//
//  Comments.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Comments.h"

@implementation Comments

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"count"]];
        [mapping mapKeyPath:@"can_post" toProperty:@"canPost"];
        [mapping mapKeyPath:@"groups_can_post" toProperty:@"groupsCanPost"];
    }];
}

@end
