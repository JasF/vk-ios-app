//
//  Dialog.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "Dialog.h"

@implementation Dialog

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"unread", @"in_read", @"out_read", @"message"]];
        
        [mapping mapKeyPath:@"message" toProperty:@"message" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[Message objectMapping]];
        }];
    }];
}

@end
