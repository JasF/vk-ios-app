//
//  GroupsViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "GroupsViewController.h"

@interface GroupsViewController ()<BaseCollectionViewControllerDataSource>
@property id<GroupsViewModel> viewModel;
@end

@implementation GroupsViewController

- (instancetype)initWithViewModel:(id<GroupsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"Groups";
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

#pragma mark - BaseCollectionViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getGroups:offset
               completion:^(NSArray *objects) {
                   if (completion) {
                       completion(objects);
                   }
               }];
}

@end
