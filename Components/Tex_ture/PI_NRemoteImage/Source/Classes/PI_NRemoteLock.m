//
//  PI_NRemoteLock.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "PI_NRemoteLock.h"

#import <pthread.h>

#if !defined(PI_NREMOTELOCK_DEBUG) && defined(DEBUG)
#define PI_NREMOTELOCK_DEBUG DEBUG
#endif

@interface PI_NRemoteLock ()
{
#if PI_NREMOTELOCK_DEBUG
    NSLock *_lock;
    NSRecursiveLock *_recursiveLock;
#else
    pthread_mutex_t _lock;
#endif
}

@end

@implementation PI_NRemoteLock

- (instancetype)init
{
    return [self initWithName:nil];
}

- (instancetype)initWithName:(NSString *)lockName lockType:(PI_NRemoteLockType)lockType
{
    if (self = [super init]) {
#if PI_NREMOTELOCK_DEBUG
        if (lockType == PI_NRemoteLockTypeNonRecursive) {
            _lock = [[NSLock alloc] init];
        } else {
            _recursiveLock = [[NSRecursiveLock alloc] init];
        }
        
        if (lockName) {
            [_lock setName:lockName];
            [_recursiveLock setName:lockName];
        }
#else
        pthread_mutexattr_t attr;
        
        pthread_mutexattr_init(&attr);
        if (lockType == PI_NRemoteLockTypeRecursive) {
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        }
        pthread_mutex_init(&_lock, &attr);
#endif
    }
    return self;
}

- (instancetype)initWithName:(NSString *)lockName
{
    return [self initWithName:lockName lockType:PI_NRemoteLockTypeNonRecursive];
}

#if ! PI_NREMOTELOCK_DEBUG
- (void)dealloc
{
    pthread_mutex_destroy(&_lock);
}
#endif

- (void)lockWithBlock:(dispatch_block_t)block
{
#if PI_NREMOTELOCK_DEBUG
    [_lock lock];
    [_recursiveLock lock];
#else
    pthread_mutex_lock(&_lock);
#endif
    block();
#if PI_NREMOTELOCK_DEBUG
    [_lock unlock];
    [_recursiveLock unlock];
#else
    pthread_mutex_unlock(&_lock);
#endif
}

- (void)lock
{
#if PI_NREMOTELOCK_DEBUG
    [_lock lock];
    [_recursiveLock lock];
#else
    pthread_mutex_lock(&_lock);
#endif
}

- (void)unlock
{
#if PI_NREMOTELOCK_DEBUG
    [_lock unlock];
    [_recursiveLock unlock];
#else
    pthread_mutex_unlock(&_lock);
#endif
}

@end
