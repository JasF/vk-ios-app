//
//  CommentsViewController.h
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsTableViewController.h"

@interface CommentsViewController : SectionsTableViewController
@property id commentsParentItem;
- (void)hideCommentsToolbar;
- (void)showCommentsToolbar;
@end
