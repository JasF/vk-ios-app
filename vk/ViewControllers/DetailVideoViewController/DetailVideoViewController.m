//
//  DetailVideoViewController.m
//  vk
//
//  Created by Jasf on 26.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DetailVideoViewController.h"

@interface DetailVideoViewController () <BaseCollectionViewControllerDataSource,
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

#pragma mark - BaseCollectionViewControllerDataSource
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
        }
        if (completion) {
            completion(comments);
        }
    }];
}

- (void)performBatchAnimated:(BOOL)animated {
    if (!self.sectionsArray && self.video) {
        self.sectionsArray = @[@[self.video]];
        [self.collectionNode insertSections:[NSIndexSet indexSetWithIndex:0]];
        [self.collectionNode insertItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]];
    }
    [super performBatchAnimated:animated];
}

@end
