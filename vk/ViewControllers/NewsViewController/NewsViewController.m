//
//  NewsViewController.m
//  vk
//
//  Created by Jasf on 24.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "NewsViewController.h"
#import "Oxy_Feed-Swift.h"

@interface NewsViewController () <BaseViewControllerDataSource, PostsViewModelDelegate>
@property id<NewsViewModel> viewModel;
@end

@implementation NewsViewController

- (instancetype)initWithViewModel:(id<NewsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        [self setTitle:L(@"title_news")];
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

#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getNewsWithOffset:offset
                       completion:^(NSArray *objects, NSError *error) {
                           if ([error utils_isConnectivityError]) {
                               [self showNoConnectionAlert];
                               completion(@[]);
                               return;
                           }
                           completion(objects);
                        }];
}

#pragma mark - PostsViewModelDelegate
- (BOOL)isNewsViewController {
    return YES;
}

@end
