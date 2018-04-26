//
//  NewsViewModelImpl.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "NewsViewModelImpl.h"

@interface NewsViewModelImpl ()
@property (strong) id<PyNewsViewModel> handler;
@property (strong) id<WallService> wallService;
@end

@implementation NewsViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(wallService);
    if (self) {
        _handler = [handlersFactory newsViewModelHandler];
        _wallService = wallService;
    }
    return self;
}

#pragma mark - NewsViewModel
- (void)getNewsWithOffset:(NSInteger)offset completion:(void(^)(NSArray *results))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getNews:@(offset)];
        NSArray *result = [self.wallService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

- (void)tappedOnPost:(WallPost *)post {
    dispatch_python(^{
        [_handler tappedOnPostWithOwnerId:@(post.owner_id) postId:@(post.identifier)];
    });
}

@end
