//
//  FriendsViewController.m
//  vk
//
//  Created by Jasf on 22.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "FriendsViewController.h"

@interface FriendsViewController () <BaseTableViewControllerDataSource>
@property (strong, nonatomic) id<FriendsViewModel> viewModel;
@end

@implementation FriendsViewController

- (instancetype)initWithViewModel:(id<FriendsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    _viewModel = viewModel;
    //_viewModel.delegate = self;
    self.dataSource = self;
    
    self = [super initWithNodeFactory:nodeFactory];
    
    if (self) {
        self.title = @"VK Friends";
    }
    
    return self;
}

- (void)viewDidLoad {
    NSCParameterAssert(_viewModel);
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self addMenuIconWithTarget:self action:@selector(menuTapped:)];
}

#pragma mark - Observers
- (IBAction)menuTapped:(id)sender {
    [_viewModel menuTapped];
}

#pragma mark - BaseTableViewControllerDataSource
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset {
    [_viewModel getFriendsWithOffset:offset
                          completion:completion];
}

#pragma mark - ASCollectionNodeDelegate
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = self.objectsArray[indexPath.row];
    if (!user) {
        return;
    }
    [_viewModel tappedOnUserWithId:user.id];
}

#pragma mark - FriendsViewModelDelegate
- (void)reloadData {
    [super reloadData];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
