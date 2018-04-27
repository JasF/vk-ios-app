//
//  PhotoAlbumsViewController.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PhotoAlbumsViewController.h"
#import "PhotoAlbum.h"

@interface PhotoAlbumsViewController () <BaseTableViewControllerDataSource>
@property id<PhotoAlbumsViewModel> viewModel;
@end

@implementation PhotoAlbumsViewController

- (instancetype)initWithViewModel:(id<PhotoAlbumsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"VK Photo Albums";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
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

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getPhotoAlbums:offset completion:^(NSArray *albums) {
        if (completion) {
            completion(albums);
        }
    }];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PhotoAlbum *photoAlbum = self.objectsArray[indexPath.row];
    if (!photoAlbum) {
        return;
    }
    [_viewModel clickedOnAlbumWithId:photoAlbum.id];
}

@end
