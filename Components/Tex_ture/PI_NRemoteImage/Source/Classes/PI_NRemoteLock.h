//
//  PI_NRemoteLock.h
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import <Foundation/Foundation.h>

/** The type of lock, either recursive or non-recursive */
typedef NS_ENUM(NSUInteger, PI_NRemoteLockType) {
    /** A non-recursive version of the lock. The default. */
    PI_NRemoteLockTypeNonRecursive = 0,
    /** A recursive version of the lock. More expensive. */
    PI_NRemoteLockTypeRecursive,
};

@interface PI_NRemoteLock : NSObject

- (instancetype)initWithName:(NSString *)lockName lockType:(PI_NRemoteLockType)lockType NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithName:(NSString *)lockName;
- (void)lockWithBlock:(dispatch_block_t)block;

- (void)lock;
- (void)unlock;

@end
