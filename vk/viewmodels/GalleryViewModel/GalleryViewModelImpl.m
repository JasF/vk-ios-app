//
//  GalleryViewModelImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GalleryViewModelImpl.h"
#import "Photo.h"

@interface GalleryViewModelImpl ()
@property id<PyGalleryViewModel> handler;
@property id<GalleryService> galleryService;
@end

@implementation GalleryViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                albumId:(id)albumId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(galleryService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(albumId);
    if (self = [super init]) {
        self.galleryService = galleryService;
        self.handler = [handlersFactory galleryViewModelHandlerWithOwnerId:ownerId.integerValue albumId:albumId];
    }
    return self;
}

#pragma mark - GalleryViewModel
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getPhotos:@(offset)];
        NSArray *result = [self.galleryService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result);
            }
        });
    });
}

- (void)tappedOnPhoto:(Photo *)photo {
    dispatch_python(^{
        [self.handler tappedOnPhotoWithId:@(photo.id)];
    });
}

@end
