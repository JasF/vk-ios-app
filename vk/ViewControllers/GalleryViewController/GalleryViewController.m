//
//  GalleryViewController.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GalleryViewController.h"

@interface GalleryViewController () <BaseTableViewControllerDataSource>
@property id<GalleryViewModel> viewModel;
@end

@implementation GalleryViewController

- (instancetype)initWithViewModel:(id<GalleryViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    _viewModel = viewModel;
    self.dataSource = self;
    if (self = [super initWithNodeFactory:nodeFactory]) {
        self.title = @"VK Photos";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ASSizeRange result = ASSizeRangeUnconstrained;
    result.min.width = self.view.width/4;
    result.max.width = self.view.width/4;
    return result;
}

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getPhotos:offset completion:^(NSArray *photos) {
        if (completion) {
            completion(photos);
        }
    }];
}

#pragma mark - ASCollectionNodeDelegate
- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Photo *photo = [collectionNode nodeModelForItemAtIndexPath:indexPath];
    if (!photo) {
        return;
    }
    [_viewModel tappedOnPhoto:photo];
}

@end
