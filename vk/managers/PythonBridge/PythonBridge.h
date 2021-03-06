//
//  PythonBridge.h
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PythonBridgeExtension.h"
@class PythonBridgeHandler;
typedef void (^ResultBlock)(id result, NSInteger requestId);
@protocol PythonBridge <NSObject>
@property (weak) <PythonBridgeExtension> bridgeExtension;
- (void)send:(NSDictionary *)object;
- (void)setClassHandler:(id)handler name:(NSString *)className;
- (id)handlerWithProtocol:(Protocol *)protocol;
- (id)instantiateHandlerWithProtocol:(Protocol *)protocol;
- (id)instantiateHandlerWithProtocol:(Protocol *)protocol
                            delegate:(id)delegate;
- (id)instantiateHandlerWithProtocol:(Protocol *)protocol
                            delegate:(id)delegate
                          parameters:(NSDictionary *)parameters;
- (id)instantiateHandlerWithProtocol:(Protocol *)protocol
                          parameters:(NSDictionary *)parameters;
- (NSInteger)sendAction:(NSString *)action
              className:(NSString *)className
              arguments:(NSArray *)arguments
             withResult:(BOOL)withResult
            resultBlock:(ResultBlock)resultBlock;


- (dispatch_block_t)sendAction:(NSString *)action
                     className:(NSString *)className
                     arguments:(NSArray *)arguments
                    withResult:(BOOL)withResult
                   resultBlock:(ResultBlock)resultBlock
                     requestId:(NSInteger *)requestId;

- (void)handlerWillRelease:(PythonBridgeHandler *)handler;
- (NSDictionary *)incomingDictionary:(NSDictionary *)dictionary;
@end
