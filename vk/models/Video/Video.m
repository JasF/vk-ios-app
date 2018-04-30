//
//  Video.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Video.h"
#import "Likes.h"
#import "Reposts.h"
#import "User.h"

@implementation Video

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"owner_id", @"title", @"duration", @"description", @"date", @"comments", @"views", @"photo_130", @"photo_320", @"adding_date", @"player", @"can_edit", @"can_add", @"can_comment", @"can_repost", @"repeat", @"width", @"height", @"photo_800", @"first_frame_320", @"first_frame_160", @"first_frame_130", @"first_frame_800"]];
        [mapping mapKeyPath:@"description" toProperty:@"videoDescription"];
        
        [mapping mapKeyPath:@"likes" toProperty:@"likes" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Likes *likes = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Likes objectMapping]];
            return likes;
        }];
        
        [mapping mapKeyPath:@"reposts" toProperty:@"reposts" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[Reposts objectMapping]];
            return reposts;
        }];
        [mapping mapKeyPath:@"owner" toProperty:@"owner" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[User objectMapping]];
            return reposts;
        }];
    }];
    
}

- (NSString *)imageURL {
    NSString *imageURL = _photo_320;
    if (!imageURL) {
        imageURL = _photo_130;
    }
    return imageURL;
}

@end
