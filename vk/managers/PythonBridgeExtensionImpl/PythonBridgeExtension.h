//
//  PythonBridgeExtension.h
//  vk
//
//  Created by Jasf on 05.05.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

@protocol PythonBridgeExtension <NSObject>
- (void)sendToPython:(NSDictionary *)data;
- (void)setPythonBridge:(id)pythonBridge;
@end
