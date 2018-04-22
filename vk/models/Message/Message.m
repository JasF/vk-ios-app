//
//  Message.m
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Message.h"

@implementation Message

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"body", @"date", @"random_id", @"read_state", @"title", @"user_id", @"from_id"]];
        [mapping mapKeyPath:@"id" toProperty:@"identifier"];
        [mapping mapKeyPath:@"out" toProperty:@"isOut"];
        
        [mapping mapKeyPath:@"attachments" toProperty:@"attachments" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                          withMapping:[Attachments objectMapping]];
        }];
    }];
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


@end
