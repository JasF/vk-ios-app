//
//  ChatListViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatListViewModel.h"
#import "HandlersFactory.h"
#import "PythonBridge.h"
#import "ChatListService.h"


@protocol PyChatListViewModel <NSObject>
- (void)menuTapped;
- (void)tappedOnDialogWithUserId:(NSNumber *)userId;
- (NSDictionary *)getDialogs:(NSNumber *)offset;
@end

@interface ChatListViewModelImpl : NSObject <ChatListViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        chatListService:(id<ChatListService>)chatListService;
@end
