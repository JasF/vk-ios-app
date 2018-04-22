//
//  ChatListViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "ChatListViewModelImpl.h"

@protocol PyChatListViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary;
- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary;
- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end;
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

#pragma mark - PyChatListViewModelDelegate
- (void)handleIncomingMessage:(NSString *)messageDictionary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate reloadData];
    });
}

- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate setTypingEnabled:!end.boolValue userId:userId.integerValue];
    });
}

@end
