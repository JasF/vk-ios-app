//
//  BookmarksViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BookmarksViewController.h"
#import "Oxy_Feed-Swift.h"

@interface BookmarksViewController ()<BaseViewControllerDataSource>
@property id<BookmarksViewModel> viewModel;
@end

@implementation BookmarksViewController

- (instancetype)initWithViewModel:(id<BookmarksViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        [self setTitle:L(@"title_bookmarks")];
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
    [_viewModel getBookmarks:offset
                  completion:^(NSArray *objects, NSError *error) {
                      if ([error utils_isConnectivityError]) {
                          [self showNoConnectionAlert];
                          completion(@[]);
                          return;
                      }
                      completion(objects);
                  }];
}

@end
