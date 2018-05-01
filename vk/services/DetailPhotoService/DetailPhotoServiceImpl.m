//
//  DetailPhotoServiceImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoServiceImpl.h"
#import "Comment.h"
#import "vk-Swift.h"

@interface DetailPhotoServiceImpl ()
@property id<GalleryService> galleryService;
@property id<CommentsService> commentsService;
@end

@implementation DetailPhotoServiceImpl

#pragma mark - Initialization
- (id)initWithGalleryService:(id<GalleryService>)galleryService {
    if (self = [super init]) {
        _galleryService = galleryService;
    }
    return self;
}

- (Photo *)parseOne:(NSDictionary *)photoData {
    if (!photoData) {
        return nil;
    }
    Photo *photo = [_galleryService parse:@{@"items":@[photoData]}].firstObject;
    return photo;
}

- (User *)parseUserInfo:(NSDictionary *)userInfo {
    return nil;
}

- (NSArray *)parseComments:(NSDictionary *)comments {
    NSCParameterAssert(_commentsService);
    return [_commentsService parseComments:comments];
}
@end
