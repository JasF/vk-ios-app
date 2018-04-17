//
//  WallViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "HandlersFactory.h"
#import "WallService.h"
#import "WallScreenViewModel.h"

@interface WallViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<WallScreenViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end