//
//  WallViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "WallViewModel.h"
#import "HandlersFactory.h"
#import "WallService.h"

@protocol PyWallViewModel <NSObject>
- (NSDictionary *)getWall:(NSNumber *)offset count:(NSNumber *)count;
- (void)menuTapped;
- (NSDictionary *)getUserInfo;
- (NSDictionary *)getUserInfoCached;
- (void)friendsTapped;
- (void)commonTapped;
- (void)subscribtionsTapped;
- (void)followersTapped;
- (void)photosTapped;
- (void)videosTapped;
- (void)groupsTapped;
- (void)messageButtonTapped;
- (NSNumber *)friendButtonTapped:(NSNumber *)friend_status;
- (void)addPostTapped;
@end

@interface WallViewModelImpl : NSObject <WallViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            wallService:(id<WallService>)wallService
                                 userId:(NSNumber *)userId;
@end
