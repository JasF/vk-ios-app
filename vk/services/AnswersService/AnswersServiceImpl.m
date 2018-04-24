//
//  AnswersServiceImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "AnswersServiceImpl.h"

@implementation AnswersServiceImpl

- (NSArray *)parse:(NSDictionary *)photosData {
    if (![photosData isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *items = photosData[@"items"];
    if (![items isKindOfClass:[NSArray class]]) {
        return nil;
    }
    /*
    NSArray *objects = [EKMapper arrayOfObjectsFromExternalRepresentation:items
                                                              withMapping:[Photo objectMapping]];
    return objects;
     */
    return nil;
}

@end
