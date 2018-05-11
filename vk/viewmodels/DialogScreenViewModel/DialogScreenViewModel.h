//
//  DialogScreenViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

@protocol DialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(Message *)message;
- (void)handleEditMessage:(Message *)message;
- (void)handleMessageDelete:(NSNumber *)messageId;
- (void)handleMessageFlagsChanged:(Message *)message;
- (void)handleTyping:(NSInteger)userId end:(BOOL)end;
- (void)handleMessagesInReaded:(NSInteger)messageId;
- (void)handleMessagesOutReaded:(NSInteger)messageId;
@end

@protocol DialogScreenViewModel <NSObject>
@property (weak) id<DialogScreenViewModelDelegate> delegate;
@property (nonatomic) User *user;
- (void)getUser:(void(^)(User *user))completion;
- (void)getMessagesWithOffset:(NSInteger)offset
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)getMessagesWithOffset:(NSInteger)offset
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)sendTextMessage:(NSString *)text
               randomId:(NSInteger)randomId
             completion:(void(^)(NSInteger messageId))completion;
- (void)willDisplayUnreadedMessageWithIdentifier:(NSInteger)identifier
                                           isOut:(NSInteger)isOut;
- (void)inputBarDidChangeText:(NSString *)text;
- (void)userDidTappedOnPhotoWithIndex:(NSInteger)index message:(Message *)message;
- (void)userDidTappedOnVideo:(Video *)video message:(Message *)message;
- (void)avatarTapped;
@end
