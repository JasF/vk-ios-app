//
//  VideosServiceImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "VideosServiceImpl.h"
#import "Video.h"

@implementation VideosServiceImpl

- (NSArray *)parse:(NSDictionary *)data {
    if (![data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *response = data[@"response"];
    if (![response isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSArray *items = response[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    
    NSArray *objects = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                              withMapping:[Video objectMapping]];
    return objects;
}

@end
