//
//  A_SPI_NRemoteImageDownloader.m
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SAvailability.h>

#if A_S_PI_N_REMOTE_IMAGE
#import <Async_DisplayKit/A_SPI_NRemoteImageDownloader.h>

#import <Async_DisplayKit/A_SAssert.h>
#import <Async_DisplayKit/A_SThread.h>
#import <Async_DisplayKit/A_SImageContainerProtocolCategories.h>

#if __has_include (<PI_NRemoteImage/PI_NGIFAnimatedImage.h>)
#define PI_N_ANIMATED_AVAILABLE 1
#import <PI_NRemoteImage/PI_NCachedAnimatedImage.h>
#import <PI_NRemoteImage/PI_NAlternateRepresentationProvider.h>
#else
#define PI_N_ANIMATED_AVAILABLE 0
#endif

#if __has_include(<webp/decode.h>)
#define PI_N_WEBP_AVAILABLE  1
#else
#define PI_N_WEBP_AVAILABLE  0
#endif

#import <PI_NRemoteImage/PI_NRemoteImageManager.h>
#import <PI_NRemoteImage/NSData+ImageDe_tectors.h>
#import <PI_NRemoteImage/PI_NRemoteImageCaching.h>

#if PI_N_ANIMATED_AVAILABLE

@interface A_SPI_NRemoteImageDownloader () <PI_NRemoteImageManagerAlternateRepresentationProvider>

@end

@interface PI_NCachedAnimatedImage (A_SPI_NRemoteImageDownloader) <A_SAnimatedImageProtocol>

@end

@implementation PI_NCachedAnimatedImage (A_SPI_NRemoteImageDownloader)

- (BOOL)isDataSupported:(NSData *)data
{
    if ([data pin_isGIF]) {
        return YES;
    }
#if PI_N_WEBP_AVAILABLE
    else if ([data pin_isAnimatedWebP]) {
        return YES;
    }
#endif
  return NO;
}

@end
#endif

// Declare two key methods on PI_NCache objects, avoiding a direct dependency on PI_NCache.h
@protocol A_SPI_NCache
- (id)diskCache;
@end

@protocol A_SPI_NDiskCache
@property (assign) NSUInteger byteLimit;
@end

@interface A_SPI_NRemoteImageManager : PI_NRemoteImageManager
@end

@implementation A_SPI_NRemoteImageManager

//Share image cache with sharedImageManager image cache.
- (id <PI_NRemoteImageCaching>)defaultImageCache
{
  static dispatch_once_t onceToken;
  static id <PI_NRemoteImageCaching> cache = nil;
  dispatch_once(&onceToken, ^{
    cache = [[PI_NRemoteImageManager sharedImageManager] cache];
    if ([cache respondsToSelector:@selector(diskCache)]) {
      id diskCache = [(id <A_SPI_NCache>)cache diskCache];
      if ([diskCache respondsToSelector:@selector(setByteLimit:)]) {
        // Set a default byteLimit. PI_NCache recently implemented a 50MB default (PR #201).
        // Ensure that older versions of PI_NCache also have a byteLimit applied.
        // NOTE: Using 20MB limit while large cache initialization is being optimized (Issue #144).
        ((id <A_SPI_NDiskCache>)diskCache).byteLimit = 20 * 1024 * 1024;
      }
    }
  });
  return cache;
}

@end


static A_SPI_NRemoteImageDownloader *sharedDownloader = nil;

@interface A_SPI_NRemoteImageDownloader ()
@end

@implementation A_SPI_NRemoteImageDownloader

+ (instancetype)sharedDownloader
{

  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    sharedDownloader = [[A_SPI_NRemoteImageDownloader alloc] init];
  });
  return sharedDownloader;
}

+ (void)setSharedImageManagerWithConfiguration:(nullable NSURLSessionConfiguration *)configuration
{
  NSAssert(sharedDownloader == nil, @"Singleton has been created and session can no longer be configured.");
  __unused PI_NRemoteImageManager *sharedManager = [self sharedPI_NRemoteImageManagerWithConfiguration:configuration];
}

+ (PI_NRemoteImageManager *)sharedPI_NRemoteImageManagerWithConfiguration:(NSURLSessionConfiguration *)configuration
{
  static A_SPI_NRemoteImageManager *sharedPI_NRemoteImageManager;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{

#if PI_N_ANIMATED_AVAILABLE
    // Check that Carthage users have linked both PI_NRemoteImage & PI_NCache by testing for one file each
    if (!(NSClassFromString(@"PI_NRemoteImageManager"))) {
      NSException *e = [NSException
                        exceptionWithName:@"FrameworkSetupException"
                        reason:@"Missing the path to the PI_NRemoteImage framework."
                        userInfo:nil];
      @throw e;
    }
    if (!(NSClassFromString(@"PI_NCache"))) {
      NSException *e = [NSException
                        exceptionWithName:@"FrameworkSetupException"
                        reason:@"Missing the path to the PI_NCache framework."
                        userInfo:nil];
      @throw e;
    }
    sharedPI_NRemoteImageManager = [[A_SPI_NRemoteImageManager alloc] initWithSessionConfiguration:configuration
                                                              alternativeRepresentationProvider:[self sharedDownloader]];
#else
    sharedPI_NRemoteImageManager = [[A_SPI_NRemoteImageManager alloc] initWithSessionConfiguration:configuration];
#endif
  });
  return sharedPI_NRemoteImageManager;
}

- (PI_NRemoteImageManager *)sharedPI_NRemoteImageManager
{
  return [A_SPI_NRemoteImageDownloader sharedPI_NRemoteImageManagerWithConfiguration:nil];
}

- (BOOL)sharedImageManagerSupportsMemoryRemoval
{
  static BOOL sharedImageManagerSupportsMemoryRemoval = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedImageManagerSupportsMemoryRemoval = [[[self sharedPI_NRemoteImageManager] cache] respondsToSelector:@selector(removeObjectForKeyFromMemory:)];
  });
  return sharedImageManagerSupportsMemoryRemoval;
}

#pragma mark A_SImageProtocols

#if PI_N_ANIMATED_AVAILABLE
- (nullable id <A_SAnimatedImageProtocol>)animatedImageWithData:(NSData *)animatedImageData
{
  return [[PI_NCachedAnimatedImage alloc] initWithAnimatedImageData:animatedImageData];
}
#endif

- (id <A_SImageContainerProtocol>)synchronouslyFetchedCachedImageWithURL:(NSURL *)URL;
{
  PI_NRemoteImageManager *manager = [self sharedPI_NRemoteImageManager];
  PI_NRemoteImageManagerResult *result = [manager synchronousImageFromCacheWithURL:URL processorKey:nil options:PI_NRemoteImageManagerDownloadOptionsSkipDecode];
  
#if PI_N_ANIMATED_AVAILABLE
  if (result.alternativeRepresentation) {
    return result.alternativeRepresentation;
  }
#endif
  return result.image;
}

- (void)cachedImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
                completion:(A_SImageCacherCompletion)completion
{
  [[self sharedPI_NRemoteImageManager] imageFromCacheWithURL:URL processorKey:nil options:PI_NRemoteImageManagerDownloadOptionsSkipDecode completion:^(PI_NRemoteImageManagerResult * _Nonnull result) {
    [A_SPI_NRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
      completion(result.image);
    }];
  }];
}

- (void)cachedImageWithURLs:(NSArray <NSURL *> *)URLs
              callbackQueue:(dispatch_queue_t)callbackQueue
                 completion:(A_SImageCacherCompletion)completion
{
  [self cachedImageWithURL:[URLs lastObject]
             callbackQueue:callbackQueue
                completion:^(id<A_SImageContainerProtocol>  _Nullable imageFromCache) {
                  if (imageFromCache.asdk_image == nil && URLs.count > 1) {
                    [self cachedImageWithURLs:[URLs subarrayWithRange:NSMakeRange(0, URLs.count - 1)]
                                callbackQueue:callbackQueue
                                   completion:completion];
                  } else {
                    completion(imageFromCache);
                  }
                }];
}

- (void)clearFetchedImageFromCacheWithURL:(NSURL *)URL
{
  if ([self sharedImageManagerSupportsMemoryRemoval]) {
    PI_NRemoteImageManager *manager = [self sharedPI_NRemoteImageManager];
    NSString *key = [manager cacheKeyForURL:URL processorKey:nil];
    [[manager cache] removeObjectForKeyFromMemory:key];
  }
}

- (nullable id)downloadImageWithURL:(NSURL *)URL
                      callbackQueue:(dispatch_queue_t)callbackQueue
                   downloadProgress:(A_SImageDownloaderProgress)downloadProgress
                         completion:(A_SImageDownloaderCompletion)completion;
{
    NSArray <NSURL *>*URLs = nil;
    if (URL) {
        URLs = @[URL];
    }
    return [self downloadImageWithURLs:URLs callbackQueue:callbackQueue downloadProgress:downloadProgress completion:completion];
}

- (nullable id)downloadImageWithURLs:(NSArray <NSURL *> *)URLs
                       callbackQueue:(dispatch_queue_t)callbackQueue
                    downloadProgress:(nullable A_SImageDownloaderProgress)downloadProgress
                          completion:(A_SImageDownloaderCompletion)completion
{
  PI_NRemoteImageManagerProgressDownload progressDownload = ^(int64_t completedBytes, int64_t totalBytes) {
    if (downloadProgress == nil) { return; }

    [A_SPI_NRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
      downloadProgress(completedBytes / (CGFloat)totalBytes);
    }];
  };

  PI_NRemoteImageManagerImageCompletion imageCompletion = ^(PI_NRemoteImageManagerResult * _Nonnull result) {
    [A_SPI_NRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
#if PI_N_ANIMATED_AVAILABLE
      if (result.alternativeRepresentation) {
        completion(result.alternativeRepresentation, result.error, result.UUID);
      } else {
        completion(result.image, result.error, result.UUID);
      }
#else
      completion(result.image, result.error, result.UUID);
#endif
    }];
  };

  // add "IgnoreCache" option since we have a caching API so we already checked it, not worth checking again.
  // PI_NRemoteImage is responsible for coalescing downloads, and even if it wasn't, the tiny probability of
  // extra downloads isn't worth the effort of rechecking caches every single time. In order to provide
  // feedback to the consumer about whether images are cached, we can't simply make the cache a no-op and
  // check the cache as part of this download.
  return [[self sharedPI_NRemoteImageManager] downloadImageWithURLs:URLs
                                                           options:PI_NRemoteImageManagerDownloadOptionsSkipDecode | PI_NRemoteImageManagerDownloadOptionsIgnoreCache
                                                     progressImage:nil
                                                  progressDownload:progressDownload
                                                        completion:imageCompletion];
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  A_SDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  [[self sharedPI_NRemoteImageManager] cancelTaskWithUUID:downloadIdentifier storeResumeData:NO];
}

- (void)cancelImageDownloadWithResumePossibilityForIdentifier:(id)downloadIdentifier
{
  A_SDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  [[self sharedPI_NRemoteImageManager] cancelTaskWithUUID:downloadIdentifier storeResumeData:YES];
}

- (void)setProgressImageBlock:(A_SImageDownloaderProgressImage)progressBlock callbackQueue:(dispatch_queue_t)callbackQueue withDownloadIdentifier:(id)downloadIdentifier
{
  A_SDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");

  if (progressBlock) {
    [[self sharedPI_NRemoteImageManager] setProgressImageCallback:^(PI_NRemoteImageManagerResult * _Nonnull result) {
      dispatch_async(callbackQueue, ^{
        progressBlock(result.image, result.renderedImageQuality, result.UUID);
      });
    } ofTaskWithUUID:downloadIdentifier];
  } else {
    [[self sharedPI_NRemoteImageManager] setProgressImageCallback:nil ofTaskWithUUID:downloadIdentifier];
  }
}

- (void)setPriority:(A_SImageDownloaderPriority)priority withDownloadIdentifier:(id)downloadIdentifier
{
  A_SDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");

  PI_NRemoteImageManagerPriority pi_priority = PI_NRemoteImageManagerPriorityDefault;
  switch (priority) {
    case A_SImageDownloaderPriorityPreload:
      pi_priority = PI_NRemoteImageManagerPriorityLow;
      break;

    case A_SImageDownloaderPriorityImminent:
      pi_priority = PI_NRemoteImageManagerPriorityDefault;
      break;

    case A_SImageDownloaderPriorityVisible:
      pi_priority = PI_NRemoteImageManagerPriorityHigh;
      break;
  }
  [[self sharedPI_NRemoteImageManager] setPriority:pi_priority ofTaskWithUUID:downloadIdentifier];
}

#pragma mark - PI_NRemoteImageManagerAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PI_NRemoteImageManagerDownloadOptions)options
{
#if PI_N_ANIMATED_AVAILABLE
  if ([data pin_isGIF]) {
    return data;
  }
#if PI_N_WEBP_AVAILABLE
  else if ([data pin_isAnimatedWebP]) {
      return data;
  }
#endif
    
#endif
  return nil;
}

#pragma mark - Private

/**
 * If on main thread and queue is main, perform now.
 * If queue is nil, assert and perform now.
 * Otherwise, dispatch async to queue.
 */
+ (void)_performWithCallbackQueue:(dispatch_queue_t)queue work:(void (^)())work
{
  if (work == nil) {
    // No need to assert here, really. We aren't expecting any feedback from this method.
    return;
  }

  if (A_SDisplayNodeThreadIsMain() && queue == dispatch_get_main_queue()) {
    work();
  } else if (queue == nil) {
    A_SDisplayNodeFailAssert(@"Callback queue should not be nil.");
    work();
  } else {
    dispatch_async(queue, work);
  }
}

@end
#endif
