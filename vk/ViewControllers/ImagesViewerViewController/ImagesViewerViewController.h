//
//  ImagesViewerViewController.h
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "ImagesViewerViewModel.h"
#import "NodeFactory.h"

@protocol MWPhotoBrowserViewModel;
@interface ImagesViewerViewController : UIViewController

- (instancetype)initWithViewModel:(id<ImagesViewerViewModel>)viewModel
            photoBrowserViewModel:(id<MWPhotoBrowserViewModel>)photoBrowserViewModel;
@end
