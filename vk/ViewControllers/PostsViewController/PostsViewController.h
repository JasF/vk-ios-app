//
//  PostsViewController.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseTableViewController.h"
#import "PostsViewModel.h"

@interface PostsViewController : BaseTableViewController <PostsViewModelDelegate>
@property id<PostsViewModel> postsViewModel;
@property (nonatomic) BOOL commentsPreloading;
- (void)numberOfCommentsDidUpdated:(NSInteger)numberOfComments;
- (void)tableNode:(ASTableNode *)tableNode willDisplayRowWithNode:(ASCellNode *)aNode;
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end
