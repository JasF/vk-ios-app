//
//  FriendsViewModelImpl.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "FriendsViewModel.h"
#import "HandlersFactory.h"
#import "FriendsService.h"

@protocol PyFriendsViewModel <NSObject>
- (NSDictionary *)getFriends:(NSNumber *)offset;
- (void)menuTapped;
- (void)tappedOnUserWithId:(NSNumber *)userId;
@end

@interface FriendsViewModelImpl : NSObject<FriendsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         friendsService:(id<FriendsService>)friendsService
                                 userId:(NSNumber *)userId
                          subscriptions:(NSNumber *)subscriptions;
@end
