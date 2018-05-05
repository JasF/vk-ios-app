//
//  RunLoop.m
//  Electrum
//
//  Created by Jasf on 20.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "RunLoop.h"

@implementation RunLoop {
    NSMutableDictionary *_groups;
    NSInteger _groupIndex;
}

#pragma mark - Public Static Methods
+ (instancetype)shared {
    static RunLoop *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [RunLoop new];
    });
    return shared;
}

#pragma mark - Initialization
- (id)init {
    if (self = [super init]) {
        _groups = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Public Methods
- (void)exec:(NSInteger)requestId {
    [self waitForGroup:[self enter:requestId]];
}

- (dispatch_group_t)enter:(NSInteger)requestId {
    dispatch_group_t group = dispatch_group_create();
    @synchronized(self) {
        [_groups setObject:[NSValue valueWithNonretainedObject:group] forKey:@(requestId)];
    }
    dispatch_group_enter(group);
    return group;
}

- (void)waitForGroup:(dispatch_group_t)group {
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)exit:(NSInteger)requestId {
    NSValue *value = nil;
    @synchronized(self) {
        value = _groups[@(requestId)];
        NSCAssert(value, @"value must be exists");
        [_groups removeObjectForKey:@(requestId)];
    }
    dispatch_group_t group = (dispatch_group_t)value.nonretainedObjectValue;
    if (group) {
        dispatch_group_leave(group);
    }
}

@end
