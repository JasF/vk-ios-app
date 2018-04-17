//
//  DialogScreenViewModelImpl.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "DialogScreenViewModelImpl.h"

@protocol PyDialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSString *)message
                       userId:(NSNumber *)userId
                    timestamp:(NSNumber *)timestamp;
@end

@interface DialogScreenViewModelImpl () <PyDialogScreenViewModelDelegate>
@property (strong, nonatomic) id<DialogService> dialogService;
@property (strong, nonatomic) NSNumber *userId;
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@end

@implementation DialogScreenViewModelImpl

@synthesize delegate = _delegate;

#pragma mark - Initialization
- (instancetype)initWithDialogService:(id<DialogService>)dialogService
                               userId:(NSNumber *)userId
                         pythonBridge:(id<PythonBridge>)pythonBridge {
    NSCParameterAssert(dialogService);
    NSCParameterAssert(userId);
    NSCParameterAssert(pythonBridge);
    if (self) {
        _dialogService = dialogService;
        _userId = userId;
        _pythonBridge = pythonBridge;
        [_pythonBridge setClassHandler:self name:@"PyDialogScreenViewModelDelegate"];
    }
    return self;
}

#pragma mark - DialogScreenViewModel
- (void)getMessagesWithOffset:(NSInteger)offset
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_dialogService getMessagesWithOffset:offset
                                       userId:_userId.integerValue
                                   completion:completion];
    });
}

- (void)getMessagesWithOffset:(NSInteger)offset
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion {
    [_dialogService getMessagesWithOffset:offset
                                   userId:_userId.integerValue
                           startMessageId:startMessageId
                               completion:completion];
}

- (void)sendTextMessage:(NSString *)text {
    [_dialogService sendTextMessage:text
                             userId:_userId.integerValue];
}

#pragma mark - PyDialogScreenViewModelDelegate
- (void)handleIncomingMessage:(NSString *)message
                       userId:(NSNumber *)userId
                    timestamp:(NSNumber *)timestamp {
    if ([_delegate respondsToSelector:@selector(handleIncomingMessage:userId:timestamp:)]) {
        [_delegate handleIncomingMessage:message
                                  userId:userId
                               timestamp:timestamp];
    }
}

@end
