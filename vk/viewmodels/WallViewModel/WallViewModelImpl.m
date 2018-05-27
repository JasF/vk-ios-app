//
//  WallViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewModelImpl.h"
#import "Oxy_Feed-Swift.h"

@protocol PyWallViewModelDelegate <NSObject>
- (void)pass;
@end

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
        DDLogInfo(@"WallInfoVMM: %@", userId);
        _handler = [handlersFactory wallViewModelHandlerWithDelegate:self parameters:@{@"userId": userId}];
        _wallService = wallService;
    }
    return self;
}

#pragma mark - WallViewModel
- (void)getWallPostsWithOffset:(NSInteger)offset
                    completion:(void(^)(NSArray *posts))completion {
    [self getWallPostsWithOffset:offset
                           count:0
                      completion:completion];
}
    
- (void)getWallPostsWithOffset:(NSInteger)offset
                         count:(NSInteger)count
                    completion:(void(^)(NSArray *posts))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getWall:@(offset) count:@(count)];
        NSArray<WallPost *> *posts = [self.wallService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(posts);
            }
        });
    });
}

- (void)getUserInfo:(void(^)(User *user, NSError *error))completion {
    dispatch_python(^{
        void (^block)(BOOL cached) = ^void(BOOL cached) {
            NSDictionary *currentUserData = (cached) ? [self.handler getUserInfoCached] : [self.handler getUserInfo];
            NSError *error = [currentUserData utils_getError];
            User *user = [self.wallService parseUserInfo:currentUserData];
            if (user) {
                self.currentUser = user;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(user, error);
                }
            });
        };
        block(YES);
        block(NO);
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [_handler menuTapped];
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

- (void)groupsTapped {
    dispatch_python(^{
        [_handler groupsTapped];
    });
}

- (void)messageButtonTapped {
    dispatch_python(^{
        [_handler messageButtonTapped];
    });
}

- (void)friendButtonTapped:(void(^)(NSInteger resultCode))callback {
    dispatch_python(^{
        NSInteger value = 0;
        if (self.currentUser.isGroup) {
            if (self.currentUser.is_member || self.currentUser.you_are_send_request) {
                value = 1;
            }
            else {
                value = 0;
            }
        }
        else {
            value = self.currentUser.friend_status;
        }
        NSNumber *response = [_handler friendButtonTapped: @(value)];
        if (!response || [response isKindOfClass:[NSNumber class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (callback) {
                    callback(response.integerValue);
                }
            });
        }
    });
}

- (void)addPostTapped {
    dispatch_python(^{
        [_handler addPostTapped];
    });
}

- (void)getLatestPostsWithCompletion:(void(^)(NSArray *objects))callback {
    [self getWallPostsWithOffset:0
                           count:1
                      completion:^(NSArray *objects) {
                          if (callback) {
                              callback(objects);
                          }
                      }];
}

#pragma mark - PyWallViewModelDelegate



@end
