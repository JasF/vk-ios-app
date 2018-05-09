//
//  ChatListViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "ChatListViewModelImpl.h"

@protocol PyChatListViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary;
- (void)handleEditMessage:(NSDictionary *)messageDictionary;
- (void)handleMessageDelete:(NSNumber *)messageId;
- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary;
- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end;
- (void)handleMessagesInReaded:(NSNumber *)userId localId:(NSNumber *)messageId;
- (void)handleMessagesOutReaded:(NSNumber *)userId localId:(NSNumber *)messageId;
- (void)handleNeedsUpdate;
@end

@interface ChatListViewModelImpl () <PyChatListViewModelDelegate>
@property (strong, nonatomic) id<PyChatListViewModel> handler;
@property (strong, nonatomic) id<ChatListService> chatListService;
@end

@implementation ChatListViewModelImpl

@synthesize delegate = _delegate;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                        chatListService:(id<ChatListService>)chatListService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(chatListService);
    if (self = [self init]) {
        _chatListService = chatListService;
        _handler = [handlersFactory chatListViewModelHandler:self];
    }
    return self;
}

#pragma mark - ChatListViewModel
- (void)menuTapped {
    dispatch_python(^{
        [_handler menuTapped];
    });
}

- (void)tappedOnDialogWithUserId:(NSInteger)userId {
    dispatch_python(^{
        [_handler tappedOnDialogWithUserId:@(userId)];
    });
}

- (void)getDialogsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<Dialog *> *dialogs))completion {
    dispatch_python(^{
        NSDictionary *chatListData = [self.handler getDialogs:@(offset)];
        NSArray *dialogs = [_chatListService parse:chatListData];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(dialogs);
            }
        });
    });
}

- (void)becomeActive {
    dispatch_python(^{
        [_handler becomeActive];
    });
}

- (void)resignActive {
    dispatch_python(^{
        [_handler resignActive];
    });
}

#pragma mark - PyChatListViewModelDelegate
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleEditMessage:(NSDictionary *)messageDictionary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleMessageDelete:(NSNumber *)messageId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleMessagesInReaded:(NSNumber *)userId localId:(NSNumber *)messageId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleMessagesOutReaded:(NSNumber *)userId localId:(NSNumber *)messageId {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate setTypingEnabled:!end.boolValue userId:userId.integerValue];
    });
}

- (void)handleNeedsUpdate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

@end
