//
//  WallPostViewModelImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallPostViewModelImpl.h"
#import "HandlersFactory.h"
#import "WallPostService.h"

@interface WallPostViewModelImpl ()
@property id<WallPostService> wallPostService;
@property id<PyWallPostViewModel> handler;
@end

@implementation WallPostViewModelImpl

- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        wallPostService:(id<WallPostService>)wallPostService
                                 userId:(NSNumber *)userId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(wallPostService);
    NSCParameterAssert(userId);
    if (self) {
        _handler = [handlersFactory wallPostViewModelHandlerWithDelegate:self parameters:@{@"postId": userId}];
        _wallPostService = wallPostService;
    }
    return self;
}

- (void)getWallPostWithCompletion:(void(^)(WallPost *post))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getPostData];
        WallPost *post = [self.wallPostService parseOne:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(post);
            }
        });
    });
}

@end
