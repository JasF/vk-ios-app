//
//  FriendsViewController.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "NodeFactory.h"
#import "BaseTableViewController.h"
#import "ChatListViewModel.h"
#import "FriendsViewModel.h"

@interface FriendsViewController : BaseTableViewController
- (instancetype)initWithViewModel:(id<FriendsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
