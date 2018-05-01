//
//  BaseTableViewController.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "BaseCollectionViewController.h"
#import "NodeFactory.h"

@interface BaseTableViewController : ASViewController <ASTableDelegate, ASTableDataSource>
@property (weak, nonatomic) id<BaseTableViewControllerDataSource> dataSource;
@property id<NodeFactory> nodeFactory;
@property ASTableNode *tableNode;
- (NSMutableArray *)objectsArray;
- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory;
- (void)addMenuIconWithTarget:(id)target action:(SEL)action;
- (void)reloadData;
- (void)performBatchAnimated:(BOOL)animated;
@end
