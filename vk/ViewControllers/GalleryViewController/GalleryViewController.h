//
//  GalleryViewController.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "GalleryViewModel.h"
#import "NodeFactory.h"

@interface GalleryViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<GalleryViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
