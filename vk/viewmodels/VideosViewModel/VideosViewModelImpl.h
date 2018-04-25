//
//  VideosViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "VideosViewModel.h"
#import "VideosService.h"
#import "HandlersFactory.h"

@protocol PyVideosViewModel <NSObject>
- (NSDictionary *)getVideos:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface VideosViewModelImpl : NSObject <VideosViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          videosService:(id<VideosService>)videosService
                                ownerId:(NSNumber *)ownerId;
@end
