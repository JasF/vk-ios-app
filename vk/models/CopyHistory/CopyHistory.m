//
//  CopyHistory.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "CopyHistory.h"

@implementation CopyHistory

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"date", @"text"]];
    
        [mapping mapKeyPath:@"attachments" toProperty:@"attachments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *attachments = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                          withMapping:[Attachments objectMapping]];
            return attachments;
        }];
     
        [mapping mapKeyPath:@"from_id" toProperty:@"fromId"];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        [mapping mapKeyPath:@"owner_id" toProperty:@"ownerId"];
        
        [mapping mapKeyPath:@"post_source" toProperty:@"postSource" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[PostSource objectMapping]];
        }];
        
        [mapping mapKeyPath:@"post_type" toProperty:@"postType" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:@{key:value}
                                                  withMapping:[PostSource objectMapping]];
        }];
         
    }];
}

@end
