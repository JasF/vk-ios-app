//  PI_NCache is a modified version of TMCache
//  Modifications by Garrett Moon
//  Copyright (c) 2015 Pinterest. All rights reserved.

#import <Foundation/Foundation.h>

#import <PI_NCache/PI_NCacheMacros.h>
#import <PI_NCache/PI_NCaching.h>
#import <PI_NCache/PI_NCacheObjectSubscripting.h>

NS_ASSUME_NONNULL_BEGIN

@class PI_NMemoryCache;
@class PI_NOperationQueue;


/**
 `PI_NMemoryCache` is a fast, thread safe key/value store similar to `NSCache`. On iOS it will clear itself
 automatically to reduce memory usage when the app receives a memory warning or goes into the background.
 
 Access is natively synchronous. Asynchronous variations are provided. Every asynchronous method accepts a
 callback block that runs on a concurrent <concurrentQueue>, with cache reads and writes protected by a lock.
 
 All access to the cache is dated so the that the least-used objects can be trimmed first. Setting an
 optional <ageLimit> will trigger a GCD timer to periodically to trim the cache to that age.
 
 Objects can optionally be set with a "cost", which could be a byte count or any other meaningful integer.
 Setting a <costLimit> will automatically keep the cache below that value with <trimToCostByDate:>.
 
 Values will not persist after application relaunch or returning from the background. See <PI_NCache> for
 a memory cache backed by a disk cache.
 */

PI_N_SUBCLASSING_RESTRICTED
@interface PI_NMemoryCache : NSObject <PI_NCaching, PI_NCacheObjectSubscripting>

#pragma mark - Properties
/// @name Core

/**
 The total accumulated cost.
 */
@property (readonly) NSUInteger totalCost;

/**
 The maximum cost allowed to accumulate before objects begin to be removed with <trimToCostByDate:>.
 */
@property (assign) NSUInteger costLimit;

/**
 The maximum number of seconds an object is allowed to exist in the cache. Setting this to a value
 greater than `0.0` will start a recurring GCD timer with the same period that calls <trimToDate:>.
 Setting it back to `0.0` will stop the timer. Defaults to `0.0`.
 */
@property (assign) NSTimeInterval ageLimit;

/**
 If ttlCache is YES, the cache behaves like a ttlCache. This means that once an object enters the
 cache, it only lives as long as self.ageLimit. This has the following implications:
 - Accessing an object in the cache does not extend that object's lifetime in the cache
 - When attempting to access an object in the cache that has lived longer than self.ageLimit,
 the cache will behave as if the object does not exist
 
 */
@property (nonatomic, assign, getter=isTTLCache) BOOL ttlCache;

/**
 When `YES` on iOS the cache will remove all objects when the app receives a memory warning.
 Defaults to `YES`.
 */
@property (assign) BOOL removeAllObjectsOnMemoryWarning;

/**
 When `YES` on iOS the cache will remove all objects when the app enters the background.
 Defaults to `YES`.
 */
@property (assign) BOOL removeAllObjectsOnEnteringBackground;

#pragma mark - Event Blocks
/// @name Event Blocks

/**
 A block to be executed just before an object is added to the cache. This block will be excuted within
 a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheObjectBlock willAddObjectBlock;

/**
 A block to be executed just before an object is removed from the cache. This block will be excuted
 within a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheObjectBlock willRemoveObjectBlock;

/**
 A block to be executed just before all objects are removed from the cache as a result of <removeAllObjects:>.
 This block will be excuted within a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheBlock willRemoveAllObjectsBlock;

/**
 A block to be executed just after an object is added to the cache. This block will be excuted within
 a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheObjectBlock didAddObjectBlock;

/**
 A block to be executed just after an object is removed from the cache. This block will be excuted
 within a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheObjectBlock didRemoveObjectBlock;

/**
 A block to be executed just after all objects are removed from the cache as a result of <removeAllObjects:>.
 This block will be excuted within a lock, i.e. all reads and writes are suspended for the duration of the block.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 */
@property (nullable, copy) PI_NCacheBlock didRemoveAllObjectsBlock;

/**
 A block to be executed upon receiving a memory warning (iOS only) potentially in parallel with other blocks on the <queue>.
 This block will be executed regardless of the value of <removeAllObjectsOnMemoryWarning>. Defaults to `nil`.
 */
@property (nullable, copy) PI_NCacheBlock didReceiveMemoryWarningBlock;

/**
 A block to be executed when the app enters the background (iOS only) potentially in parallel with other blocks on the <concurrentQueue>.
 This block will be executed regardless of the value of <removeAllObjectsOnEnteringBackground>. Defaults to `nil`.
 */
@property (nullable, copy) PI_NCacheBlock didEnterBackgroundBlock;

#pragma mark - Lifecycle
/// @name Shared Cache

/**
 A shared cache.
 
 @result The shared singleton cache instance.
 */
@property (class, strong, readonly) PI_NMemoryCache *sharedCache;

- (instancetype)initWithOperationQueue:(PI_NOperationQueue *)operationQueue;

- (instancetype)initWithName:(NSString *)name operationQueue:(PI_NOperationQueue *)operationQueue NS_DESIGNATED_INITIALIZER;

#pragma mark - Asynchronous Methods
/// @name Asynchronous Methods

/**
 Removes objects from the cache, costliest objects first, until the <totalCost> is below the specified
 value. This method returns immediately and executes the passed block after the cache has been trimmed,
 potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param cost The total accumulation allowed to remain after the cache has been trimmed.
 @param block A block to be executed concurrently after the cache has been trimmed, or nil.
 */
- (void)trimToCostAsync:(NSUInteger)cost completion:(nullable PI_NCacheBlock)block;

/**
 Removes objects from the cache, ordered by date (least recently used first), until the <totalCost> is below
 the specified value. This method returns immediately and executes the passed block after the cache has been
 trimmed, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param cost The total accumulation allowed to remain after the cache has been trimmed.
 @param block A block to be executed concurrently after the cache has been trimmed, or nil.
 */
- (void)trimToCostByDateAsync:(NSUInteger)cost completion:(nullable PI_NCacheBlock)block;

/**
 Loops through all objects in the cache with reads and writes suspended. Calling serial methods which
 write to the cache inside block may be unsafe and may result in a deadlock. This method returns immediately.
 
 @param block A block to be executed for every object in the cache.
 @param completionBlock An optional block to be executed concurrently when the enumeration is complete.
 */
- (void)enumerateObjectsWithBlockAsync:(PI_NCacheObjectEnumerationBlock)block completionBlock:(nullable PI_NCacheBlock)completionBlock;

#pragma mark - Synchronous Methods
/// @name Synchronous Methods

/**
 Removes objects from the cache, costliest objects first, until the <totalCost> is below the specified
 value. This method blocks the calling thread until the cache has been trimmed.
 
 @see trimToCostAsync:
 @param cost The total accumulation allowed to remain after the cache has been trimmed.
 */
- (void)trimToCost:(NSUInteger)cost;

/**
 Removes objects from the cache, ordered by date (least recently used first), until the <totalCost> is below
 the specified value. This method blocks the calling thread until the cache has been trimmed.
 
 @see trimToCostByDateAsync:
 @param cost The total accumulation allowed to remain after the cache has been trimmed.
 */
- (void)trimToCostByDate:(NSUInteger)cost;

/**
 Loops through all objects in the cache within a memory lock (reads and writes are suspended during the enumeration).
 This method blocks the calling thread until all objects have been enumerated.
 Calling synchronous methods on the cache within this callback will likely cause a deadlock.
 
 @see enumerateObjectsWithBlockAsync:completionBlock:
 @param block A block to be executed for every object in the cache.
 
 @warning Do not call this method within the event blocks (<didReceiveMemoryWarningBlock>, etc.)
 Instead use the asynchronous version, <enumerateObjectsWithBlock:completionBlock:>.
 
 */
- (void)enumerateObjectsWithBlock:(PI_N_NOESCAPE PI_NCacheObjectEnumerationBlock)block;

@end


#pragma mark - Deprecated

typedef void (^PI_NMemoryCacheBlock)(PI_NMemoryCache *cache);
typedef void (^PI_NMemoryCacheObjectBlock)(PI_NMemoryCache *cache, NSString *key, id _Nullable object);
typedef void (^PI_NMemoryCacheContainmentBlock)(BOOL containsObject);

@interface PI_NMemoryCache (Deprecated)
- (void)containsObjectForKey:(NSString *)key block:(PI_NMemoryCacheContainmentBlock)block __attribute__((deprecated));
- (void)objectForKey:(NSString *)key block:(nullable PI_NMemoryCacheObjectBlock)block __attribute__((deprecated));
- (void)setObject:(id)object forKey:(NSString *)key block:(nullable PI_NMemoryCacheObjectBlock)block __attribute__((deprecated));
- (void)setObject:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost block:(nullable PI_NMemoryCacheObjectBlock)block __attribute__((deprecated));
- (void)removeObjectForKey:(NSString *)key block:(nullable PI_NMemoryCacheObjectBlock)block __attribute__((deprecated));
- (void)trimToDate:(NSDate *)date block:(nullable PI_NMemoryCacheBlock)block __attribute__((deprecated));
- (void)trimToCost:(NSUInteger)cost block:(nullable PI_NMemoryCacheBlock)block __attribute__((deprecated));
- (void)trimToCostByDate:(NSUInteger)cost block:(nullable PI_NMemoryCacheBlock)block __attribute__((deprecated));
- (void)removeAllObjects:(nullable PI_NMemoryCacheBlock)block __attribute__((deprecated));
- (void)enumerateObjectsWithBlock:(PI_NMemoryCacheObjectBlock)block completionBlock:(nullable PI_NMemoryCacheBlock)completionBlock __attribute__((deprecated));
@end

NS_ASSUME_NONNULL_END
