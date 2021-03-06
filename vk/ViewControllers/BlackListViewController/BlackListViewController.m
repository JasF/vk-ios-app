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
    self.tableNode.view.editing = YES;
    self.tableNode.allowsSelectionDuringEditing = YES;
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableNode:(ASTableNode *)tableNode performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSCAssert(indexPath.row < self.objectsArray.count, @"indexpath out of bounds: %@", indexPath);
        if (indexPath.row >= self.objectsArray.count) {
            return;
        }
        User *user = self.objectsArray[indexPath.row];
        @weakify(self);
        [_viewModel unbanUser:user completion:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self.objectsArray removeObjectAtIndex:indexPath.row];
                [self.tableNode deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
    }
}
/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
}
 */

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

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableNode deselectRowAtIndexPath:indexPath animated:YES];
    NSCAssert(indexPath.row < self.objectsArray.count, @"indexpath out of bounds: %@", indexPath);
    if (indexPath.row >= self.objectsArray.count) {
        return;
    }
    User *user = self.objectsArray[indexPath.row];
    [_viewModel tappedWithUser:user];
}

@end
