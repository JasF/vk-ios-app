//
//  WallPost.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "WallPost.h"
#import "CopyHistory.h"

@implementation WallPost

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"date"]];
        
        [mapping mapKeyPath:@"can_delete" toProperty:@"canDelete"];
        [mapping mapKeyPath:@"can_pin" toProperty:@"canPin"];
        [mapping mapKeyPath:@"comments" toProperty:@"comments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Comments *comments = [EKMapper objectFromExternalRepresentation:value
                                                                withMapping:[Comments objectMapping]];
            return comments;
        }];
        
        [mapping mapKeyPath:@"copy_history" toProperty:@"history" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *history = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                      withMapping:[CopyHistory objectMapping]];
            return history;
        }];
        
        [mapping mapKeyPath:@"from_id" toProperty:@"fromId"];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        
        [mapping mapKeyPath:@"likes" toProperty:@"likes" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Likes *likes = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Likes objectMapping]];
            return likes;
        }];
        
        [mapping mapKeyPath:@"owner_id" toProperty:@"ownerId"];
        
        [mapping mapKeyPath:@"post_source" toProperty:@"postSource" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            PostSource *postSource = [EKMapper objectFromExternalRepresentation:value
                                                                    withMapping:[PostSource objectMapping]];
            return postSource;
        }];
        
        [mapping mapKeyPath:@"post_type" toProperty:@"postType" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            PostType *postType = [EKMapper objectFromExternalRepresentation:@{key:value}
                                                                withMapping:[PostType objectMapping]];
            return postType;
        }];
        
        [mapping mapKeyPath:@"reposts" toProperty:@"reposts" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[Reposts objectMapping]];
            return reposts;
        }];
        
        [mapping mapKeyPath:@"text" toProperty:@"text"];
        
        [mapping mapKeyPath:@"views" toProperty:@"views" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Views *views = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Views objectMapping]];
            return views;
        }];
    }];
}

@end
