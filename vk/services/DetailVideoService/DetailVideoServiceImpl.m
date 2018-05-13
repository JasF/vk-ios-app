//
//  DetailVideoServiceImpl.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoServiceImpl.h"
#import "Comment.h"
#import "Oxy_Feed-Swift.h"

@interface DetailVideoServiceImpl ()
@property id<CommentsService> commentsService;
@end

@implementation DetailVideoServiceImpl

- (Video *)parseOne:(NSDictionary *)videoData {
    if (!videoData) {
        return nil;
    }
    Video *video = [EKMapper objectFromExternalRepresentation:videoData
                                                  withMapping:[Video objectMapping]];
    return video;
}

- (NSArray *)parseComments:(NSDictionary *)comments {
    NSCParameterAssert(_commentsService);
    return [_commentsService parseComments:comments];
}
@end
