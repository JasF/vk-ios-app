//
//  DetailPhotoViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailPhotoViewController.h"
#import "Oxy_Feed-Swift.h"

static NSInteger const kOffsetForPreloadLatestComments = -1;
@interface DetailPhotoViewController () <BaseViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<DetailPhotoViewModel> viewModel;
@property Photo *photo;
@property (nonatomic) WallUserCellModel *avatarModel;
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
        [self setTitle:L(@"title_detail_photo")];
    }
    return self;
}

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    dispatch_block_t completionBlock = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
    };
    if (offset) {
        completionBlock();
        return;
    }
    if (self.sectionsArray.count) {
        completionBlock();
        return;
    }
    [_viewModel getPhotoWithCommentsOffset:kOffsetForPreloadLatestComments completion:^(Photo *photo, NSArray *comments) {
        if (!self.photo) {
            self.photo = photo;
            self.commentsParentItem = photo;
            if (self.photo.can_comment) {
                [self showCommentsToolbar];
            }
        }
        if (completion) {
            completion(comments);
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    NSMutableArray *array = [NSMutableArray new];
    if (self.avatarModel) {
        [array addObject:self.avatarModel];
    }
    if (self.photo) {
        [array addObject:self.photo];
    }
    if (self.objectsArray.count && self.photo.comments.count > self.objectsArray.count) {
        [self showPreloadCommentsCellWithCount:self.photo.comments.count item:self.photo section:array];
    }
    self.sectionsArray = @[array];
    [super performBatchAnimated:animated];
}

#pragma mark - Private Methods
- (WallUserCellModel *)avatarModel {
    if (!_avatarModel && self.photo.owner) {
        _avatarModel = [[WallUserCellModel alloc] init:WallUserCellModelTypeAvatarNameDate user:self.photo.owner date:self.photo.date];
    }
    return _avatarModel;
}

#pragma mark - BaseViewController
- (ScreenType)screenType {
    return ScreenDetailPhoto;
}

@end
