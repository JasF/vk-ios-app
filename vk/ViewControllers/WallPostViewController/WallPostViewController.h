//
//  WallPostViewController.h
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "SectionsCollectionViewController.h"
#import "WallPostViewModel.h"

@interface WallPostViewController : SectionsCollectionViewController
- (instancetype)initWithViewModel:(id<WallPostViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
