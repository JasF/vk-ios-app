//
//  DetailPhotoViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoViewModelImpl.h"

@interface DetailPhotoViewModelImpl ()
@property id<DetailPhotoService> detailPhotoService;
@property id<PyDetailPhotoViewModel> handler;
@end

@implementation DetailPhotoViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     detailPhotoService:(id<DetailPhotoService>)detailPhotoService
                                ownerId:(NSNumber *)ownerId
                                albumId:(NSNumber *)albumId
                                photoId:(NSNumber *)photoId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(detailPhotoService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(albumId);
    NSCParameterAssert(photoId);
    if (self) {
        _handler = [handlersFactory detailPhotoViewModelHandlerWithOwnerId:ownerId.integerValue albumId:albumId.integerValue photoId:photoId.integerValue];
        _detailPhotoService = detailPhotoService;
    }
    return self;
}

- (void)getPhotoWithCommentsOffset:(NSInteger)offset completion:(void(^)(Photo *photo, NSArray *comments))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getPhotoData:@(offset)];
        Photo *photo = [self.detailPhotoService parseOne:response[@"photoData"]];
        NSArray *comments = [self.detailPhotoService parseComments:response[@"comments"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(photo, comments);
            }
        });
    });
}

@end
