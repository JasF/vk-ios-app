//
//  NewsViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "PythonBridge.h"
#import "NodeFactory.h"

@protocol NewsHandlerProtocol <NSObject>
- (void)menuTapped;
- (NSDictionary *)getWall:(NSNumber *)offset;
@end

@interface NewsViewController : ASViewController
- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory;
@end
