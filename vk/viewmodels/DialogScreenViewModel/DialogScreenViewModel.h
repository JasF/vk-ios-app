//
//  DialogScreenViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

@protocol DialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(Message *)message;
- (void)handleMessageFlagsChanged:(Message *)message;
- (void)handleTyping:(NSInteger)userId end:(BOOL)end;
@end

@protocol DialogScreenViewModel <NSObject>
@property (weak) id<DialogScreenViewModelDelegate> delegate;
- (void)getMessagesWithOffset:(NSInteger)offset
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)getMessagesWithOffset:(NSInteger)offset
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)sendTextMessage:(NSString *)text
             completion:(void(^)(NSInteger messageId))completion;
- (void)willDisplayUnreadedMessageWithIdentifier:(NSInteger)identifier
                                           isOut:(NSInteger)isOut;
- (void)inputBarDidChangeText:(NSString *)text;
@end
