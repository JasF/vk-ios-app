//
//  PostsViewController.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseTableViewController.h"
#import "PostsViewModel.h"

@interface PostsViewController : BaseTableViewController
@property id<PostsViewModel> postsViewModel;
@end
