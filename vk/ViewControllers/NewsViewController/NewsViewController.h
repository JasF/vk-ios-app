//
//  NewsViewController.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PostsViewController.h"
#import "NewsViewModel.h"

@interface NewsViewController : PostsViewController
- (instancetype)initWithViewModel:(id<NewsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
