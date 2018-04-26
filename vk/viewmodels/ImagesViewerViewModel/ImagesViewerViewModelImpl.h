//
//  ImagesViewerViewModelImpl.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ImagesViewerViewModel.h"
#import "HandlersFactory.h"
#import "GalleryService.h"

@protocol PyImagesViewerViewModel <NSObject>
- (NSDictionary *)getPhotos:(NSNumber *)offset;
- (void)navigateWithPhotoId:(NSNumber *)photoId;
@end

@interface ImagesViewerViewModelImpl : NSObject <ImagesViewerViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                albumId:(NSNumber *)albumId
                                photoId:(NSNumber *)photoId;
@end
