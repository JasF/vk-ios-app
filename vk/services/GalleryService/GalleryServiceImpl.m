//
//  GalleryServiceImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GalleryServiceImpl.h"
#import "Photo.h"
#import "WallPost.h"

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

- (WallPost *)parsePost:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    WallPost *post = [EKMapper objectFromExternalRepresentation:data withMapping:[WallPost objectMapping]];
    return post;
}
@end
