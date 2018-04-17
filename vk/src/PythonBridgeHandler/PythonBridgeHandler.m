//
//  PythonBridgeHandler.m
//  Electrum
//
//  Created by Jasf on 01.04.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "PythonBridgeHandler.h"
#import "PythonBridge.h"
#import "RunLoop.h"

@interface PythonBridgeHandler ()
@property (strong, nonatomic) RunLoop *runLoop;
@property (strong, nonatomic) id resultValue;
@end

@implementation PythonBridgeHandler {
    id<PythonBridge> _bridge;
    NSString *_name;
    NSDictionary *_actions;
    NSMethodSignature *_invokingMethodSignature;
}

- (id)initWithPythonBridge:(id<PythonBridge>)bridge
                      name:(NSString *)name
                   actions:(NSDictionary *)actions {
    NSCParameterAssert(bridge);
    NSCParameterAssert(name);
    NSCParameterAssert(actions);
    _bridge = bridge;
    _name = name;
    _actions = actions;
    _runLoop = [RunLoop shared];
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    NSString *selectorName = NSStringFromSelector(aSelector);
    if (![_actions.allKeys containsObject:selectorName]) {
        return NO;
    }
    return YES;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    NSString *signature = _actions[NSStringFromSelector(sel)];
    NSCParameterAssert(signature); // AV: If raise, check arguments on sel
    if (!signature) {
        return nil;
    }
    return [NSMethodSignature signatureWithObjCTypes:[signature cStringUsingEncoding:NSUTF8StringEncoding]];
}

- (id)methodWithResult {
    return self.resultValue;
}
- (void)voidMethod {
}
- (void)voidMethodWithOneArgument:(id)argument {
}
- (void)voidMethodWithTwoArgument:(id)argument arg2:(id)arg2 {
}
- (id)methodWithResultAndOneArgument:(id)argument {
    return self.resultValue;
}
- (id)methodWithResultAndTwoArgument:(id)argument arg:(id)arg2 {
    return self.resultValue;
}
- (id)methodWithResultAndThreeArgument:(id)argument arg2:(id)arg2 arg3:(id)arg3 {
    return self.resultValue;
}

-(void)forwardInvocation:(NSInvocation*)anInvocation
{
    NSString *selectorName = NSStringFromSelector(anInvocation.selector);
    NSString *returnValueSignature = [[NSString alloc] initWithCString:anInvocation.methodSignature.methodReturnType encoding:NSUTF8StringEncoding];
    ResultBlock resultBlock = nil;
    BOOL withResultValue = [returnValueSignature isEqualToString:@"@"];
    NSMutableArray *arguments = [NSMutableArray new];
    NSInteger argumentsCount = anInvocation.methodSignature.numberOfArguments;
    NSInteger defaultArgumentsCount = 2;
    for (NSInteger i=defaultArgumentsCount;i<argumentsCount;++i) {
        id __unsafe_unretained argument = nil;
        [anInvocation getArgument:&argument atIndex:i];
        if (argument) {
            [arguments addObject:[argument copy]];
        }
    }
    if (withResultValue) {
        @weakify(self);
        resultBlock = ^(id result) {
            @strongify(self);
            self.resultValue = result;
            [self.runLoop exit:0];
        };
    }
    [_bridge sendAction:selectorName
              className:_name
              arguments:[arguments copy]
             withResult:withResultValue
            resultBlock:resultBlock];
    if (!withResultValue && arguments.count == 1) {
        anInvocation.selector = @selector(voidMethodWithOneArgument:);
    }
    else if (!withResultValue && arguments.count == 2) {
        anInvocation.selector = @selector(voidMethodWithTwoArgument:arg2:);
    }
    else if (withResultValue && arguments.count == 1) {
        anInvocation.selector = @selector(methodWithResultAndOneArgument:);
    }
    else if (withResultValue && arguments.count == 2) {
        anInvocation.selector = @selector(methodWithResultAndTwoArgument:arg:);
    }
    else if (withResultValue && arguments.count == 3) {
        anInvocation.selector = @selector(methodWithResultAndThreeArgument:arg2:arg3:);
    }
    else if (withResultValue) {
        NSCParameterAssert(!arguments.count);
        anInvocation.selector = @selector(methodWithResult);
    }
    else {
        NSCParameterAssert(!arguments.count);
        anInvocation.selector = @selector(voidMethod);
    }
    if (withResultValue) {
        [_runLoop exec];
    }
    anInvocation.target = self;
    [anInvocation invoke];
}

@end
