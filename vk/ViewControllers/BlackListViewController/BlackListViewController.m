//
//  BlackListViewController.m
//  Oxy Feed
//
//  Created by Jasf on 25.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BlackListViewController.h"
#import "Oxy_Feed-Swift.h"

@interface BlackListViewController () <BaseViewControllerDataSource>
@property (nonatomic) id<BlackListViewModel> viewModel;
@end

@implementation BlackListViewController

- (instancetype)initWithViewModel:(id<BlackListViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        [self setTitle:L(@"title_black_list")];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - BaseViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getBanned:offset
               completion:^(NSArray *objects) {
                   if (completion) {
                       completion(objects);
                   }
               }];
}


@end
