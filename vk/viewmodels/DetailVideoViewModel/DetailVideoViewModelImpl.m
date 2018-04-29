//
//  DetailVideoViewModelImpl.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewModelImpl.h"

@interface DetailVideoViewModelImpl ()
@property id<DetailVideoService> detailVideoService;
@property id<PyDetailVideoViewModel> handler;
@property id<ScreensManager> screensManager;
@end

@implementation DetailVideoViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                     detailVideoService:(id<DetailVideoService>)detailVideoService
                                ownerId:(NSNumber *)ownerId
                                videoId:(NSNumber *)videoId
                         screensManager:(id<ScreensManager>)screensManager {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(detailVideoService);
    NSCParameterAssert(ownerId);
    NSCParameterAssert(videoId);
    NSCParameterAssert(screensManager);
    if (self) {
        _screensManager = screensManager;
        _handler = [handlersFactory detailVideoViewModelHandlerWithOwnerId:ownerId.integerValue videoId:videoId.integerValue];
        _detailVideoService = detailVideoService;
    }
    return self;
}

- (void)getVideoWithCommentsOffset:(NSInteger)offset completion:(void(^)(Video *video, NSArray *comments))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getVideoData:@(offset)];
        Video *video = [self.detailVideoService parseOne:response[@"videoData"]];
        NSArray *comments = [self.detailVideoService parseComments:response[@"comments"]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(video, comments);
            }
        });
    });
}

- (void)tappedOnVideo:(Video *)video {
    [self.screensManager showVideoPlayerViewControllerWithVideo:video];
}

@end
