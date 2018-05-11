//
//  PhotoAlbumsViewController.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumsViewController.h"
#import "PhotoAlbum.h"
#import "vk-Swift.h"

static NSInteger const kNumberOfColumns = 2;
static CGFloat const kInteritemSpacing = 12.f;

@interface PhotoAlbumsViewController () <BaseTableViewControllerDataSource>
@property id<PhotoAlbumsViewModel> viewModel;
@end

@implementation PhotoAlbumsViewController {
    AlignTopCollectionViewFlowLayout *_layout;
}

- (instancetype)initWithViewModel:(id<PhotoAlbumsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    self.layout.minimumInteritemSpacing = kInteritemSpacing;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        [self setTitle:L(@"title_photo_albums")];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}

#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_viewModel menuTapped];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BaseCollectionViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getPhotoAlbums:offset completion:^(NSArray *albums) {
        if (completion) {
            completion(albums);
        }
    }];
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ASSizeRange result = ASSizeRangeUnconstrained;
    result.min.width = (self.view.width-kInteritemSpacing)/2;
    result.max.width = result.min.width;
    return result;
}

#pragma mark - ASCollectionNodeDelegate
- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    PhotoAlbum *photoAlbum = self.objectsArray[indexPath.row];
    if (!photoAlbum) {
        return;
    }
    [_viewModel clickedOnAlbumWithId:photoAlbum.id];
}

- (UICollectionViewFlowLayout *)layout {
    if (!_layout) {
        _layout = [AlignTopCollectionViewFlowLayout new];
        _layout.numberOfColumns = kNumberOfColumns;
    }
    return _layout;
}
@end
