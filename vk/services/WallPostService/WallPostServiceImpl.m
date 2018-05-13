//
//  WallPostServiceImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallPostServiceImpl.h"
#import "Comment.h"
#import "Oxy_Feed-Swift.h"

@interface WallPostServiceImpl ()
@property id<CommentsService> commentsService;
@end

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
    NSCParameterAssert(_commentsService);
    return [_commentsService parseComments:comments];
}

@end
