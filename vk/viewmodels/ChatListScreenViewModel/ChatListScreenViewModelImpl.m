//
//  ChatListScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "ChatListScreenViewModelImpl.h"

@protocol PyChatListScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary;
- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary;
- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags;
@end

@interface ChatListScreenViewModelImpl () <PyChatListScreenViewModelDelegate>
@property (strong, nonatomic) id<PyChatListScreenViewModel> handler;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (strong, nonatomic) id<ChatListService> chatListService;
@end

@implementation ChatListScreenViewModelImpl

@synthesize delegate = _delegate;

#pragma mark - Initialization
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                           pythonBridge:(id<PythonBridge>)pythonBridge
                        chatListService:(id<ChatListService>)chatListService {
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(chatListService);
    if (self = [self init]) {
        _pythonBridge = pythonBridge;
        _chatListService = chatListService;
        _handler = [handlersFactory chatListViewModelHandler:self];
    }
    return self;
}

#pragma mark - ChatListScreenViewModel
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

#pragma mark - PyChatListScreenViewModelDelegate
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

- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags {
    NSLog(@"TBD");
}

@end
