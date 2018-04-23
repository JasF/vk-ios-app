//
//  ChatListViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

@class Dialog;

@protocol ChatListViewModelDelegate <NSObject>
- (void)reloadData;
- (void)setTypingEnabled:(BOOL)enabled userId:(NSInteger)userId;
@end

@protocol ChatListViewModel <NSObject>
@property (weak) id<ChatListViewModelDelegate> delegate;
- (void)menuTapped;
- (void)tappedOnDialogWithUserId:(NSInteger)userId;
- (void)getDialogsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<Dialog *> *dialogs))completion;
@end

