//
//  Photo.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Photo.h"


@implementation Photo

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"album_id", @"owner_id", @"photo_75", @"photo_130", @"photo_604", @"photo_807", @"photo_1280", @"photo_2560", @"width", @"height", @"text", @"date", @"can_comment", @"can_repost", @"access_key", @"url"]];
        
        [mapping mapKeyPath:@"likes" toProperty:@"likes" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Likes *likes = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Likes objectMapping]];
            return likes;
        }];
        
        [mapping mapKeyPath:@"tags" toProperty:@"tags" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Tags *tags = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Tags objectMapping]];
            return tags;
        }];
        [mapping mapKeyPath:@"reposts" toProperty:@"reposts" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[Reposts objectMapping]];
            return reposts;
        }];
        [mapping mapKeyPath:@"comments" toProperty:@"comments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[Comments objectMapping]];
            return reposts;
        }];
        [mapping mapKeyPath:@"owner" toProperty:@"owner" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Reposts *reposts = [EKMapper objectFromExternalRepresentation:value
                                                              withMapping:[User objectMapping]];
            return reposts;
        }];
    }];
}

- (NSString *)bigPhotoURL {
    NSString *imageURL = _photo_2560;
    if (!imageURL.length) {
        imageURL = _photo_1280;
    }
    if (!imageURL.length) {
        imageURL = _photo_807;
    }
    if (!imageURL.length) {
        imageURL = _photo_604;
    }
    if (!imageURL.length) {
        imageURL = _photo_130;
    }
    if (!imageURL.length) {
        imageURL = _photo_75;
    }
    if (!imageURL.length) {
        imageURL = _url;
    }
    return imageURL;
}

- (NSString *)photo_130 {
    NSString *imageURL = _photo_130;
    if (!imageURL.length) {
        imageURL = _photo_75;
    }
    if (!imageURL.length) {
        imageURL = _url;
    }
    return imageURL;
}

- (NSString *)photo_604 {
    NSString *imageURL = _photo_604;
    if (!imageURL.length) {
        imageURL = _photo_130;
    }
    if (!imageURL.length) {
        imageURL = _photo_75;
    }
    if (!imageURL.length) {
        imageURL = _url;
    }
    return imageURL;
}

- (NSString *)photo_807 {
    NSString *imageURL = _photo_807;
    if (!imageURL.length) {
        imageURL = _photo_604;
    }
    if (!imageURL.length) {
        imageURL = _photo_130;
    }
    if (!imageURL.length) {
        imageURL = _photo_75;
    }
    if (!imageURL.length) {
        imageURL = _url;
    }
    return imageURL;
}

@end
