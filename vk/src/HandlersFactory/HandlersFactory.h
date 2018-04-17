//
//  HandlersFactory.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol PyChatListScreenViewModel;
@protocol PyDialogScreenViewModel;
@protocol PyWallScreenViewModel;

@protocol HandlersFactory <NSObject>
- (id<PyChatListScreenViewModel>)chatListViewModelHandler:(id)delegate;
- (id<PyDialogScreenViewModel>)dialogViewModelHandler:(id)delegate;
- (id<PyWallScreenViewModel>)wallViewModelHandler;
@end
