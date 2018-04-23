//
//  PhotoAlbumsViewModelImpl.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumsViewModel.h"
#import "PhotoAlbumsService.h"
#import "HandlersFactory.h"

@protocol PyPhotoAlbumsViewModel <NSObject>
- (NSDictionary *)getPhotoAlbums:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface PhotoAlbumsViewModelImpl : NSObject <PhotoAlbumsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     photoAlbumsService:(id<PhotoAlbumsService>)photoAlbumsService
                                ownerId:(NSNumber *)ownerId;
@end
