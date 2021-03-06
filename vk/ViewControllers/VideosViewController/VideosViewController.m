//
//  VideosViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "VideosViewController.h"
#import "Oxy_Feed-Swift.h"

@interface VideosViewController () <BaseViewControllerDataSource>
@property id<VideosViewModel> viewModel;
@end

@implementation VideosViewController

- (instancetype)initWithViewModel:(id<VideosViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        [self setTitle:L(@"title_videos")];
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

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getVideos:offset
               completion:^(NSArray *objects, NSError *error) {
                   if ([error utils_isConnectivityError]) {
                       [self showNoConnectionAlert];
                       completion(@[]);
                       return;
                   }
                   completion(objects);
               }];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [super tableNode:tableNode didSelectRowAtIndexPath:indexPath];
    Video *video = self.objectsArray[indexPath.row];
    if (!video) {
        return;
    }
    [_viewModel tappedOnVideo:video];
}

@end
