//
//  PythonBridge.h
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

typedef void (^ResultBlock)(id result);
@protocol PythonBridge <NSObject>
- (void)send:(NSDictionary *)object;
- (void)connect;
- (void)setClassHandler:(id)handler name:(NSString *)className;
- (id)handlerWithProtocol:(Protocol *)protocol;
- (void)sendAction:(NSString *)action
         className:(NSString *)className
         arguments:(NSArray *)arguments
        withResult:(BOOL)withResult
       resultBlock:(ResultBlock)resultBlock;

@end
