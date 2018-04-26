//
//  DetailVideoViewController.h
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsCollectionViewController.h"
#import "DetailVideoViewModel.h"

@interface DetailVideoViewController : SectionsCollectionViewController
- (instancetype)initWithViewModel:(id<DetailVideoViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
