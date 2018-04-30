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
    if (!_sectionsArray && sectionsArray) {
        for (int i=0;i<sectionsArray.count;++i) {
            [self.tableNode insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
    if (sectionsArray) {
        NSArray *displayEntries = sectionsArray.firstObject;
        NSArray *oldEntries = _sectionsArray.firstObject;
        
        NSMutableArray* rowsToDelete = [NSMutableArray array];
        NSMutableArray* rowsToInsert = [NSMutableArray array];
        
        for ( NSInteger i = 0; i < oldEntries.count; i++ )
        {
            id entry = [oldEntries objectAtIndex:i];
            if ( ! [displayEntries containsObject:entry] )
                [rowsToDelete addObject: [NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        for ( NSInteger i = 0; i < displayEntries.count; i++ )
        {
            id entry = [displayEntries objectAtIndex:i];
            if ( ! [oldEntries containsObject:entry] )
                [rowsToInsert addObject: [NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [self.tableNode deleteRowsAtIndexPaths:rowsToDelete withRowAnimation:UITableViewRowAnimationFade];
        [self.tableNode insertRowsAtIndexPaths:rowsToInsert withRowAnimation:UITableViewRowAnimationFade];

    }
    _sectionsArray = sectionsArray;
}


@end
