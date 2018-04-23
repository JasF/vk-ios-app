//
//  PhotoAlbumsServiceImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumsServiceImpl.h"
#import "PhotoAlbum.h"

@implementation PhotoAlbumsServiceImpl

- (NSArray *)parse:(NSDictionary *)albums {
    if (![albums isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *itemsData = albums[@"items"];
    if (![itemsData isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray *objects = [EKMapper arrayOfObjectsFromExternalRepresentation:itemsData
                                                              withMapping:[PhotoAlbum objectMapping]];
    return objects;
}

@end
