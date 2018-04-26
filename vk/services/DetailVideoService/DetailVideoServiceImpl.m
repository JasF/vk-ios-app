//
//  DetailVideoServiceImpl.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoServiceImpl.h"
#import "Comment.h"

@interface DetailVideoServiceImpl ()
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
