//
//  DocumentsViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "DocumentsViewController.h"

@interface DocumentsViewController ()

@end

@interface DocumentsViewController () <BaseTableViewControllerDataSource>
@property id<DocumentsViewModel> viewModel;
@end

@implementation DocumentsViewController

- (instancetype)initWithViewModel:(id<DocumentsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"Documents";
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
    [_viewModel getDocuments:offset
               completion:^(NSArray *objects) {
                   if (completion) {
                       completion(objects);
                   }
               }];
}

@end