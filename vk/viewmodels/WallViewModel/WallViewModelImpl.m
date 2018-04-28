//
//  WallViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewModelImpl.h"

@interface WallViewModelImpl () <WallViewModel>
@property (strong) id<PyWallViewModel> handler;
@property (strong) id<WallService> wallService;
@property NSInteger userId;
@end

@implementation WallViewModelImpl

@synthesize currentUser = _currentUser;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService
                                 userId:(NSNumber *)userId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(wallService);
    NSCParameterAssert(userId);
    if (self) {
        self.userId = userId.integerValue;
        _handler = [handlersFactory wallViewModelHandlerWithDelegate:self parameters:@{@"userId": userId}];
        _wallService = wallService;
    }
    return self;
}

#pragma mark - WallViewModel
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getWall:@(offset)];
        if (!offset && !self.currentUser) {
            NSDictionary *currentUserData = [self.handler getUserInfo];
            User *user = [self.wallService parseUserInfo:currentUserData];
            if (user) {
                self.currentUser = user;
            }
        }
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

- (void)tappedOnPost:(WallPost *)post {
    dispatch_python(^{
        [_handler tappedOnPostWithId:@(post.identifier)];
    });
}

- (void)friendsTapped {
    dispatch_python(^{
        [_handler friendsTapped];
    });
}

- (void)commonTapped {
    dispatch_python(^{
        [_handler commonTapped];
    });
}

- (void)subscribtionsTapped {
    dispatch_python(^{
        [_handler subscribtionsTapped];
    });
}

- (void)followersTapped {
    dispatch_python(^{
        [_handler followersTapped];
    });
}

- (void)photosTapped {
    dispatch_python(^{
        [_handler photosTapped];
    });
}

- (void)videosTapped {
    dispatch_python(^{
        [_handler videosTapped];
    });
}

@end
