//
//  HandlersFactoryImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "HandlersFactory.h"
#import "PythonBridge.h"

@interface HandlersFactoryImpl : NSObject <HandlersFactory>
- (id)initWithPythonBridge:(id<PythonBridge>)pythonBridge;
@end
