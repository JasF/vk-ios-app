//
//  Sticker.m
//  vk
//
//  Created by Jasf on 10.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Sticker.h"

static NSInteger const kStickerIndex = 2;

@implementation Sticker

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"product_id", @"sticker_id"]];
        [mapping mapKeyPath:@"images" toProperty:@"images" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *array = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                    withMapping:[Photo objectMapping]];
            return array;
        }];
        [mapping mapKeyPath:@"images_with_background" toProperty:@"images_with_background" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *array = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                    withMapping:[Photo objectMapping]];
            return array;
        }];
    }];
}

- (Photo *)photoForChatCell {
    if (_images.count > kStickerIndex) {
        return _images[kStickerIndex];
    }
    return _images.lastObject;
}

@end
