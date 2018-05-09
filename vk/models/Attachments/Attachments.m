//
//  Attachments.m
//  vk
//
//  Created by Jasf on 10.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Attachments.h"
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
        [mapping mapKeyPath:@"type" toProperty:@"typeString"];
    }];
}

- (void)setTypeString:(NSString *)typeString {
    NSDictionary *dictionary = @{@"photo":@(AttachmentPhoto),
                                 @"video":@(AttachmentVideo)};
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
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uInt crc = crc32(0, data.bytes, data.length);
    return [NSString stringWithFormat:@"%@", @(crc)];
}

@end
