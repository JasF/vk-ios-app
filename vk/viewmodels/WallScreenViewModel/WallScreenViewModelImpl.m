//
//  WallScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "WallScreenViewModelImpl.h"

@interface WallScreenViewModelImpl ()
@property (strong) id<PyWallScreenViewModel> handler;
@property (strong) id<WallService> wallService;
@end

@implementation WallScreenViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(wallService);
    if (self) {
        _handler = [handlersFactory wallViewModelHandler];
        _wallService = wallService;
    }
    return self;
}

#pragma mark - WallScreenViewModel
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getWall:@(offset)];
        NSArray<WallPost *> *posts = [self.wallService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(posts);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [_handler menuTapped];
    });
}

@end
