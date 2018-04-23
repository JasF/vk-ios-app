//
//  PhotoAlbumsViewModelImpl.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumsViewModelImpl.h"

@interface PhotoAlbumsViewModelImpl ()
@property id<PhotoAlbumsService> photoAlbumsService;
@property id<PyPhotoAlbumsViewModel> handler;
@end

@implementation PhotoAlbumsViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     photoAlbumsService:(id<PhotoAlbumsService>)photoAlbumsService
                                ownerId:(NSNumber *)ownerId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(photoAlbumsService);
    NSCParameterAssert(ownerId);
    if (self) {
        _handler = [handlersFactory photoAlbumsViewModelHandler:ownerId.integerValue];
        _photoAlbumsService = photoAlbumsService;
    }
    return self;
}

- (void)getPhotoAlbums:(NSInteger)offset
            completion:(void(^)(NSArray *albums))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getPhotoAlbums:@(offset)];
        NSArray *albums = [self.photoAlbumsService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(albums);
            }
        });
    });
}

- (void)clickedOnAlbumAtIndex:(NSInteger)index {
    
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

@end
