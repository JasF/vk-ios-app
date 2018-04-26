//
//  PI_NCache+PI_NRemoteImageCaching.m
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import "PI_NCache+PI_NRemoteImageCaching.h"

@implementation PI_NCache (PI_NRemoteImageCaching)

//******************************************************************************************************
// Memory cache methods
//******************************************************************************************************
-(nullable id)objectFromMemoryForKey:(NSString *)key
{
    return [self.memoryCache objectForKey:key];
}

-(void)setObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost
{
    [self.memoryCache setObject:object forKey:key withCost:cost];
}

- (void)removeObjectForKeyFromMemory:(NSString *)key
{
    [self.memoryCache removeObjectForKey:key];
}

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
-(nullable id)objectFromDiskForKey:(NSString *)key
{
    return [self.diskCache objectForKey:key];
}

-(void)objectFromDiskForKey:(NSString *)key completion:(PI_NRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) weakSelf = self;
    [self.diskCache objectForKeyAsync:key completion:^(PI_NDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        if(completion) {
            typeof(self) strongSelf = weakSelf;
            completion(strongSelf, key, object);
        }
    }];
}

-(void)setObjectOnDisk:(id)object forKey:(NSString *)key
{
    [self.diskCache setObject:object forKey:key];
}

- (BOOL)objectExistsForKey:(NSString *)key
{
    return [self containsObjectForKey:key];
}

//******************************************************************************************************
// Common cache methods
//******************************************************************************************************
- (void)removeObjectForKey:(NSString *)key completion:(PI_NRemoteImageCachingObjectBlock)completion
{
  if (completion) {
    __weak typeof(self) weakSelf = self;
    [self removeObjectForKeyAsync:key completion:^(PI_NCache * _Nonnull cache, NSString * _Nonnull key, id  _Nullable object) {
        typeof(self) strongSelf = weakSelf;
        completion(strongSelf, key, object);
    }];
  } else {
    [self removeObjectForKeyAsync:key completion:nil];
  }
}

@end

@implementation PI_NRemoteImageManager (PI_NCache)

- (PI_NCache <PI_NRemoteImageCaching> *)pinCache
{
  static BOOL isCachePI_NCache = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    isCachePI_NCache = [self.cache isKindOfClass:[PI_NCache class]];
  });
  if (isCachePI_NCache) {
    return (PI_NCache <PI_NRemoteImageCaching> *)self.cache;
  }
  return nil;
}

@end
