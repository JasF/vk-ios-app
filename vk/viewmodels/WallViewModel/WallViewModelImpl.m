//
//  WallViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewModelImpl.h"

@protocol PyWallViewModelDelegate <NSObject>
- (void)friendsCountDidUpdated:(NSNumber *)friendsCount;
- (void)photosCountDidUpdated:(NSNumber *)photos;
- (void)videosCountDidUpdated:(NSNumber *)videos;
- (void)groupsCountDidUpdated:(NSNumber *)groups;
- (void)interestPagesCountDidUpdated:(NSNumber *)interestPages;
@end

@interface WallViewModelImpl () <WallViewModel>
@property (strong) id<PyWallViewModel> handler;
@property (strong) id<WallService> wallService;
@property NSInteger userId;
@end

@implementation WallViewModelImpl

@synthesize friendsCountDidUpdated = _friendsCountDidUpdated;
@synthesize photosCountDidUpdated = _photosCountDidUpdated;
@synthesize videosCountDidUpdated = _videosCountDidUpdated;
@synthesize groupsCountDidUpdated = _groupsCountDidUpdated;
@synthesize interestPagesCountDidUpdated = _interestPagesCountDidUpdated;

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

- (void)friendButtonTapped {
    dispatch_python(^{
        [_handler friendButtonTapped];
    });
}

#pragma mark - PyWallViewModelDelegate
- (void)friendsCountDidUpdated:(NSNumber *)friendsCount {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.friendsCountDidUpdated) {
            self.friendsCountDidUpdated(friendsCount);
        }
    });
}

- (void)photosCountDidUpdated:(NSNumber *)photos {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.photosCountDidUpdated) {
            self.photosCountDidUpdated(photos);
        }
    });
}

- (void)groupsCountDidUpdated:(NSNumber *)groups {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.groupsCountDidUpdated) {
            self.groupsCountDidUpdated(groups);
        }
    });
}

- (void)videosCountDidUpdated:(NSNumber *)videos {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.videosCountDidUpdated) {
            self.videosCountDidUpdated(videos);
        }
    });
}

- (void)interestPagesCountDidUpdated:(NSNumber *)interestPages {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.interestPagesCountDidUpdated) {
            self.interestPagesCountDidUpdated(interestPages);
        }
    });
}

@end
