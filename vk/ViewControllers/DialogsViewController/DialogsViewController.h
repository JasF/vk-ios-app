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

@protocol DialogsHandlerProtocol <NSObject>
- (NSDictionary *)getDialogs:(NSNumber *)offset;
- (void)menuTapped;
@end

@interface DialogsViewController : ASViewController
- (instancetype)initWithPythonBridge:(id<PythonBridge>)pythonBridge
                         nodeFactory:(id<NodeFactory>)nodeFactory;
@end
