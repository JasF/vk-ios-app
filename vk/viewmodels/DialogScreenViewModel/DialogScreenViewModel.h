//
//  DialogScreenViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

@protocol DialogScreenViewModelDelegate <NSObject>
- (void)handleIncomingMessage:(NSString *)message
                       userId:(NSNumber *)userId
                    timestamp:(NSNumber *)timestamp;
@end

@protocol DialogScreenViewModel <NSObject>
@property (weak) id<DialogScreenViewModelDelegate> delegate;
- (void)getMessagesWithOffset:(NSInteger)offset
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)getMessagesWithOffset:(NSInteger)offset
               startMessageId:(NSInteger)startMessageId
                   completion:(void(^)(NSArray<Message *> *messages))completion;
- (void)sendTextMessage:(NSString *)text;
@end
