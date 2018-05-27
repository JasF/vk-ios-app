//
//  FriendsViewModelImpl.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "FriendsViewModelImpl.h"
#import "Oxy_Feed-Swift.h"

@interface FriendsViewModelImpl ()
@property id<PyFriendsViewModel> handler;
@property (strong, nonatomic) id<FriendsService> friendsService;
@end

@implementation FriendsViewModelImpl
#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                         friendsService:(id<FriendsService>)friendsService
                                 userId:(NSNumber *)userId
                          usersListType:(NSNumber *)usersListType {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(friendsService);
    NSCParameterAssert(userId);
    if (self = [self init]) {
        _friendsService = friendsService;
        _handler = [handlersFactory friendsViewModelHandler:userId.integerValue usersListType:usersListType];
    }
    return self;
}

#pragma mark - FriendsViewModel
- (void)getFriendsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<User *> *users, NSError *error))completion {
    dispatch_python(^{
        NSDictionary *data = [_handler getFriends:@(offset)];
        NSError *error = [data utils_getError];
        NSArray *friends = [_friendsService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(friends, error);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [_handler menuTapped];
    });
}

- (void)tappedOnUserWithId:(NSInteger)userId {
    dispatch_python(^{
        [_handler tappedOnUserWithId:@(userId)];
    });
}

@end
    
