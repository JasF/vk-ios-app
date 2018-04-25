//
//  GroupsViewModelImpl.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GroupsViewModel.h"
#import "HandlersFactory.h"
#import "GroupsService.h"

@protocol PyGroupsViewModel <NSObject>
- (NSDictionary *)getGroups:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface GroupsViewModelImpl : NSObject <GroupsViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                          groupsService:(id<GroupsService>)groupsService
                                 userId:(NSNumber *)userId;
@end
