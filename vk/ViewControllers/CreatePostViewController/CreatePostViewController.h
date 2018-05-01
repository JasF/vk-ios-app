//
//  CreatePostViewController.h
//  vk
//
//  Created by Jasf on 01.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@protocol CreatePostViewModel;

@interface CreatePostViewController : ASViewController
- (id)init:(id<CreatePostViewModel>)viewModel;
@end
