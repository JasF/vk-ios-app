//
//  VideosViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "VideosViewModelImpl.h"
#import "Oxy_Feed-Swift.h"

@interface VideosViewModelImpl () <VideosViewModel>
@property (strong) id<PyVideosViewModel> handler;
@property (strong) id<VideosService> videosService;
@end

@implementation VideosViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          videosService:(id<VideosService>)videosService
                                ownerId:(NSNumber *)ownerId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(videosService);
    NSCParameterAssert(ownerId);
    if (self) {
        _handler = [handlersFactory videosViewModelHandler:ownerId.integerValue];
        _videosService = videosService;
    }
    return self;
}

#pragma mark - VideosViewModel
- (void)getVideos:(NSInteger)offset completion:(void(^)(NSArray *videos, NSError *error))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getVideos:@(offset)];
        NSError *error = [response utils_getError];
        NSArray *objects = [self.videosService parse:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(objects, error);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

- (void)tappedOnVideo:(Video *)video {
    dispatch_python(^{
        [self.handler tappedOnVideoWithId:@(video.id) ownerId:@(video.owner_id)];
    });
}

@end
