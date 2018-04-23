//
//  SectionsCollectionViewController.m
//  vk
//
//  Created by Jasf on 23.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "SectionsCollectionViewController.h"

@interface SectionsCollectionViewController () <ASCollectionDelegate, ASCollectionDataSource>

@end

@implementation SectionsCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ASCollectionDelegate, ASCollectionDataSource
- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
    NSInteger count = [super numberOfSectionsInCollectionNode:collectionNode];
    count += _sectionsArray.count;
    return count;
}

- (id)collectionNode:(ASCollectionNode *)collectionNode nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_sectionsArray.count > indexPath.section) {
        NSArray *rowsArray = _sectionsArray[indexPath.section];
        NSCParameterAssert(rowsArray.count > indexPath.row);
        if (rowsArray.count <= indexPath.row) {
            return nil;
        }
        return rowsArray[indexPath.row];
    }
    return [super collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    if (_sectionsArray.count > section) {
        NSArray *rowsArray = _sectionsArray[section];
        return rowsArray.count;
    }
    return [super collectionNode:collectionNode numberOfItemsInSection:section];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (_sectionsArray.count && !indexPath.section) {
        return ^{
            NSArray *rows = _sectionsArray[indexPath.section];
            id object = rows[indexPath.row];
            ASCellNode *node = (ASCellNode *)[self.nodeFactory nodeForItem:object];
            return node;
        };
    }
    return [super collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
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
