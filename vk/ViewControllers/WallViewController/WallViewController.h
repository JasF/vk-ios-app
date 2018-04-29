//
//  WallViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsTableViewController.h"
#import "HandlersFactory.h"
#import "WallService.h"
#import "WallViewModel.h"

@interface WallViewController : SectionsTableViewController
- (instancetype)initWithViewModel:(id<WallViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@property BOOL pushed;
@end
