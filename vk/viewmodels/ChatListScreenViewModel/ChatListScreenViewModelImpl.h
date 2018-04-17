//
//  ChatListScreenViewModelImpl.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "ChatListScreenViewModel.h"
#import "HandlersFactory.h"
#import "PythonBridge.h"
#import "ChatListService.h"


@protocol PyChatListScreenViewModel <NSObject>
- (void)menuTapped;
- (void)tappedOnDialogWithUserId:(NSNumber *)userId;
- (NSDictionary *)getDialogs:(NSNumber *)offset;
@end

@interface ChatListScreenViewModelImpl : NSObject <ChatListScreenViewModel>
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                           pythonBridge:(id<PythonBridge>)pythonBridge
                        chatListService:(id<ChatListService>)chatListService;
@end
