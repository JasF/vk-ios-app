//
//  GroupsViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseTableViewController.h"
#import "GroupsViewModel.h"

@interface GroupsViewController : BaseTableViewController
- (instancetype)initWithViewModel:(id<GroupsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
