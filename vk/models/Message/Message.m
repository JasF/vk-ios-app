//
//  Message.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Message.h"

@implementation Message

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"body", @"date", @"random_id", @"read_state", @"title", @"user_id"]];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        [mapping mapKeyPath:@"out" toProperty:@"isOut"];
    }];
}

@end
