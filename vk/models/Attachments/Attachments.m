//
//  Attachments.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Attachments.h"
#import "WallPost.h"
#import <zlib.h>

@implementation Attachments

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapKeyPath:@"photo" toProperty:@"photo" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[Photo objectMapping]];
        }];
        [mapping mapKeyPath:@"video" toProperty:@"video" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[Video objectMapping]];
        }];
        [mapping mapKeyPath:@"sticker" toProperty:@"sticker" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[Sticker objectMapping]];
        }];
        [mapping mapKeyPath:@"wall" toProperty:@"wall" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            return [EKMapper objectFromExternalRepresentation:value
                                                  withMapping:[WallPost objectMapping]];
        }];
        [mapping mapKeyPath:@"type" toProperty:@"typeString"];
    }];
}

- (void)setTypeString:(NSString *)typeString {
    NSDictionary *dictionary = @{@"photo":@(AttachmentPhoto),
                                 @"video":@(AttachmentVideo),
                                 @"sticker":@(AttachmentSticker),
                                 @"wall":@(AttachmentWall)};
    _type = [dictionary[typeString] integerValue];
}

- (NSString *)uid {
    NSString *string = @"";
    if (self.photo) {
        string = [NSString stringWithFormat:@"p%@", @(self.photo.id)];
    }
    else if (self.video) {
        string = [NSString stringWithFormat:@"v%@", @(self.video.id)];
    }
    else if (self.sticker) {
        string = [NSString stringWithFormat:@"s%@%@", @(self.sticker.product_id), @(self.sticker.sticker_id)];
    }
    else if (self.wall) {
        string = [NSString stringWithFormat:@"w%@%@", @(self.wall.identifier), @(self.wall.owner_id)];
    }
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned long crc =(unsigned long)crc32(0, data.bytes, (uInt)data.length);
    return [NSString stringWithFormat:@"%@", @(crc)];
}

@end
