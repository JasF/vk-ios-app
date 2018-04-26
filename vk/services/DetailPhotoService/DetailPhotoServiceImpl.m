//
//  DetailPhotoServiceImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoServiceImpl.h"
#import "Comment.h"

@interface DetailPhotoServiceImpl ()
@property id<GalleryService> galleryService;
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
