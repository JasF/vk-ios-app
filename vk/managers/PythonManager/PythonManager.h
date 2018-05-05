//
//  PythonManager.h
//  vk
//
//  Created by Jasf on 13.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>

@protocol PythonManagerExtension <NSObject>
- (void)initializeSystem;
- (void)initializeUser;
@end

@protocol PythonManager <NSObject>
- (void)startupPython;
@end
