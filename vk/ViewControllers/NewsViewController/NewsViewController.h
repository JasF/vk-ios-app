//
//  NewsViewController.h
//  vk
//
//  Created by Jasf on 11.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "PythonBridge.h"

@protocol NewsHandlerProtocol <NSObject>
- (void)menuTapped;
- (NSDictionary *)getWall;
@end

@interface NewsViewController : ASViewController
@property (strong, nonatomic) id<PythonBridge> pythonBridge;
@end
