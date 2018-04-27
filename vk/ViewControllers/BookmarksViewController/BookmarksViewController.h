//
//  BookmarksViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseTableViewController.h"
#import "BookmarksViewModel.h"

@interface BookmarksViewController : BaseTableViewController
- (instancetype)initWithViewModel:(id<BookmarksViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
