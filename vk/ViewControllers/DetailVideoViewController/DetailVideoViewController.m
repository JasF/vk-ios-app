//
//  DetailVideoViewController.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewController.h"
#import "Oxy_Feed-Swift.h"
#import "User.h"

@interface DetailVideoViewController () <BaseTableViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource, DetailVideoViewModelDelegate>
@property (strong, nonatomic) id<DetailVideoViewModel> viewModel;
@property Video *video;
@end

@implementation DetailVideoViewController {
    WallUserCellModel *_avatarModel;
    VideoModel *_videoModel;
}

- (instancetype)initWithViewModel:(id<DetailVideoViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        _viewModel.delegate = self;
        [self setTitle:L(@"title_detail_video")];
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
    [_viewModel getVideoWithCommentsOffset:offset completion:^(Video *video, NSArray *comments) {
        if (!self.video) {
            self.video = video;
            self.commentsParentItem = video;
            if (self.video.can_comment) {
                [self showCommentsToolbar];
            }
        }
        if (completion) {
            completion(comments);
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!self.sectionsArray && self.video) {
        [self updateSections];
    }
    [super performBatchAnimated:animated];
}

- (void)updateSections {
    NSMutableArray *array = [NSMutableArray new];
    if (self.video.owner || _avatarModel) {
        [array addObject:[self avatarModel]];
    }
    if (self.video || _videoModel) {
        [array addObject:[self videoModel]];
    }
    self.sectionsArray = @[array];
}

- (WallUserCellModel *)avatarModel {
    if (!_avatarModel) {
        _avatarModel = [[WallUserCellModel alloc] init:WallUserCellModelTypeAvatarNameDate user:self.video.owner date:self.video.date];
    }
    return _avatarModel;
}

- (VideoModel *)videoModel {
    if (!_videoModel) {
        _videoModel = [[VideoModel alloc] init:self.video];
    }
    return _videoModel;
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableNode:tableNode didSelectRowAtIndexPath:indexPath];
    if (!indexPath.section && self.sectionsArray) {
        NSArray *section = self.sectionsArray[0];
        NSCAssert(indexPath.row < section.count, @"Unknown indexPath: %@", indexPath);
        if (indexPath.row >= section.count) {
            return;
        }
        if ([section[indexPath.row] isEqual:self.video]) {
            [_viewModel tappedOnVideo:self.video];
            return;
        }
    }
    [super tableNode:tableNode didSelectRowAtIndexPath:indexPath];
}

#pragma mark -
- (void)videoDidUpdated:(Video *)video {
    self.video = video;
    [self videoModel].video = video;
    [self updateSections];
    [self.tableNode reloadData];
}

@end
