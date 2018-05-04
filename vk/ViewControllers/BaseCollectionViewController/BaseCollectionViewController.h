//
//  BaseCollectionViewController.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "NodeFactory.h"

@protocol BaseTableViewControllerDataSource <NSObject>
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset;
@end

@interface BaseCollectionViewController : ASViewController <ASCollectionDelegate, ASCollectionDataSource>
@property (weak, nonatomic) id<BaseTableViewControllerDataSource> dataSource;
@property id<NodeFactory> nodeFactory;
@property ASCollectionNode *collectionNode;
@property UICollectionViewFlowLayout *layout;
@property BOOL pushed;
- (NSArray *)objectsArray;
- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory;
- (void)addMenuIconWithTarget:(id)target action:(SEL)action;
- (void)reloadData;
- (void)simpleReloadCollectionView;
- (void)performBatchAnimated:(BOOL)animated;
@end
