//
//  ChatListViewController.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "NodeFactory.h"
#import "BaseCollectionViewController.h"
#import "ChatListScreenViewModel.h"

@protocol DialogsHandlerProtocol <NSObject>
- (void)menuTapped;
- (void)tappedOnDialogWithUserId:(NSNumber *)userId;
@end

@interface ChatListViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<ChatListScreenViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end