//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol PyChatListViewModel;
@protocol PyDialogScreenViewModel;
@protocol PyWallScreenViewModel;
@protocol PyMenuScreenViewModel;
@protocol PyFriendsViewModel;

@protocol HandlersFactory <NSObject>
- (id<PyChatListViewModel>)chatListViewModelHandler:(id)delegate;
- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate parameters:(NSDictionary *)parameters;
- (id<PyWallScreenViewModel>)wallViewModelHandler;
- (id<PyMenuScreenViewModel>)menuViewModelHandler;
- (id<PyFriendsViewModel>)friendsViewModelHandler;
@end
