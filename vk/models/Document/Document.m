//
//  Document.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "Document.h"

@implementation Document

+(EKObjectMapping *)objectMapping
{
    return [EKObjectMapping mappingForClass:self withBlock:^(EKObjectMapping *mapping) {
        [mapping mapPropertiesFromArray:@[@"id", @"owner_id", @"title", @"size", @"ext", @"url", @"date", @"type"]];
        
        [mapping mapKeyPath:@"preview.photo.sizes" toProperty:@"sizedPhotos" withValueBlock:^id _Nullable(NSString * _Nonnull key, id  _Nullable value) {
            NSArray *photos = [EKMapper arrayOfObjectsFromExternalRepresentation:value
                                                                     withMapping:[SizedPhoto objectMapping]];
            return photos;
        }];
    }];
}

- (NSString *)imageURL {
    return self.sizedPhotos.firstObject.src;
}

@end
