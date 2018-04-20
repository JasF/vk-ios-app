//
//  DialogScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "DialogScreenViewModelImpl.h"

@protocol PyDialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSDictionary *)message;
- (void)handleMessageFlagsChanged:(NSDictionary *)message;
@end

@interface DialogScreenViewModelImpl () <PyDialogScreenViewModelDelegate>
@property (strong, nonatomic) id<DialogService> dialogService;
@property (strong, nonatomic) id<PyDialogScreenViewModel> handler;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (assign, nonatomic) BOOL allMessagesLoaded;
@end

@implementation DialogScreenViewModelImpl

@synthesize delegate = _delegate;

#pragma mark - Initialization
- (instancetype)initWithDialogService:(id<DialogService>)dialogService
                      handlersFactory:(id<HandlersFactory>)handlersFactory
                               userId:(NSNumber *)userId
                         pythonBridge:(id<PythonBridge>)pythonBridge {
    NSCParameterAssert(dialogService);
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(userId);
    NSCParameterAssert(pythonBridge);
    if (self) {
        _dialogService = dialogService;
        _handler = [handlersFactory dialogViewModelHandler:self parameters:@{@"userId":userId}];
        _userId = userId;
        _pythonBridge = pythonBridge;
    }
    return self;
}

- (void)dealloc {
    
}

#pragma mark - DialogScreenViewModel
- (void)getMessagesWithOffset:(NSInteger)offset
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getMessages:@(offset) userId:self.userId];
        NSArray<Message *> *messages = [_dialogService parse:data];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(messages);
            }
        });
    });
}

- (void)getMessagesWithOffset:(NSInteger)offset
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    if (self.allMessagesLoaded) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    dispatch_python(^{
        NSDictionary *data = [self.handler getMessages:@(offset) userId:self.userId startMessageId:@(startMessageId)];
        NSArray<Message *> *messages = [_dialogService parse:data];
        NSMutableArray *mutableMessages = [messages mutableCopy];
        if (mutableMessages.count) {
            [mutableMessages removeObjectAtIndex:0];
        }
        if (messages.count == 1) {
            // AV: нет более старых сообщений
            self.allMessagesLoaded = YES;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(mutableMessages);
            }
        });
    });
}

- (void)sendTextMessage:(NSString *)text
             completion:(void(^)(NSInteger messageId))completion {
    dispatch_python(^{
        NSNumber *identifier = [self.handler sendTextMessage:text
                                                      userId:_userId];
        if (completion) {
            completion(identifier.integerValue);
        }
    });
}

#pragma mark - PyDialogScreenViewModelDelegate
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary {
    Message *message = [_dialogService parseOne:messageDictionary];
    NSCParameterAssert(message);
    if (!message) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate handleIncomingMessage:message];
    });
}

- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary {
    Message *message = [_dialogService parseOne:messageDictionary];
    [self.delegate handleMessageFlagsChanged:message];
}

@end
