//
//  DetailVideoViewController.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewController.h"
#import "vk-Swift.h"
#import "User.h"

@interface DetailVideoViewController () <BaseTableViewControllerDataSource,
ASCollectionDelegate, ASCollectionDataSource>
@property (strong, nonatomic) id<DetailVideoViewModel> viewModel;
@property Video *video;
@end

@implementation DetailVideoViewController

- (instancetype)initWithViewModel:(id<DetailVideoViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"Detail Video";
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
        NSMutableArray *array = [NSMutableArray new];
        if (self.video.owner) {
            [array addObject:[[WallUserCellModel alloc] init:WallUserCellModelTypeAvatarNameDate user:self.video.owner date:self.video.date]];
        }
        if (self.video) {
            [array addObject:self.video];
        }
        self.sectionsArray = @[array];
    }
    [super performBatchAnimated:animated];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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

@end
