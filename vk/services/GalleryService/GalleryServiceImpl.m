//
//  GalleryServiceImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GalleryServiceImpl.h"
#import "Photo.h"

@implementation GalleryServiceImpl

- (NSArray *)parse:(NSDictionary *)photosData {
    if (![photosData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = photosData[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *objects = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                              withMapping:[Photo objectMapping]];
    return objects;
}

@end
