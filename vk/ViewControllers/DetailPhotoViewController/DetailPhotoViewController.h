//
//  DetailPhotoViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsTableViewController.h"
#import "DetailPhotoViewModel.h"

@interface DetailPhotoViewController : SectionsTableViewController
- (instancetype)initWithViewModel:(id<DetailPhotoViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
