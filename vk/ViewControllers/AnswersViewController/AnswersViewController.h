//
//  AnswersViewController.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "AnswersViewModel.h"

@interface AnswersViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<AnswersViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
