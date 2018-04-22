//
//  WallPostServiceImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallPostServiceImpl.h"

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

@end
