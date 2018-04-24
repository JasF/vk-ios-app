//
//  WallPost.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPost.h"
#import "Audio.h"

@implementation WallPost {
    NSArray<Attachments *> *_attachments;
}

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"date", @"text", @"can_delete", @"can_pin", @"from_id", @"owner_id", @"source_id", @"type"]];
        
        [mapping mapKeyPath:@"comments" toProperty:@"comments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Comments *comments = [EKMapper objectFromExternalRepresentation:value
                                                                withMapping:[Comments objectMapping]];
            return comments;
        }];
        
        [mapping mapKeyPath:@"copy_history" toProperty:@"history" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *history = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                      withMapping:[WallPost objectMapping]];
            return history;
        }];
        
        [mapping mapKeyPath:@"friends.items" toProperty:@"friendsIds" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *history = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                      withMapping:[UserId objectMapping]];
            return history;
        }];
        
        [mapping mapKeyPath:@"audio.items" toProperty:@"audio" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *audio = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                      withMapping:[Audio objectMapping]];
            return audio;
        }];
        
        [mapping mapKeyPath:@"photos.items" toProperty:@"photos" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *photos = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                     withMapping:[Photo objectMapping]];
            return photos;
        }];
        
        [mapping mapKeyPath:@"attachments" toProperty:@"attachments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                          withMapping:[Attachments objectMapping]];
        }];
        
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        
        [mapping mapKeyPath:@"likes" toProperty:@"likes" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Likes *likes = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Likes objectMapping]];
            return likes;
        }];
    
        
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
        
        [mapping mapKeyPath:@"views" toProperty:@"views" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            Views *views = [EKMapper objectFromExternalRepresentation:value
                                                          withMapping:[Views objectMapping]];
            return views;
        }];
    }];
}

- (NSArray<Attachments *> *)attachments {
    return _attachments;
}

- (void)setAttachments:(NSArray<Attachments *> *)attachments {
    NSMutableArray *photos = [NSMutableArray new];
    for (Attachments *attachment in attachments) {
        if (attachment.type == AttachmentPhoto) {
            [photos addObject:attachment];
        }
    }
    
    if (photos.count) {
        NSMutableArray *mutableArray = [attachments mutableCopy];
        for (Attachments *attachment in photos) {
            [mutableArray removeObject:attachment];
        }
        attachments = [mutableArray copy];
        [self setPhotoAttachments:[photos copy]];
    }
    _attachments = attachments;
}

- (NSInteger)validId {
    if (_source_id != 0) {
        return _source_id;
    }
    return _from_id;
}

- (NSInteger)identifier {
    if (_post_id != 0) {
        return _post_id;
    }
    return _identifier;
}

@end
