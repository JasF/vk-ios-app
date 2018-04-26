//
//  DetailVideoViewModelImpl.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewModel.h"
#import "DetailVideoService.h"
#import "HandlersFactory.h"

@protocol PyDetailVideoViewModel <NSObject>
- (NSDictionary *)getVideoData:(NSNumber *)offset;
@end

@interface DetailVideoViewModelImpl : NSObject <DetailVideoViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     detailVideoService:(id<DetailVideoService>)detailVideoService
                                ownerId:(NSNumber *)ownerId
                                videoId:(NSNumber *)videoId;
@end
