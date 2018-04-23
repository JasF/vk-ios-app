//
//  GalleryViewModelImpl.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GalleryViewModel.h"
#import "GalleryService.h"
#import "HandlersFactory.h"

@protocol PyGalleryViewModel <NSObject>
- (NSDictionary *)getPhotos:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface GalleryViewModelImpl : NSObject <GalleryViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         galleryService:(id<GalleryService>)galleryService
                                ownerId:(NSNumber *)ownerId
                                albumId:(id)albumId;
@end
