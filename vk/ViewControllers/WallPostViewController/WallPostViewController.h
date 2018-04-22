//
//  WallPostViewController.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "WallPostViewModel.h"

@interface WallPostViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<WallPostViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
