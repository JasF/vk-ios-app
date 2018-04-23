//
//  WallPostServiceImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallPostServiceImpl.h"
#import "Comment.h"

@implementation WallPostServiceImpl {
    id<WallService> _wallService;
}

- (id)initWithWallService:(id<WallService>)wallService {
    NSCParameterAssert(wallService);
    if (self = [super init]) {
        _wallService = wallService;
    }
    return self;
}

- (WallPost *)parseOne:(NSDictionary *)postData {
    WallPost *post = [_wallService parse:postData].firstObject;
    return post;
}

- (NSArray *)parseComments:(NSDictionary *)comments {
    if (![comments isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSArray *commentsData = comments[@"items"];
    if (![commentsData isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSArray *results = [EKMapper arrayOfObjectsFromExternalRepresentation:commentsData
                                                              withMapping:[Comment objectMapping]];
    return results;
}

@end
