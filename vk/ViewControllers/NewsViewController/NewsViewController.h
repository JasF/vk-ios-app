//
//  NewsViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "HandlersFactory.h"
#import "WallService.h"

@protocol NewsHandlerProtocol <NSObject>
- (void)menuTapped;
@end

@interface NewsViewController : BaseCollectionViewController
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            nodeFactory:(id<NodeFactory>)nodeFactory
                            wallService:(id<WallService>)wallService;
@end
