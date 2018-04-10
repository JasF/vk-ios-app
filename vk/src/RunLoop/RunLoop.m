//
//  RunLoop.m
//  Electrum
//
//  Created by Jasf on 20.03.2018.
//  Copyright © 2018 Freedom. All rights reserved.
//

#import "RunLoop.h"

@implementation RunLoop {
    NSMutableArray *_groups;
    NSMutableArray *_resultCodes;
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
        _groups = [NSMutableArray new];
        _resultCodes = [NSMutableArray new];
    }
    return self;
}

#pragma mark - Public Methods
- (NSInteger)exec {
    _groupIndex++;
    dispatch_group_t group = dispatch_group_create();
    @synchronized(self) {
        [_groups addObject:[NSValue valueWithNonretainedObject:group]];
    }
    dispatch_group_enter(group);
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    __block NSNumber *resultCode = nil;
    @synchronized(self) {
        NSCAssert(_resultCodes.count, @"_resultCodes cannot be nil");
        resultCode = _resultCodes.firstObject;
        [_resultCodes removeObjectAtIndex:0];
    }
    return [resultCode integerValue];
}

- (void)exit:(NSInteger)resultCode {
    NSValue *value = nil;
    @synchronized(self) {
        NSCAssert(_groups.count, @"object in _groups must be exists");
        [_resultCodes addObject:@(resultCode)];
        value = _groups.lastObject;
        [_groups removeLastObject];
    }
    dispatch_group_t group = (dispatch_group_t)value.nonretainedObjectValue;
    dispatch_group_leave(group);
}

@end
