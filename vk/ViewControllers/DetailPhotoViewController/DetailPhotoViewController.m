//
//  DetailPhotoViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoViewController.h"
#import "vk-Swift.h"

@interface DetailPhotoViewController () <BaseTableViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<DetailPhotoViewModel> viewModel;
@property Photo *photo;
@end

@implementation DetailPhotoViewController

- (instancetype)initWithViewModel:(id<DetailPhotoViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"Detail Photo";
    }
    return self;
}

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    if (offset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    if (self.sectionsArray.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    [_viewModel getPhotoWithCommentsOffset:offset completion:^(Photo *photo, NSArray *comments) {
        if (!self.photo) {
            self.photo = photo;
        }
        if (completion) {
            completion(comments);
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!self.sectionsArray && self.photo) {
        NSMutableArray *array = [NSMutableArray new];
        if (self.photo.owner) {
            [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeAvatarNameDate user:self.photo.owner date:self.photo.date]];
        }
        if (self.photo) {
            [array addObject:self.photo];
        }
        self.sectionsArray = @[array];
    }
    
    /*
    - (void)performBatchAnimated:(BOOL)animated {
        if (!self.sectionsArray && self.viewModel.currentUser) {
            NSMutableArray *array = [@[[[WallUserCellModel alloc] init:WallUserCellModelTypeImage user:self.viewModel.currentUser]] mutableCopy];
            if (!self.viewModel.currentUser.currentUser) {
                [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeMessage user:self.viewModel.currentUser]];
            }
            [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeActions user:self.viewModel.currentUser]];
            self.sectionsArray = @[array];
        }
        [super performBatchAnimated:animated];
    }
*/
    [super performBatchAnimated:animated];
}

@end
