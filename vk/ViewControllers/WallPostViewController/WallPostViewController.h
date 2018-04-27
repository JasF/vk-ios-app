//
//  WallPostViewController.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsTableViewController.h"
#import "WallPostViewModel.h"

@interface WallPostViewController : SectionsTableViewController
- (instancetype)initWithViewModel:(id<WallPostViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
