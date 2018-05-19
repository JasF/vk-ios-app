//
//  BaseCollectionViewController.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "BaseViewController.h"
#import "NodeFactory.h"
#import "UIViewController+Utils.h"

@interface BaseCollectionViewController : BaseViewController <ASCollectionDelegate, ASCollectionDataSource>
@property (weak, nonatomic) id<BaseViewControllerDataSource> dataSource;
@property id<NodeFactory> nodeFactory;
@property ASCollectionNode *collectionNode;
@property (nonatomic) UICollectionViewFlowLayout *layout;
- (NSArray *)objectsArray;
- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory;
- (void)reloadData;
- (void)simpleReloadCollectionView;
- (void)performBatchAnimated:(BOOL)animated;
@end
