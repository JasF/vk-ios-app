//
//  PI_NOperationGroup.h
//  PI_NQueue
//
//  Created by Garrett Moon on 10/8/16.
//  Copyright © 2016 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PI_NOperationTypes.h"
#import "PI_NOperationMacros.h"

@class PI_NOperationQueue;

NS_ASSUME_NONNULL_BEGIN

@protocol PI_NGroupOperationReference;

PI_NOP_SUBCLASSING_RESTRICTED
@interface PI_NOperationGroup : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)asyncOperationGroupWithQueue:(PI_NOperationQueue *)operationQueue;

- (nullable id <PI_NGroupOperationReference>)addOperation:(dispatch_block_t)operation;
- (nullable id <PI_NGroupOperationReference>)addOperation:(dispatch_block_t)operation withPriority:(PI_NOperationQueuePriority)priority;
- (void)start;
- (void)cancel;
- (void)setCompletion:(dispatch_block_t)completion;
- (void)waitUntilComplete;

@end

@protocol PI_NGroupOperationReference <NSObject>

@end

NS_ASSUME_NONNULL_END
