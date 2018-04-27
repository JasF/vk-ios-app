//
//  VideosViewController.h
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "VideosViewModel.h"

@interface VideosViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<VideosViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end