//
//  PythonManagerImpl.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PythonManager.h"

@interface PythonManagerImpl : NSObject <PythonManager>
- (id)initWithExtensions:(NSArray<id<PythonManagerExtension>> *)extensions;
@end
