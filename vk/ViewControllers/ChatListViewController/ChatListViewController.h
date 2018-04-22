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
#import "ChatListViewModel.h"

@interface ChatListViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<ChatListViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
