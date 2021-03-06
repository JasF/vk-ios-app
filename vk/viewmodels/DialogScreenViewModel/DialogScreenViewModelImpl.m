//
//  DialogScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DialogScreenViewModelImpl.h"

static CGFloat const kTypingNotifierInterval = 5.f;

@protocol PyDialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSDictionary *)message;
- (void)handleEditMessage:(NSDictionary *)message;
- (void)handleMessageDelete:(NSNumber *)messageId;
- (void)handleMessageFlagsChanged:(NSDictionary *)message;
- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end;
- (void)handleMessagesInReaded:(NSNumber *)messageId;
- (void)handleMessagesOutReaded:(NSNumber *)messageId;
@end

@interface DialogScreenViewModelImpl () <PyDialogScreenViewModelDelegate>
@property (strong, nonatomic) id<DialogService> dialogService;
@property (strong, nonatomic) id<PyDialogScreenViewModel> handler;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@property (assign, nonatomic) BOOL allMessagesLoaded;
@property (strong, nonatomic) NSMutableArray *markAsReadIds;
@property (strong, nonatomic) NSTimer *typingNotifier;
@property (strong, nonatomic) id<PostsViewModel> postsViewModel;
@end

@implementation DialogScreenViewModelImpl

@synthesize delegate = _delegate;
@synthesize user = _user;

#pragma mark - Initialization
- (instancetype)initWithDialogService:(id<DialogService>)dialogService
                      handlersFactory:(id<HandlersFactory>)handlersFactory
                               userId:(NSNumber *)userId
                         pythonBridge:(id<PythonBridge>)pythonBridge
                       postsViewModel:(id<PostsViewModel>)postsViewModel {
    NSCParameterAssert(dialogService);
    NSCParameterAssert(handlersFactory);
    NSCParameterAssert(userId);
    NSCParameterAssert(pythonBridge);
    NSCParameterAssert(postsViewModel);
    if (self) {
        _dialogService = dialogService;
        _handler = [handlersFactory dialogViewModelHandler:self parameters:@{@"userId":userId}];
        _userId = userId;
        _pythonBridge = pythonBridge;
        _markAsReadIds = [NSMutableArray new];
        _postsViewModel = postsViewModel;
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
        if (!self.user) {
            self.user = [self.dialogService parseUser:data];
        }
        NSArray<Message *> *messages = [_dialogService parse:data];
        if (!offset && messages.count) {
            // [self markAsRead:messages.firstObject];
        }
      //  dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(messages);
            }
      //  });
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
        NSArray<Message *> *messages = [self.dialogService parse:data];
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
               randomId:(NSInteger)randomId
             completion:(void(^)(NSInteger messageId))completion {
    dispatch_python(^{
        NSNumber *identifier = [self.handler sendTextMessage:text
                                                      userId:_userId
                                                    randomId:@(randomId)];
        if (completion) {
            completion(identifier.integerValue);
        }
    });
}

- (void)inputBarDidChangeText:(NSString *)text {
    if (_typingNotifier) {
        return;
    }
    _typingNotifier = [NSTimer scheduledTimerWithTimeInterval:kTypingNotifierInterval target:self selector:@selector(resumeTypingNotifications) userInfo:nil repeats:NO];
    dispatch_python(^{
        [_handler handleTypingActivity];
    });
}
    
- (void)resumeTypingNotifications {
    [_typingNotifier invalidate];
    _typingNotifier = nil;
}

- (void)userDidTappedOnPhotoWithIndex:(NSInteger)index message:(Message *)message {
    dispatch_python(^{
        [_handler tappedOnPhotoWithIndex:@(index) messageId:@(message.identifier)];
    });
}

- (void)userDidTappedOnVideo:(Video *)video message:(Message *)message {
    dispatch_python(^{
        NSDictionary *representation = [EKSerializer serializeObject:video
                                                         withMapping:[Video objectMapping]];
        if (!representation) {
            representation = @{};
        }
        [self.handler tappedOnVideoWithId:@(video.id) ownerId:@(video.owner_id) representation:representation];
    });
}

- (void)avatarTapped {
    NSCParameterAssert(self.user);
    if (!self.user) {
        return;
    }
    [self.postsViewModel tappedOnCellWithUser:self.user];
}

#pragma mark - PyDialogScreenViewModelDelegate
- (void)handleIncomingMessage:(NSDictionary *)messageDictionary {
    Message *message = [_dialogService parseOne:messageDictionary];
    NSCParameterAssert(message);
    if (!message) {
        return;
    }
    [_delegate handleIncomingMessage:message];
}

- (void)handleEditMessage:(NSDictionary *)messageDictionary {
    Message *message = [_dialogService parseOne:messageDictionary];
    NSCParameterAssert(message);
    if (!message) {
        return;
    }
    [_delegate handleEditMessage:message];
}

- (void)handleMessageDelete:(NSNumber *)messageId {
    [_delegate handleMessageDelete:messageId];
}

- (void)handleMessageFlagsChanged:(NSDictionary *)messageDictionary {
    Message *message = [_dialogService parseOne:messageDictionary];
    [self.delegate handleMessageFlagsChanged:message];
}

- (void)handleTypingInDialog:(NSNumber *)userId flags:(NSNumber *)flags end:(NSNumber *)end {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate handleTyping:userId.integerValue end:end.boolValue];
    });
}

- (void)getUser:(void(^)(User *user))completion {
    dispatch_python(^{
        NSDictionary *data = [self.handler getUserData];
        self.user = [self.dialogService parseUser:data];
        if (completion) {
            completion(self.user);
        }
    });
}

#pragma mark - Private Methods
- (void)markAsRead:(Message *)message {
    NSCParameterAssert(message);
    dispatch_python(^{
        [self markAsReadMessageWithIdentifier:message.identifier];
    });
}

- (void)markAsReadMessageWithIdentifier:(NSInteger)identifier {
    @synchronized (self) {
        if ([self.markAsReadIds containsObject:@(identifier)]) {
            return;
        }
        [self.markAsReadIds addObject:@(identifier)];
    }
    NSNumber *result = [self.handler markAsRead:self.userId messageId:@(identifier)];
    if (![result isEqual:@(1)]) {
        @synchronized (self) {
            [self.markAsReadIds removeObject:@(identifier)];
        }
    }
}

- (void)willDisplayUnreadedMessageWithIdentifier:(NSInteger)identifier
                                           isOut:(NSInteger)isOut {
    if (isOut) {
        return;
    }
    dispatch_python(^{
        [self markAsReadMessageWithIdentifier:identifier];
    });
}

- (void)handleMessagesInReaded:(NSNumber *)messageId {
    [self.delegate handleMessagesInReaded:messageId.integerValue];
}

- (void)handleMessagesOutReaded:(NSNumber *)messageId {
    [self.delegate handleMessagesOutReaded:messageId.integerValue];
}

@end
