//
//  SettingsViewController.m
//  vk
//
//  Created by Jasf on 25.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsViewModel.h"
#import "Settings.h"
#import "SwitchNode.h"
#import "TextNode.h"

typedef NS_ENUM(NSInteger, SettingsRow) {
    NotificationsRow,
    ExitRow,
    RowsCount
};

@interface SettingsViewController () <BaseTableViewControllerDataSource>
@property id<SettingsViewModel> viewModel;
@property Settings *settings;
@end

@implementation SettingsViewController

- (instancetype)initWithViewModel:(id<SettingsViewModel>)viewModel
                      nodeFactory:(id<NodeFactory>)nodeFactory {
    NSCParameterAssert(viewModel);
    NSCParameterAssert(nodeFactory);
    self.dataSource = self;
    _viewModel = viewModel;
    self = [super initWithNodeFactory:nodeFactory];
    if (self) {
        self.title = @"Settings";
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
    if (offset || self.settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(@[]);
            }
        });
        return;
    }
    
    @weakify(self);
    [_viewModel getSettingsWithCompletion:^(Settings *settings) {
        @strongify(self);
        self.settings = settings;
        [self reloadData];
    }];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    @weakify(self);
    return ^ASCellNode *{
        @strongify(self);
        switch (indexPath.row) {
            case NotificationsRow: {
                @weakify(self);
                return [[SwitchNode alloc] initWithTitle:L(@"notifications")
                                                      on:self.settings.notificationsEnabled
                                             actionBlock:^(BOOL on) {
                                                 @strongify(self);
                                                 [self.viewModel notificationsSettingsChanged:on];
                                             }];
                break;
            }
            case ExitRow: return [[TextNode alloc] initWithText:L(@"exit")];
            default: {
                NSCAssert(false, @"Unhandled cell");
                break;
            }
        }
        return nil;
    };
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return @(0);
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    if (!_settings) {
        return 0;
    }
    return RowsCount;
}

@end