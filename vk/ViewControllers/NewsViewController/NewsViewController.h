//
//  NewsViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "BaseCollectionViewController.h"
#import "PythonBridge.h"
#import "WallService.h"

@protocol NewsHandlerProtocol <NSObject>
- (void)menuTapped;
@end

@interface NewsViewController : BaseCollectionViewController
- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory
                         wallService:(id<WallService>)wallService;
@end
