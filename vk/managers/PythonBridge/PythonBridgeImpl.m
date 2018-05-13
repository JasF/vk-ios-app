//
//  PythonBridgeImpl.m
//  Rubricon
//
//  Created by Jasf on 30.03.2018.
//  Copyright © 2018 Home. All rights reserved.
//

#import "PythonBridgeImpl.h"
#import "PythonBridgeHandler.h"
#import <objc/runtime.h>
#import "Oxy_Feed-Swift.h"
#import "DeallocSubscriber.h"

NSString * const PXProtocolMethodListMethodNameKey = @"methodName";
NSString * const PXProtocolMethodListArgumentTypesKey = @"types";

@interface PythonBridgeImpl () <PythonBridge>
@property (strong, nonatomic) NSMutableDictionary *handlers;
@property (strong, nonatomic) NSMutableDictionary *resultBlocks;
@property (strong, nonatomic) id<Modules> modules;
@end

@implementation PythonBridgeImpl {
    BOOL _sessionStartedSended;
    NSInteger _currentRequestId;
    NSInteger _instanceId;
    BOOL _initialized;
}

@synthesize bridgeExtension = _bridgeExtension;

+ (instancetype)shared {
    static PythonBridgeImpl *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [PythonBridgeImpl new];
    });
    return shared;
}

- (id)initWithExtension:(id<PythonBridgeExtension>)extension
                modules:(id<Modules>)modules {
    NSCParameterAssert(extension);
    NSCParameterAssert(modules);
    if (self = [super init]) {
        [extension setPythonBridge:self];
        _bridgeExtension = extension;
        _resultBlocks = [NSMutableDictionary new];
        _handlers = [NSMutableDictionary new];
        _modules = modules;
    }
    return self;
}

- (void)send:(NSDictionary *)object {
    NSCParameterAssert(_bridgeExtension);
    [_bridgeExtension sendToPython:object];
}

- (id)handlerWithActions:(NSDictionary *)actions
                    name:(NSString *)name {
    NSCParameterAssert(actions.count);
    return [[PythonBridgeHandler alloc] initWithPythonBridge:self
                                                        name:name
                                                     actions:actions];
}

- (NSInteger)sendAction:(NSString *)action
              className:(NSString *)className
              arguments:(NSArray *)arguments
             withResult:(BOOL)withResult
            resultBlock:(ResultBlock)resultBlock {
    NSInteger requestId = 0;
    dispatch_block_t block = [self sendAction:action
                                    className:className
                                    arguments:(NSArray *)arguments
                                   withResult:withResult resultBlock:resultBlock
                                    requestId:&requestId];
    if (block) {
        block();
    }
    return requestId;
}

- (dispatch_block_t)sendAction:(NSString *)action
                     className:(NSString *)className
                     arguments:(NSArray *)arguments
                    withResult:(BOOL)withResult
                   resultBlock:(ResultBlock)resultBlock
                     requestId:(NSInteger *)storageId {
    NSCParameterAssert(action);
    NSCParameterAssert(className);
    NSInteger result = 0;
    if (!action || !className) {
        if (storageId) {
            *storageId = result;
        }
        return ^{};
    }
    @synchronized(self) {
        if (resultBlock) {
            _currentRequestId++;
            result = _currentRequestId;
            [_resultBlocks setObject:resultBlock forKey:@(result)];
        }
        NSDictionary *dictionary = @{
                                     @"command":@"classAction",
                                     @"action":action,
                                     @"class":className,
                                     @"args":(arguments) ?: @[],
                                     @"withResult":@(withResult),
                                     @"requestId":@(result)
                                    };
        if (storageId) {
            *storageId = result;
        }
        @weakify(self);
        return [^{
            @strongify(self);
            [self send:dictionary];
        } copy];
    }
    return ^{};
}

NSArray *px_allProtocolMethods(Protocol *protocol);
NSArray *px_allProtocolMethods(Protocol *protocol)
{
    NSMutableArray *methodList = [[NSMutableArray alloc] init];
    
    // We have 4 permutations as protocol_copyMethodDescriptionList() takes two BOOL arguments for the types of methods to return.
    for (NSUInteger i = 0; i < 4; ++i) {
        unsigned int numberOfMethodDescriptions = 0;
        struct objc_method_description *methodDescriptions = protocol_copyMethodDescriptionList(protocol, (i / 2) % 2, i % 2, &numberOfMethodDescriptions);
        
        for (unsigned int j = 0; j < numberOfMethodDescriptions; ++j) {
            struct objc_method_description methodDescription = methodDescriptions[j];
            [methodList addObject:@{PXProtocolMethodListMethodNameKey: NSStringFromSelector(methodDescription.name),
                                    PXProtocolMethodListArgumentTypesKey: [NSString stringWithUTF8String:methodDescription.types]}];
        }
        
        free(methodDescriptions);
    }
    
    return methodList;
}

- (NSString *)nameByProtocol:(Protocol *)protocol {
    NSString *protocolName = NSStringFromProtocol(protocol);
    NSArray *components = [protocolName componentsSeparatedByString:@"."];
    if (components.count == 2) {
        protocolName = components[1];
    }
    return protocolName;
}

- (id)handlerWithProtocol:(Protocol *)protocol {
    NSCParameterAssert(protocol);
    NSString *protocolName = [self nameByProtocol:protocol];
    NSArray *methods = px_allProtocolMethods(protocol);
    NSMutableDictionary *actions = [NSMutableDictionary new];
    for (NSDictionary *dictionary in methods) {
        [actions setObject:dictionary[PXProtocolMethodListArgumentTypesKey]
                    forKey:dictionary[PXProtocolMethodListMethodNameKey]];
    }
    return [self handlerWithActions:[actions copy] name:protocolName];
}

- (id)instantiateHandlerWithProtocol:(Protocol *)protocol {
    NSString *protocolName = [self nameByProtocol:protocol];
    PythonBridgeHandler *handler = [self handlerWithProtocol:protocol];
    @synchronized (self) {
        handler.instanceId = ++_instanceId;
        handler.key = [NSString stringWithFormat:@"%@_%@", protocolName, @(handler.instanceId)];
    }
    NSDictionary *dictionary = @{
                                 @"command":@"instantiateHandler",
                                 @"key":handler.key,
                                 @"class":protocolName,
                                 };
    [self send:dictionary];
    return handler;
}

- (id)instantiateHandlerWithProtocol:(Protocol *)protocol delegate:(id)delegate {
    return [self instantiateHandlerWithProtocol:protocol
                                       delegate:delegate
                                     parameters:nil];
}

- (id)instantiateHandlerWithProtocol:(Protocol *)protocol
                          parameters:(NSDictionary *)parameters {
    return [self instantiateHandlerWithProtocol:protocol
                                       delegate:nil
                                     parameters:parameters];
}

- (id)instantiateHandlerWithProtocol:(Protocol *)protocol
                            delegate:(id)delegate
                          parameters:(NSDictionary *)parameters {
    NSString *protocolName = [self nameByProtocol:protocol];
    PythonBridgeHandler *handler = [self handlerWithProtocol:protocol];
    @synchronized (self) {
        handler.instanceId = ++_instanceId;
    }
    handler.key = [NSString stringWithFormat:@"%@_%@", protocolName, @(handler.instanceId)];
    if (delegate) {
        [self setClassHandler:delegate name:[NSString stringWithFormat:@"%@Delegate_%@", protocolName, @(handler.instanceId)]];
    }
    NSMutableDictionary *dictionary = [@{
                                 @"command":(delegate) ? @"instantiateHandlerWithDelegate" : @"instantiateHandler",
                                 @"key":handler.key,
                                 @"class":protocolName,
                                 } mutableCopy];
    if (delegate) {
        [dictionary setObject:@(handler.instanceId) forKey:@"delegateId"];
    }
    if (parameters) {
        [dictionary setObject:parameters forKey:@"parameters"];
    }
    [self send:dictionary];
    return handler;
}

- (void)handleIncomingPostData:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        message = [message dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSDictionary *object = [NSJSONSerialization JSONObjectWithData:message options:0 error:nil];
    [self incomingDictionary:object];
}

- (NSDictionary *)incomingDictionary:(NSDictionary *)object {
    if (!_initialized) {
        _initialized = YES;
        [_modules performInitializationOfSubmodulesAfterPythonLoaded];
    }
    NSString *value = [self loggingStringWithDictionary:object];
    if (value) {
        NSLog(@"%@", value);
    }
    else {
        NSString *command = object[@"command"];
        if ([command isEqualToString:@"classAction"]) {
            NSArray *args = object[@"args"];
            if (![args isKindOfClass:[NSArray class]]) {
                args = @[];
            }
            NSDictionary *resultValue = [self performAction:object[@"action"]
                                                  className:object[@"class"]
                                                       args:args
                                                 delegateId:object[@"delegateId"]];
            return resultValue;
        }
        else if ([command isEqualToString:@"response"]) {
            id result = object[@"result"];
            if ([result isKindOfClass:[NSNull class]]) {
                result = nil;
            }
            NSInteger requestId = [object[@"request"][@"requestId"] integerValue];
            ResultBlock resultBlock = _resultBlocks[@(requestId)];
            NSCAssert(resultBlock, @"received response but callback not achived!");
            if (resultBlock) {
                [_resultBlocks removeObjectForKey:@(requestId)];
                resultBlock(result, requestId);
            }
        }
        else {
            NSLog(@"unknown command. data: %@", object);
        }
    }
    return @{};
}

- (void)handlerWillRelease:(PythonBridgeHandler *)handler {
    if (!handler.key) {
        return;
    }
    NSDictionary *dictionary = @{
                                 @"command":@"releaseHandler",
                                 @"key":handler.key
                                 };
    dispatch_python(^{
        [self send:dictionary];
    });
    /*
    NSArray *keys = [_handlers allKeysForObject:[NSValue valueWithNonretainedObject:handler]];
    for (NSString *key in keys) {
        [_handlers removeObjectForKey:key];
    }
     */
}

#pragma mark - Private
- (NSString *)loggingStringWithDictionary:(NSDictionary *)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSString *command = object[@"command"];
        if ([command isEqualToString:@"logging"]) {
            NSData *data = [[NSData alloc] initWithBase64EncodedString:(NSString *)object[@"value"] options:0];
            NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            return string;
        }
    }
    return nil;
}

- (NSDictionary *)performAction:(NSString *)action
                      className:(NSString *)className
                           args:(NSArray *)args
                     delegateId:(NSNumber *)delegateId {
    NSCParameterAssert(action);
    NSCParameterAssert(className);
    if (!action || !className) {
        return @{};
    }
    if (delegateId) {
        className = [className stringByAppendingFormat:@"_%@", delegateId];
    }
    id handler = [_handlers[className] nonretainedObjectValue];
    if (!handler) {
        NSLog(@"handler for protocol \"%@\" not registered", className);
        return @{};
    }
    SEL selector = NSSelectorFromString(action);
    
    Method m = class_getInstanceMethod([handler class], selector);
    char type[6];
    method_getReturnType(m, type, sizeof(type));
    NSString *returnTypeString = [NSString stringWithCString:type encoding:NSUTF8StringEncoding];
    BOOL hasReturnValue = [returnTypeString isEqualToString:@"@"];
    
    id returnValue = nil;
    if (!args.count) {
        returnValue = [self performSelector:selector onHandler:handler hasReturnValue:hasReturnValue];
    }
    else if (args.count == 1) {
        returnValue = [self performSelector:selector onHandler:handler hasReturnValue:hasReturnValue arg1:args[0]];
    }
    else if (args.count == 2) {
        returnValue = [self performSelector:selector onHandler:handler hasReturnValue:hasReturnValue arg1:args[0] arg2:args[1]];
    }
    else if (args.count == 3) {
        returnValue = [self performSelector:selector onHandler:handler hasReturnValue:hasReturnValue arg1:args[0] arg2:args[1] arg3:args[2]];
    }
    else if (args.count == 4) {
        returnValue = [self performSelector:selector onHandler:handler hasReturnValue:hasReturnValue arg1:args[0] arg2:args[1] arg3:args[2] arg4:args[3]];
    }
    else if (args.count == 5) {
        returnValue = [self performSelector:selector
                                  onHandler:handler
                             hasReturnValue:hasReturnValue
                                       arg1:args[0] arg2:args[1] arg3:args[2] arg4:args[3] arg5:args[4]];
    }
    else {
        NSCAssert(false, @"Unimplemented python -> objc bridge call");
    }
    
    if (hasReturnValue) {
        NSDictionary *result = @{@"command":@"response", @"class":className, @"action":action, @"result":returnValue};
        [self send:result];
        return result;
    }
    return @{};
}

- (id)performSelector:(SEL)selector onHandler:(id)handler hasReturnValue:(BOOL)hasReturnValue {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL) = (void *)imp;
        return func(handler, selector);
    }
    void (*func)(id, SEL) = (void *)imp;
    func(handler, selector);
    return nil;
}

- (id)performSelector:(SEL)selector onHandler:(id)handler hasReturnValue:(BOOL)hasReturnValue arg1:(id)arg1 {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL, id) = (void *)imp;
        return func(handler, selector, arg1);
    }
    void (*func)(id, SEL, id) = (void *)imp;
    func(handler, selector, arg1);
    return nil;
}

- (id)performSelector:(SEL)selector onHandler:(id)handler hasReturnValue:(BOOL)hasReturnValue arg1:(id)arg1 arg2:(id)arg2 {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL, id, id) = (void *)imp;
        return func(handler, selector, arg1, arg2);
    }
    void (*func)(id, SEL, id, id) = (void *)imp;
    func(handler, selector, arg1, arg2);
    return nil;
}
    
- (id)performSelector:(SEL)selector
            onHandler:(id)handler
       hasReturnValue:(BOOL)hasReturnValue
                 arg1:(id)arg1 arg2:(id)arg2 arg3:(id)arg3 {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL, id, id, id) = (void *)imp;
        return func(handler, selector, arg1, arg2, arg3);
    }
    void (*func)(id, SEL, id, id, id) = (void *)imp;
    func(handler, selector, arg1, arg2, arg3);
    return nil;
}

- (id)performSelector:(SEL)selector
            onHandler:(id)handler
       hasReturnValue:(BOOL)hasReturnValue
                 arg1:(id)arg1 arg2:(id)arg2 arg3:(id)arg3 arg4:(id)arg4 {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL, id, id, id, id) = (void *)imp;
        return func(handler, selector, arg1, arg2, arg3, arg4);
    }
    void (*func)(id, SEL, id, id, id, id) = (void *)imp;
    func(handler, selector, arg1, arg2, arg3, arg4);
    return nil;
}

- (id)performSelector:(SEL)selector
            onHandler:(id)handler
       hasReturnValue:(BOOL)hasReturnValue
                 arg1:(id)arg1 arg2:(id)arg2 arg3:(id)arg3 arg4:(id)arg4 arg5:(id)arg5 {
    NSCParameterAssert(handler);
    if (!handler) {
        return nil;
    }
    IMP imp = [handler methodForSelector:selector];
    if (hasReturnValue) {
        id (*func)(id, SEL, id, id, id, id, id) = (void *)imp;
        return func(handler, selector, arg1, arg2, arg3, arg4, arg5);
    }
    void (*func)(id, SEL, id, id, id, id, id) = (void *)imp;
    func(handler, selector, arg1, arg2, arg3, arg4, arg5);
    return nil;
}

- (void)setClassHandler:(id)handler
                   name:(NSString *)className {
    NSCParameterAssert(className);
    NSCParameterAssert(handler);
    NSValue *value = [NSValue valueWithNonretainedObject:handler];
    @synchronized(self) {
        [_handlers setObject:value forKey:className];
    }
    @weakify(self);
    [DeallocSubscriber subscribe:handler releasingBlock:^{
        @strongify(self);
        @synchronized(self) {
            NSArray *keys = [self.handlers allKeysForObject:value];
            for (NSString *key in keys) {
                [self.handlers removeObjectForKey:key];
            }
        }
    }];
}

@end
