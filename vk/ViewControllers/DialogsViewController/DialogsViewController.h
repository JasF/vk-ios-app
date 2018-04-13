//
//  DialogsViewController.h
//  vk
//
//  Created by Jasf on 12.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "PythonBridge.h"
#import "NodeFactory.h"
#import "HandlersFactory.h"
#import "DialogsService.h"
#import "BaseCollectionViewController.h"

@protocol DialogsHandlerProtocol <NSObject>
- (void)menuTapped;
@end

@interface DialogsViewController : BaseCollectionViewController
- (instancetype)initWithHandlersFactory:(id<HandlersFactory>)handlersFactory
                            nodeFactory:(id<NodeFactory>)nodeFactory
                         dialogsService:(id<DialogsService>)dialogsService;
@end
