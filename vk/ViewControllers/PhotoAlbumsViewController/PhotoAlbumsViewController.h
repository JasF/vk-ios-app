//
//  PhotoAlbumsViewController.h
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "PhotoAlbumsViewModel.h"
#import "NodeFactory.h"

@interface PhotoAlbumsViewController : BaseCollectionViewController
- (instancetype)initWithViewModel:(id<PhotoAlbumsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory;
@end
