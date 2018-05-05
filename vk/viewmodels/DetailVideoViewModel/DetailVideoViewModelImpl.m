//
//  DetailVideoViewModelImpl.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewModelImpl.h"

@protocol DetailVideoViewModelImpl <NSObject>
- (void)videoDidUpdated:(NSDictionary *)representation;
@end

@interface DetailVideoViewModelImpl () <DetailVideoViewModelImpl>
@property id<DetailVideoService> detailVideoService;
@property id<PyDetailVideoViewModel> handler;
@property id<ScreensManager> screensManager;
@end

@implementation DetailVideoViewModelImpl

@synthesize delegate = _delegate;

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
        _handler = [handlersFactory detailVideoViewModelHandlerWithDelegate:self
                                                                    ownerId:ownerId.integerValue
                                                                    videoId:videoId.integerValue];
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

#pragma mark - DetailVideoViewModelImpl
- (void)videoDidUpdated:(NSDictionary *)representation {
    Video *video = [self.detailVideoService parseOne:representation];
    NSCParameterAssert(video);
    if (!video) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(videoDidUpdated:)]) {
            [self.delegate videoDidUpdated:video];
        }
    });
}

@end
