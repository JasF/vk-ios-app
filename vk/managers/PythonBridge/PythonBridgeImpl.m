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
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <GCDWebServer/GCDWebServerDataRequest.h>

@import GCDWebServer;

NSString * const PXProtocolMethodListMethodNameKey = @"methodName";
NSString * const PXProtocolMethodListArgumentTypesKey = @"types";

@interface PythonBridgeImpl ()
@property (strong, nonatomic) NSMutableDictionary *handlers;
@property (strong, nonatomic) dispatch_queue_t queue;
@property (strong, nonatomic) GCDWebServer *webServer;
@property (strong, nonatomic) NSMutableArray *sendArray;
@end

@implementation PythonBridgeImpl {
    ResultBlock _resultBlock;
    BOOL _sessionStartedSended;
    dispatch_group_t _group;
    BOOL _groupWaiting;
}

+ (instancetype)shared {
    static PythonBridgeImpl *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [PythonBridgeImpl new];
    });
    return shared;
}

- (id)init {
    if (self = [super init]) {
        _handlers = [NSMutableDictionary new];
        _queue = dispatch_queue_create("python.bridge.queue.serial", DISPATCH_QUEUE_SERIAL);
        _sendArray = [NSMutableArray new];
        _group = dispatch_group_create();
    }
    return self;
}

- (void)send:(NSDictionary *)object {
    @synchronized (self) {
        [_sendArray addObject:object];
        if (_groupWaiting) {
            _groupWaiting = NO;
            dispatch_group_leave(_group);
        }
    }
}

- (void)connect {
    _webServer = [[GCDWebServer alloc] init];
    [_webServer addDefaultHandlerForMethod:@"GET"
                              requestClass:[GCDWebServerRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                  NSDictionary *dictionary = @{};
                                  if ([request.path isEqualToString:@"/grep"]) {
                                      dictionary = [self handleGrepRequest:request];
                                  }
                                  NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
                                  return [GCDWebServerDataResponse responseWithData:data contentType:@"application/json"];
                              }];
    
    @weakify(self);
    [_webServer addDefaultHandlerForMethod:@"POST"
                              requestClass:[GCDWebServerDataRequest class]
                              processBlock:^GCDWebServerResponse *(GCDWebServerDataRequest* request) {
                                  @strongify(self);
                                  if ([request.path isEqualToString:@"/post"]) {
                                      [self handleIncomingPostData:request.data];
                                  }
                                  return nil;
                              }];
    [_webServer startWithPort:8765 bonjourName:nil];
}

- (NSDictionary *)handleGrepRequest:(GCDWebServerRequest *)request {
    if (!_sessionStartedSended) {
        _sessionStartedSended = YES;
        return @{@"command":@"startSession"};
    }
    
    while (YES) {
        @synchronized (self) {
            if (_sendArray.count) {
                NSDictionary *object = _sendArray.firstObject;
                [_sendArray removeObjectAtIndex:0];
                return object;
            }
            _groupWaiting = YES;
        }
        dispatch_group_enter(_group);
        dispatch_group_wait(_group, DISPATCH_TIME_FOREVER);
    }
}

- (id)handlerWithActions:(NSDictionary *)actions
                    name:(NSString *)name {
    NSCParameterAssert(actions.count);
    return [[PythonBridgeHandler alloc] initWithPythonBridge:self
                                                        name:name
                                                     actions:actions];
}

- (void)sendAction:(NSString *)action
         className:(NSString *)className
         arguments:(NSArray *)arguments
        withResult:(BOOL)withResult
       resultBlock:(ResultBlock)resultBlock {
    NSCParameterAssert(action);
    NSCParameterAssert(className);
    if (!action || !className) {
        return;
    }
    if (resultBlock) {
        _resultBlock = resultBlock;
    }
    [self send:@{@"command":@"classAction", @"action":action, @"class":className, @"args":(arguments) ?: @[], @"withResult":@(withResult)}];
}

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

- (id)handlerWithProtocol:(Protocol *)protocol {
    const char *name = protocol_getName(protocol);
    NSCParameterAssert(protocol);
    NSArray *methods = px_allProtocolMethods(protocol);
    NSMutableDictionary *actions = [NSMutableDictionary new];
    for (NSDictionary *dictionary in methods) {
        [actions setObject:dictionary[PXProtocolMethodListArgumentTypesKey]
                    forKey:dictionary[PXProtocolMethodListMethodNameKey]];
    }
    return [self handlerWithActions:[actions copy] name:NSStringFromProtocol(protocol)];
}

- (void)handleIncomingPostData:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        message = [message dataUsingEncoding:NSUTF8StringEncoding];
    }
    NSDictionary *object = [NSJSONSerialization JSONObjectWithData:message options:0 error:nil];
    //NSLog(@"handleIncomingPostData: %@", object);
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
            [self performAction:object[@"action"] className:object[@"class"] args:args];
        }
        else if ([command isEqualToString:@"response"]) {
            id result = object[@"result"];
            if ([result isKindOfClass:[NSNull class]]) {
                result = nil;
            }
            NSCAssert(_resultBlock, @"received response but callback not achived!");
            if (_resultBlock) {
                ResultBlock block = _resultBlock;
                _resultBlock = nil;
                block(result);
            }
        }
        else {
            NSLog(@"unknown command. data: %@", object);
        }
    }
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

- (void)performAction:(NSString *)action
            className:(NSString *)className
                 args:(NSArray *)args {
    NSCParameterAssert(action);
    NSCParameterAssert(className);
    if (!action || !className) {
        return;
    }
    id handler = _handlers[className];
    if (!handler) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performAction:action className:className args:args];
        });
        return;
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
    
    if (hasReturnValue) {
        [self send:@{@"command":@"response", @"class":className, @"action":action, @"result":returnValue}];
    }
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

- (void)setClassHandler:(id)handler
                   name:(NSString *)className {
    NSCParameterAssert(className);
    NSCParameterAssert(handler);
    [_handlers setObject:handler forKey:className];
}

@end
