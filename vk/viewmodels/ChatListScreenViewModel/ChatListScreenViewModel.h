//
//  ChatListScreenViewModel.h
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

@class Dialog;

@protocol ChatListScreenViewModelDelegate <NSObject>
- (void)reloadData;
@end

@protocol ChatListScreenViewModel <NSObject>
@property (weak) id<ChatListScreenViewModelDelegate> delegate;
- (void)menuTapped;
- (void)tappedOnDialogWithUserId:(NSInteger)userId;
- (void)getDialogsWithOffset:(NSInteger)offset
                  completion:(void(^)(NSArray<Dialog *> *dialogs))completion;
@end

