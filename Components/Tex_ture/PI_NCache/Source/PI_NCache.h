//  PI_NCache is a modified version of TMCache
//  Modifications by Garrett Moon
//  Copyright (c) 2015 Pinterest. All rights reserved.

#import <Foundation/Foundation.h>

#import <PI_NCache/PI_NCacheMacros.h>
#import <PI_NCache/PI_NCaching.h>
#import <PI_NCache/PI_NDiskCache.h>
#import <PI_NCache/PI_NMemoryCache.h>

NS_ASSUME_NONNULL_BEGIN

@class PI_NCache;


/**
 `PI_NCache` is a thread safe key/value store designed for persisting temporary objects that are expensive to
 reproduce, such as downloaded data or the results of slow processing. It is comprised of two self-similar
 stores, one in memory (<PI_NMemoryCache>) and one on disk (<PI_NDiskCache>).
 
 `PI_NCache` itself actually does very little; its main function is providing a front end for a common use case:
 a small, fast memory cache that asynchronously persists itself to a large, slow disk cache. When objects are
 removed from the memory cache in response to an "apocalyptic" event they remain in the disk cache and are
 repopulated in memory the next time they are accessed. `PI_NCache` also does the tedious work of creating a
 dispatch group to wait for both caches to finish their operations without blocking each other.
 
 The parallel caches are accessible as public properties (<memoryCache> and <diskCache>) and can be manipulated
 separately if necessary. See the docs for <PI_NMemoryCache> and <PI_NDiskCache> for more details.

 @warning when using in extension or watch extension, define PI_N_APP_EXTENSIONS=1
 */

PI_N_SUBCLASSING_RESTRICTED
@interface PI_NCache : NSObject <PI_NCaching, PI_NCacheObjectSubscripting>

#pragma mark -
/// @name Core

/**
 Synchronously retrieves the total byte count of the <diskCache> on the shared disk queue.
 */
@property (readonly) NSUInteger diskByteCount;

/**
 The underlying disk cache, see <PI_NDiskCache> for additional configuration and trimming options.
 */
@property (readonly) PI_NDiskCache *diskCache;

/**
 The underlying memory cache, see <PI_NMemoryCache> for additional configuration and trimming options.
 */
@property (readonly) PI_NMemoryCache *memoryCache;

#pragma mark - Lifecycle
/// @name Initialization

/**
 A shared cache.
 
 @result The shared singleton cache instance.
 */
@property (class, strong, readonly) PI_NCache *sharedCache;

- (instancetype)init NS_UNAVAILABLE;

/**
 Multiple instances with the same name are *not* allowed and can *not* safely
 access the same data on disk. Also used to create the <diskCache>.
 
 @see name
 @param name The name of the cache.
 @result A new cache with the specified name.
 */
- (instancetype)initWithName:(nonnull NSString *)name;

/**
 Multiple instances with the same name are *not* allowed and can *not* safely
 access the same data on disk. Also used to create the <diskCache>.
 
 @see name
 @param name The name of the cache.
 @param rootPath The path of the cache on disk.
 @result A new cache with the specified name.
 */
- (instancetype)initWithName:(nonnull NSString *)name rootPath:(nonnull NSString *)rootPath;

/**
 Multiple instances with the same name are *not* allowed and can *not* safely
 access the same data on disk.. Also used to create the <diskCache>.
 Initializer allows you to override default NSKeyedArchiver/NSKeyedUnarchiver serialization for <diskCache>.
 You must provide both serializer and deserializer, or opt-out to default implementation providing nil values.
 
 @see name
 @param name The name of the cache.
 @param rootPath The path of the cache on disk.
 @param serializer   A block used to serialize object before writing to disk. If nil provided, default NSKeyedArchiver serialized will be used.
 @param deserializer A block used to deserialize object read from disk. If nil provided, default NSKeyedUnarchiver serialized will be used.
 @result A new cache with the specified name.
 */
- (instancetype)initWithName:(NSString *)name
                    rootPath:(NSString *)rootPath
                  serializer:(nullable PI_NDiskCacheSerializerBlock)serializer
                deserializer:(nullable PI_NDiskCacheDeserializerBlock)deserializer;


/**
 Multiple instances with the same name are *not* allowed and can *not* safely
 access the same data on disk. Also used to create the <diskCache>.
 Initializer allows you to override default NSKeyedArchiver/NSKeyedUnarchiver serialization for <diskCache>.
 You must provide both serializer and deserializer, or opt-out to default implementation providing nil values.
 
 @see name
 @param name The name of the cache.
 @param rootPath The path of the cache on disk.
 @param serializer   A block used to serialize object before writing to disk. If nil provided, default NSKeyedArchiver serialized will be used.
 @param deserializer A block used to deserialize object read from disk. If nil provided, default NSKeyedUnarchiver serialized will be used.
 @param keyEncoder A block used to encode key(filename). If nil provided, default url encoder will be used
 @param keyDecoder A block used to decode key(filename). If nil provided, default url decoder will be used
 @result A new cache with the specified name.
 */
- (instancetype)initWithName:(nonnull NSString *)name
                    rootPath:(nonnull NSString *)rootPath
                  serializer:(nullable PI_NDiskCacheSerializerBlock)serializer
                deserializer:(nullable PI_NDiskCacheDeserializerBlock)deserializer
                  keyEncoder:(nullable PI_NDiskCacheKeyEncoderBlock)keyEncoder
                  keyDecoder:(nullable PI_NDiskCacheKeyDecoderBlock)keyDecoder NS_DESIGNATED_INITIALIZER;

@end

@interface PI_NCache (Deprecated)
- (void)containsObjectForKey:(NSString *)key block:(PI_NCacheObjectContainmentBlock)block __attribute__((deprecated));
- (void)objectForKey:(NSString *)key block:(PI_NCacheObjectBlock)block __attribute__((deprecated));
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key block:(nullable PI_NCacheObjectBlock)block __attribute__((deprecated));
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key withCost:(NSUInteger)cost block:(nullable PI_NCacheObjectBlock)block __attribute__((deprecated));
- (void)removeObjectForKey:(NSString *)key block:(nullable PI_NCacheObjectBlock)block __attribute__((deprecated));
- (void)trimToDate:(NSDate *)date block:(nullable PI_NCacheBlock)block __attribute__((deprecated));
- (void)removeAllObjects:(nullable PI_NCacheBlock)block __attribute__((deprecated));
@end

NS_ASSUME_NONNULL_END
