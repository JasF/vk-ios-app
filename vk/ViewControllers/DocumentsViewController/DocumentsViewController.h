//
//  DocumentsViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "DocumentsViewModel.h"

@interface DocumentsViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<DocumentsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
