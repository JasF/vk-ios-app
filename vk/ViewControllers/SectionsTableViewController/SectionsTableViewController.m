//
//  SectionsTableViewController.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsTableViewController.h"

@interface SectionsTableViewController () <ASTableDelegate, ASTableDataSource>

@end

@implementation SectionsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASTableDelegate, ASTableDataSource
- (NSInteger)numberOfSectionsInTableNode:(ASTableNode *)tableNode
{
    NSInteger count = [super numberOfSectionsInTableNode:tableNode];
    count += _sectionsArray.count;
    return count;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_sectionsArray.count > indexPath.section) {
        NSArray *rowsArray = _sectionsArray[indexPath.section];
        NSCParameterAssert(rowsArray.count > indexPath.row);
        if (rowsArray.count <= indexPath.row) {
            return nil;
        }
        @weakify(self);
        return ^{
            @strongify(self);
            id object = rowsArray[indexPath.row];
            ASCellNode *node = (ASCellNode *)[self.nodeFactory nodeForItem:object];
            return node;
        };
    }
    return [super tableNode:tableNode nodeBlockForRowAtIndexPath:indexPath];
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
    if (_sectionsArray.count > section) {
        NSArray *rowsArray = _sectionsArray[section];
        return rowsArray.count;
    }
    return [super tableNode:tableNode numberOfRowsInSection:section];
}

- (void)setSectionsArray:(NSArray *)sectionsArray {
    NSCAssert(!_sectionsArray, @"TBD: deleteRows");
    _sectionsArray = sectionsArray;
    if (sectionsArray) {
        for (NSInteger section = 0; section < _sectionsArray.count; ++section) {
            [self.tableNode insertSections:[NSIndexSet indexSetWithIndex:section]
                          withRowAnimation:UITableViewRowAnimationFade];
            NSArray *rows = _sectionsArray[section];
            NSMutableArray *indexPathes = [NSMutableArray new];
            for (NSInteger row = 0; row < rows.count; ++row) {
                [indexPathes addObject:[NSIndexPath indexPathForRow:row inSection:section]];
            }
            [self.tableNode insertRowsAtIndexPaths:indexPathes
                                  withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

@end
