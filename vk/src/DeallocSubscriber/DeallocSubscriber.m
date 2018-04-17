//
//  DeallocSubscriber.m
//  vk
//
//  Created by Jasf on 17.04.2018.
//  Copyright © 2018 Ebay Inc. All rights reserved.
//

#import "DeallocSubscriber.h"
#import <objc/runtime.h>

@interface DeallocSubscriber ()
@property (copy) dispatch_block_t releasingBlock;
@end

static const char *key;

@implementation DeallocSubscriber

+ (void)subscribe:(id)object releasingBlock:(dispatch_block_t)block {
    DeallocSubscriber *subscriber = [DeallocSubscriber new];
    subscriber.releasingBlock = block;
    objc_setAssociatedObject(object, &key, subscriber, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc {
    if (_releasingBlock) {
        _releasingBlock();
    }
}

@end
