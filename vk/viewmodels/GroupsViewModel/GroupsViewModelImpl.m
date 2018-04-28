//
//  GroupsViewModelImpl.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GroupsViewModelImpl.h"

@interface GroupsViewModelImpl () <GroupsViewModel>
@property (strong) id<PyGroupsViewModel> handler;
@property (strong) id<GroupsService> groupsService;
@end

@implementation GroupsViewModelImpl

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          groupsService:(id<GroupsService>)groupsService
                                 userId:(NSNumber *)userId {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(groupsService);
    NSCParameterAssert(userId);
    if (self) {
        _handler = [handlersFactory groupsViewModelHandler:userId.integerValue];
        _groupsService = groupsService;
    }
    return self;
}

#pragma mark - GroupsViewModel
- (void)getGroups:(NSInteger)offset completion:(void(^)(NSArray *Groups))completion {
    dispatch_python(^{
        NSDictionary *response = [self.handler getGroups:@(offset)];
        NSArray *objects = [self.groupsService parse:response];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(objects);
            }
        });
    });
}

- (void)menuTapped {
    dispatch_python(^{
        [self.handler menuTapped];
    });
}

- (void)tappedOnGroup:(User *)user {
    dispatch_python(^{
        [self.handler tappedOnGroupWithId:@(user.id)];
    });
}

@end
