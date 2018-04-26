//
//  ImagesViewerViewModelImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ImagesViewerViewModelImpl.h"

@interface ImagesViewerViewModelImpl ()
@property id<PyImagesViewerViewModel> handler;
@property id<GalleryService> galleryService;
@end

@implementation ImagesViewerViewModelImpl

@synthesize photoId = _photoId;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                albumId:(NSNumber *)albumId
                                photoId:(NSNumber *)photoId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(galleryService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(albumId);
    if (self = [super init]) {
        self.photoId = photoId.integerValue;
        _galleryService = galleryService;
        _handler = [handlersFactory imagesViewerViewModelHandlerWithOwnerId:ownerId.integerValue
                                                                    albumId:albumId.integerValue
                                                                    photoId:photoId.integerValue];
    }
    return self;
}

#pragma mark - ImagesViewerViewModel
- (void)getPhotos:(NSInteger)offset completion:(void(^)(NSArray *photos))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getPhotos:@(offset)];
        NSArray *photos = [self.galleryService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(photos);
            }
        });
    });
}

- (void)navigateWithPhoto:(Photo *)photo {
    dispatch_python(^{
        [self.handler navigateWithPhotoId:@(photo.id)];
    });
}
    
@end
