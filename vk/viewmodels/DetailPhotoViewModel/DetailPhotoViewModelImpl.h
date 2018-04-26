//
//  DetailPhotoViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoViewModel.h"
#import "DetailPhotoService.h"
#import "HandlersFactory.h"

@protocol PyDetailPhotoViewModel <NSObject>
- (NSDictionary *)getPhotoData:(NSNumber *)offset;
@end

@interface DetailPhotoViewModelImpl : NSObject <DetailPhotoViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     detailPhotoService:(id<DetailPhotoService>)detailPhotoService
                                ownerId:(NSNumber *)ownerId
                                albumId:(NSNumber *)albumId
                                photoId:(NSNumber *)photoId;
@end
