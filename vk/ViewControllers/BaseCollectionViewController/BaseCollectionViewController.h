//
//  BaseCollectionViewController.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Async_DisplayKit/Async_DisplayKit.h>
#import "NodeFactory.h"

@protocol BaseCollectionViewControllerDataSource <NSObject>
- (void)getModelObjets:(void(^)(NSArray *objects))completion
                offset:(NSInteger)offset;
@end

@interface BaseCollectionViewController : A_SViewController
@property (weak, nonatomic) id<BaseCollectionViewControllerDataSource> dataSource;
- (id)initWithNodeFactory:(id<NodeFactory>)nodeFactory;
- (void)addMenuIconWithTarget:(id)target action:(SEL)action;
@end
