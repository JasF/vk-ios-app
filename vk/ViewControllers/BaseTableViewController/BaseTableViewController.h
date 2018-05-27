//
//  BaseTableViewController.h
//  vk
//
//  Created by Jasf on 27.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "BaseViewController.h"
#import "NodeFactory.h"
#import "UIViewController+Utils.h"

@interface BaseTableViewController : BaseViewController <ASTableDelegate, ASTableDataSource>
@property (weak, nonatomic) id<BaseViewControllerDataSource> dataSource;
@property ASTableNode *tableNode;
- (NSMutableArray *)objectsArray;
- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory;
- (void)reloadData;
- (void)performBatchAnimated:(BOOL)animated;
- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end
