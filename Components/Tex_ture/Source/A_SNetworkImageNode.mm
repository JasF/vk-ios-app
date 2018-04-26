//
//  A_SNetworkImageNode.mm
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

#import <Async_DisplayKit/A_SNetworkImageNode.h>

#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SBasicImageDownloader.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SImageNode+Private.h>
#import <Async_DisplayKit/A_SImageNode+AnimatedImagePrivate.h>
#import <Async_DisplayKit/A_SImageContainerProtocolCategories.h>
#import <Async_DisplayKit/A_SLog.h>

#if A_S_PI_N_REMOTE_IMAGE
#import <Async_DisplayKit/A_SPI_NRemoteImageDownloader.h>
#endif

@interface A_SNetworkImageNode ()
{
  // Only access any of these with __instanceLock__.
  __weak id<A_SNetworkImageNodeDelegate> _delegate;

  NSArray *_URLs;
  UIImage *_defaultImage;

  NSUUID *_cacheUUID;
  id _downloadIdentifier;
  // The download identifier that we have set a progress block on, if any.
  id _downloadIdentifierForProgressBlock;

  BOOL _imageLoaded;
  BOOL _imageWasSetExternally;
  CGFloat _currentImageQuality;
  CGFloat _renderedImageQuality;
  BOOL _shouldRenderProgressImages;

  struct {
    unsigned int delegateDidStartFetchingData:1;
    unsigned int delegateDidFailWithError:1;
    unsigned int delegateDidFinishDecoding:1;
    unsigned int delegateDidLoadImage:1;
    unsigned int delegateDidLoadImageWithInfo:1;
  } _delegateFlags;

  
  // Immutable and set on init only. We don't need to lock in this case.
  __weak id<A_SImageDownloaderProtocol> _downloader;
  struct {
    unsigned int downloaderImplementsSetProgress:1;
    unsigned int downloaderImplementsSetPriority:1;
    unsigned int downloaderImplementsAnimatedImage:1;
    unsigned int downloaderImplementsCancelWithResume:1;
    unsigned int downloaderImplementsDownloadURLs:1;
  } _downloaderFlags;

  // Immutable and set on init only. We don't need to lock in this case.
  __weak id<A_SImageCacheProtocol> _cache;
  struct {
    unsigned int cacheSupportsClearing:1;
    unsigned int cacheSupportsSynchronousFetch:1;
    unsigned int cacheSupportsCachedURLs:1;
  } _cacheFlags;
}

@end

@implementation A_SNetworkImageNode

@dynamic image;

- (instancetype)initWithCache:(id<A_SImageCacheProtocol>)cache downloader:(id<A_SImageDownloaderProtocol>)downloader
{
  if (!(self = [super init]))
    return nil;

  _cache = (id<A_SImageCacheProtocol>)cache;
  _downloader = (id<A_SImageDownloaderProtocol>)downloader;
  
  _downloaderFlags.downloaderImplementsSetProgress = [downloader respondsToSelector:@selector(setProgressImageBlock:callbackQueue:withDownloadIdentifier:)];
  _downloaderFlags.downloaderImplementsSetPriority = [downloader respondsToSelector:@selector(setPriority:withDownloadIdentifier:)];
  _downloaderFlags.downloaderImplementsAnimatedImage = [downloader respondsToSelector:@selector(animatedImageWithData:)];
  _downloaderFlags.downloaderImplementsCancelWithResume = [downloader respondsToSelector:@selector(cancelImageDownloadWithResumePossibilityForIdentifier:)];
  _downloaderFlags.downloaderImplementsDownloadURLs = [downloader respondsToSelector:@selector(downloadImageWithURLs:callbackQueue:downloadProgress:completion:)];

  _cacheFlags.cacheSupportsClearing = [cache respondsToSelector:@selector(clearFetchedImageFromCacheWithURL:)];
  _cacheFlags.cacheSupportsSynchronousFetch = [cache respondsToSelector:@selector(synchronouslyFetchedCachedImageWithURL:)];
  _cacheFlags.cacheSupportsCachedURLs = [cache respondsToSelector:@selector(cachedImageWithURLs:callbackQueue:completion:)];
  
  _shouldCacheImage = YES;
  _shouldRenderProgressImages = YES;
  self.shouldBypassEnsureDisplay = YES;

  return self;
}

- (instancetype)init
{
#if A_S_PI_N_REMOTE_IMAGE
  return [self initWithCache:[A_SPI_NRemoteImageDownloader sharedDownloader] downloader:[A_SPI_NRemoteImageDownloader sharedDownloader]];
#else
  return [self initWithCache:nil downloader:[A_SBasicImageDownloader sharedImageDownloader]];
#endif
}

- (void)dealloc
{
  [self _cancelImageDownloadWithResumePossibility:NO];
}

#pragma mark - Public methods -- must lock

/// Setter for public image property. It has the side effect of setting an internal _imageWasSetExternally that prevents setting an image internally. Setting an image internally should happen with the _setImage: method
- (void)setImage:(UIImage *)image
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setImage:image];
}

- (void)_locked_setImage:(UIImage *)image
{
  BOOL imageWasSetExternally = (image != nil);
  BOOL shouldCancelAndClear = imageWasSetExternally && (imageWasSetExternally != _imageWasSetExternally);
  _imageWasSetExternally = imageWasSetExternally;
  if (shouldCancelAndClear) {
    A_SDisplayNodeAssert(_URLs == nil || _URLs.count == 0, @"Directly setting an image on an A_SNetworkImageNode causes it to behave like an A_SImageNode instead of an A_SNetworkImageNode. If this is what you want, set the URL to nil first.");
    _URLs = nil;
    [self _locked_cancelDownloadAndClearImageWithResumePossibility:NO];
  }
  
  [self _locked__setImage:image];
}

/// Setter for private image property. See @c _locked_setImage why this is needed
- (void)_setImage:(UIImage *)image
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked__setImage:image];
}

- (void)_locked__setImage:(UIImage *)image
{
  [super _locked_setImage:image];
}

- (void)setURL:(NSURL *)URL
{
  if (URL) {
    [self setURLs:@[URL]];
  } else {
    [self setURLs:nil];
  }
}

- (void)setURL:(NSURL *)URL resetToDefault:(BOOL)reset
{
  if (URL) {
    [self setURLs:@[URL] resetToDefault:reset];
  } else {
    [self setURLs:nil resetToDefault:reset];
  }
}

- (NSURL *)URL
{
  return [self.URLs lastObject];
}

- (void)setURLs:(NSArray <NSURL *> *)URLs
{
  [self setURLs:URLs resetToDefault:YES];
}

- (void)setURLs:(NSArray <NSURL *> *)URLs resetToDefault:(BOOL)reset
{
  {
    A_SDN::MutexLocker l(__instanceLock__);
    
    if (A_SObjectIsEqual(URLs, _URLs)) {
      return;
    }
    
    A_SDisplayNodeAssert(_imageWasSetExternally == NO, @"Setting a URL to an A_SNetworkImageNode after setting an image changes its behavior from an A_SImageNode to an A_SNetworkImageNode. If this is what you want, set the image to nil first.");
    
    _imageWasSetExternally = NO;
    
    [self _locked_cancelImageDownloadWithResumePossibility:NO];
    
    _imageLoaded = NO;
    
    _URLs = URLs;
    
    BOOL hasURL = (_URLs.count == 0);
    if (reset || hasURL) {
      [self _locked_setCurrentImageQuality:(hasURL ? 0.0 : 1.0)];
      [self _locked__setImage:_defaultImage];
    }
  }
  
  [self setNeedsPreload];
}

- (NSArray <NSURL *>*)URLs
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _URLs;
}

- (void)setDefaultImage:(UIImage *)defaultImage
{
  A_SDN::MutexLocker l(__instanceLock__);

  [self _locked_setDefaultImage:defaultImage];
}

- (void)_locked_setDefaultImage:(UIImage *)defaultImage
{
  if (A_SObjectIsEqual(defaultImage, _defaultImage)) {
    return;
  }

  _defaultImage = defaultImage;

  if (!_imageLoaded) {
    [self _locked_setCurrentImageQuality:((_URLs.count == 0) ? 0.0 : 1.0)];
    [self _locked__setImage:defaultImage];
    
  }
}

- (UIImage *)defaultImage
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _defaultImage;
}

- (void)setCurrentImageQuality:(CGFloat)currentImageQuality
{
  A_SDN::MutexLocker l(__instanceLock__);
  _currentImageQuality = currentImageQuality;
}

- (CGFloat)currentImageQuality
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _currentImageQuality;
}

/**
 * Always use this methods internally to update the current image quality
 * We want to maintain the order that currentImageQuality is set regardless of the calling thread,
 * so we always have to dispatch to the main threadto ensure that we queue the operations in the correct order.
 * (see comment in displayDidFinish)
 */
- (void)_setCurrentImageQuality:(CGFloat)imageQuality
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_setCurrentImageQuality:imageQuality];
}

- (void)_locked_setCurrentImageQuality:(CGFloat)imageQuality
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // As the setting of the image quality is dispatched the lock is gone by the time the block is executing.
    // Therefore we have to grab the lock again
    __instanceLock__.lock();
      _currentImageQuality = imageQuality;
    __instanceLock__.unlock();
  });
}

- (void)setRenderedImageQuality:(CGFloat)renderedImageQuality
{
  A_SDN::MutexLocker l(__instanceLock__);
  _renderedImageQuality = renderedImageQuality;
}

- (CGFloat)renderedImageQuality
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _renderedImageQuality;
}

- (void)setDelegate:(id<A_SNetworkImageNodeDelegate>)delegate
{
  A_SDN::MutexLocker l(__instanceLock__);
  _delegate = delegate;
  
  _delegateFlags.delegateDidStartFetchingData = [delegate respondsToSelector:@selector(imageNodeDidStartFetchingData:)];
  _delegateFlags.delegateDidFailWithError = [delegate respondsToSelector:@selector(imageNode:didFailWithError:)];
  _delegateFlags.delegateDidFinishDecoding = [delegate respondsToSelector:@selector(imageNodeDidFinishDecoding:)];
  _delegateFlags.delegateDidLoadImage = [delegate respondsToSelector:@selector(imageNode:didLoadImage:)];
  _delegateFlags.delegateDidLoadImageWithInfo = [delegate respondsToSelector:@selector(imageNode:didLoadImage:info:)];
}

- (id<A_SNetworkImageNodeDelegate>)delegate
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _delegate;
}

- (void)setShouldRenderProgressImages:(BOOL)shouldRenderProgressImages
{
  {
    A_SDN::MutexLocker l(__instanceLock__);
    if (shouldRenderProgressImages == _shouldRenderProgressImages) {
      return;
    }
    _shouldRenderProgressImages = shouldRenderProgressImages;
  }

  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

- (BOOL)shouldRenderProgressImages
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _shouldRenderProgressImages;
}

- (BOOL)placeholderShouldPersist
{
  A_SDN::MutexLocker l(__instanceLock__);
  return (self.image == nil && self.animatedImage == nil && _URLs.count != 0);
}

/* displayWillStartAsynchronously: in A_SMultiplexImageNode has a very similar implementation. Changes here are likely necessary
 in A_SMultiplexImageNode as well. */
- (void)displayWillStartAsynchronously:(BOOL)asynchronously
{
  [super displayWillStartAsynchronously:asynchronously];
  
  if (asynchronously == NO && _cacheFlags.cacheSupportsSynchronousFetch) {
    A_SDN::MutexLocker l(__instanceLock__);

    if (_imageLoaded == NO && _URLs.count > 0 && _downloadIdentifier == nil) {
      for (NSURL *url in [_URLs reverseObjectEnumerator]) {
        UIImage *result = [[_cache synchronouslyFetchedCachedImageWithURL:url] asdk_image];
        if (result) {
          [self _locked_setCurrentImageQuality:1.0];
          [self _locked__setImage:result];
          _imageLoaded = YES;

          // Call out to the delegate.
          if (_delegateFlags.delegateDidLoadImageWithInfo) {
            A_SDN::MutexUnlocker l(__instanceLock__);
            A_SNetworkImageNodeDidLoadInfo info = {};
            info.imageSource = A_SNetworkImageSourceSynchronousCache;
            [_delegate imageNode:self didLoadImage:result info:info];
          } else if (_delegateFlags.delegateDidLoadImage) {
            A_SDN::MutexUnlocker l(__instanceLock__);
            [_delegate imageNode:self didLoadImage:result];
          }
          break;
        }
      }
    }
  }

  // TODO: Consider removing this; it predates A_SInterfaceState, which now ensures that even non-range-managed nodes get a -preload call.
  [self didEnterPreloadState];
  
  if (self.image == nil && _downloaderFlags.downloaderImplementsSetPriority) {
    __instanceLock__.lock();
      id downloadIdentifier = _downloadIdentifier;
    __instanceLock__.unlock();
    if (downloadIdentifier != nil) {
      [_downloader setPriority:A_SImageDownloaderPriorityImminent withDownloadIdentifier:downloadIdentifier];
    }
  }
}

/* visibileStateDidChange in A_SMultiplexImageNode has a very similar implementation. Changes here are likely necessary
 in A_SMultiplexImageNode as well. */
- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  
  __instanceLock__.lock();
    id downloadIdentifier = nil;
    if (_downloaderFlags.downloaderImplementsSetPriority) {
      downloadIdentifier = _downloadIdentifier;
    }
  __instanceLock__.unlock();
  
  if (downloadIdentifier != nil) {
    [_downloader setPriority:A_SImageDownloaderPriorityVisible withDownloadIdentifier:downloadIdentifier];
  }
  
  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];

  __instanceLock__.lock();
    id downloadIdentifier = nil;
    if (_downloaderFlags.downloaderImplementsSetPriority) {
      downloadIdentifier = _downloadIdentifier;
    }
  __instanceLock__.unlock();
  
  if (downloadIdentifier != nil) {
    [_downloader setPriority:A_SImageDownloaderPriorityPreload withDownloadIdentifier:downloadIdentifier];
  }
  
  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

- (void)didExitPreloadState
{
  [super didExitPreloadState];

  __instanceLock__.lock();
    BOOL imageWasSetExternally = _imageWasSetExternally;
  __instanceLock__.unlock();
  // If the image was set explicitly we don't want to remove it while exiting the preload state
  if (imageWasSetExternally) {
    return;
  }

  [self _cancelDownloadAndClearImageWithResumePossibility:YES];
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  
  // Image was set externally no need to load an image
  [self _lazilyLoadImageIfNecessary];
}

#pragma mark - Progress

- (void)handleProgressImage:(UIImage *)progressImage progress:(CGFloat)progress downloadIdentifier:(nullable id)downloadIdentifier
{
  A_SDN::MutexLocker l(__instanceLock__);
  
  // Getting a result back for a different download identifier, download must not have been successfully canceled
  if (A_SObjectIsEqual(_downloadIdentifier, downloadIdentifier) == NO && downloadIdentifier != nil) {
    return;
  }
  
  as_log_verbose(A_SImageLoadingLog(), "Received progress image for %@ q: %.2g id: %@", self, progress, progressImage);
  [self _locked_setCurrentImageQuality:progress];
  [self _locked__setImage:progressImage];
}

- (void)_updateProgressImageBlockOnDownloaderIfNeeded
{
  // If the downloader doesn't do progress, we are done.
  if (_downloaderFlags.downloaderImplementsSetProgress == NO) {
    return;
  }

  // Read state.
  __instanceLock__.lock();
    BOOL shouldRender = _shouldRenderProgressImages && A_SInterfaceStateIncludesVisible(_interfaceState);
    id oldDownloadIDForProgressBlock = _downloadIdentifierForProgressBlock;
    id newDownloadIDForProgressBlock = shouldRender ? _downloadIdentifier : nil;
    BOOL clearAndReattempt = NO;
  __instanceLock__.unlock();

  // If we're already bound to the correct download, we're done.
  if (A_SObjectIsEqual(oldDownloadIDForProgressBlock, newDownloadIDForProgressBlock)) {
    return;
  }

  // Unbind from the previous download.
  if (oldDownloadIDForProgressBlock != nil) {
    as_log_verbose(A_SImageLoadingLog(), "Disabled progress images for %@ id: %@", self, oldDownloadIDForProgressBlock);
    [_downloader setProgressImageBlock:nil callbackQueue:dispatch_get_main_queue() withDownloadIdentifier:oldDownloadIDForProgressBlock];
  }

  // Bind to the current download.
  if (newDownloadIDForProgressBlock != nil) {
    __weak __typeof(self) weakSelf = self;
    as_log_verbose(A_SImageLoadingLog(), "Enabled progress images for %@ id: %@", self, newDownloadIDForProgressBlock);
    [_downloader setProgressImageBlock:^(UIImage * _Nonnull progressImage, CGFloat progress, id  _Nullable downloadIdentifier) {
      [weakSelf handleProgressImage:progressImage progress:progress downloadIdentifier:downloadIdentifier];
    } callbackQueue:dispatch_get_main_queue() withDownloadIdentifier:newDownloadIDForProgressBlock];
  }

  // Update state local state with lock held.
  {
    A_SDN::MutexLocker l(__instanceLock__);
    // Check if the oldDownloadIDForProgressBlock still is the same as the _downloadIdentifierForProgressBlock
    if (_downloadIdentifierForProgressBlock == oldDownloadIDForProgressBlock) {
      _downloadIdentifierForProgressBlock = newDownloadIDForProgressBlock;
    } else if (newDownloadIDForProgressBlock != nil) {
      // If this is not the case another thread did change the _downloadIdentifierForProgressBlock already so
      // we have to deregister the newDownloadIDForProgressBlock that we registered above
      clearAndReattempt = YES;
    }
  }
  
  if (clearAndReattempt) {
    // In this case another thread changed the _downloadIdentifierForProgressBlock before we finished registering
    // the new progress block for newDownloadIDForProgressBlock ID. Let's clear it now and reattempt to register
    if (newDownloadIDForProgressBlock) {
      [_downloader setProgressImageBlock:nil callbackQueue:dispatch_get_main_queue() withDownloadIdentifier:newDownloadIDForProgressBlock];
    }
    [self _updateProgressImageBlockOnDownloaderIfNeeded];
  }
}

- (void)_cancelDownloadAndClearImageWithResumePossibility:(BOOL)storeResume
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_cancelDownloadAndClearImageWithResumePossibility:storeResume];
}

- (void)_locked_cancelDownloadAndClearImageWithResumePossibility:(BOOL)storeResume
{
  [self _locked_cancelImageDownloadWithResumePossibility:storeResume];
  
  [self _locked_setAnimatedImage:nil];
  [self _locked_setCurrentImageQuality:0.0];
  [self _locked__setImage:_defaultImage];

  _imageLoaded = NO;

  if (_cacheFlags.cacheSupportsClearing) {
    if (_URLs.count != 0) {
      as_log_verbose(A_SImageLoadingLog(), "Clearing cached image for %@ url: %@", self, _URLs);
      for (NSURL *url in _URLs) {
        [_cache clearFetchedImageFromCacheWithURL:url];
      }
    }
  }
}

- (void)_cancelImageDownloadWithResumePossibility:(BOOL)storeResume
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self _locked_cancelImageDownloadWithResumePossibility:storeResume];
}

- (void)_locked_cancelImageDownloadWithResumePossibility:(BOOL)storeResume
{
  if (!_downloadIdentifier) {
    return;
  }

  if (_downloadIdentifier) {
    if (storeResume && _downloaderFlags.downloaderImplementsCancelWithResume) {
      as_log_verbose(A_SImageLoadingLog(), "Canceling image download w resume for %@ id: %@", self, _downloadIdentifier);
      [_downloader cancelImageDownloadWithResumePossibilityForIdentifier:_downloadIdentifier];
    } else {
      as_log_verbose(A_SImageLoadingLog(), "Canceling image download no resume for %@ id: %@", self, _downloadIdentifier);
      [_downloader cancelImageDownloadForIdentifier:_downloadIdentifier];
    }
  }
  _downloadIdentifier = nil;

  _cacheUUID = nil;
}

- (void)_downloadImageWithCompletion:(void (^)(id <A_SImageContainerProtocol> imageContainer, NSError*, id downloadIdentifier))finished
{
  A_SPerformBlockOnBackgroundThread(^{
    NSArray <NSURL *> *urls;
    id downloadIdentifier;
    BOOL cancelAndReattempt = NO;
    
    // Below, to avoid performance issues, we're calling downloadImageWithURL without holding the lock. This is a bit ugly because
    // We need to reobtain the lock after and ensure that the task we've kicked off still matches our URL. If not, we need to cancel
    // it and try again.
    {
      A_SDN::MutexLocker l(__instanceLock__);
      urls = _URLs;
    }

    if (_downloaderFlags.downloaderImplementsDownloadURLs) {
      downloadIdentifier = [_downloader downloadImageWithURLs:urls
                                                callbackQueue:dispatch_get_main_queue()
                                             downloadProgress:NULL
                                                   completion:^(id <A_SImageContainerProtocol> _Nullable imageContainer, NSError * _Nullable error, id  _Nullable downloadIdentifier) {
                                                     if (finished != NULL) {
                                                       finished(imageContainer, error, downloadIdentifier);
                                                     }
                                                   }];
    } else {
      downloadIdentifier = [_downloader downloadImageWithURL:[urls lastObject]
                                               callbackQueue:dispatch_get_main_queue()
                                            downloadProgress:NULL
                                                  completion:^(id <A_SImageContainerProtocol> _Nullable imageContainer, NSError * _Nullable error, id  _Nullable downloadIdentifier) {
                                                    if (finished != NULL) {
                                                      finished(imageContainer, error, downloadIdentifier);
                                                    }
                                                  }];
    }
    
    as_log_verbose(A_SImageLoadingLog(), "Downloading image for %@ url: %@", self, url);
  
    {
      A_SDN::MutexLocker l(__instanceLock__);
      if (A_SObjectIsEqual(_URLs, urls)) {
        // The download we kicked off is correct, no need to do any more work.
        _downloadIdentifier = downloadIdentifier;
      } else {
        // The URL changed since we kicked off our download task. This shouldn't happen often so we'll pay the cost and
        // cancel that request and kick off a new one.
        cancelAndReattempt = YES;
      }
    }
    
    if (cancelAndReattempt) {
      if (downloadIdentifier != nil) {
        as_log_verbose(A_SImageLoadingLog(), "Canceling image download no resume for %@ id: %@", self, downloadIdentifier);
        [_downloader cancelImageDownloadForIdentifier:downloadIdentifier];
      }
      [self _downloadImageWithCompletion:finished];
      return;
    }
    
    [self _updateProgressImageBlockOnDownloaderIfNeeded];
  });
}

- (void)_lazilyLoadImageIfNecessary
{
  __instanceLock__.lock();
    __weak id<A_SNetworkImageNodeDelegate> delegate = _delegate;
    BOOL delegateDidStartFetchingData = _delegateFlags.delegateDidStartFetchingData;
    BOOL isImageLoaded = _imageLoaded;
    NSArray <NSURL *>*URLs = _URLs;
    id currentDownloadIdentifier = _downloadIdentifier;
  __instanceLock__.unlock();
  
  if (!isImageLoaded && URLs.count > 0 && currentDownloadIdentifier == nil) {
    if (delegateDidStartFetchingData) {
      [delegate imageNodeDidStartFetchingData:self];
    }
    
    // We only support file URLs if there is one URL currently
    if (URLs.count == 1 && [URLs lastObject].isFileURL) {
      dispatch_async(dispatch_get_main_queue(), ^{
        A_SDN::MutexLocker l(__instanceLock__);
        
        // Bail out if not the same URL anymore
        if (!A_SObjectIsEqual(URLs, _URLs)) {
          return;
        }
        
        NSURL *URL = [URLs lastObject];
        if (_shouldCacheImage) {
          [self _locked__setImage:[UIImage imageNamed:URL.path.lastPathComponent]];
        } else {
          // First try to load the path directly, for efficiency assuming a developer who
          // doesn't want caching is trying to be as minimal as possible.
          UIImage *nonAnimatedImage = [UIImage imageWithContentsOfFile:URL.path];
          if (nonAnimatedImage == nil) {
            // If we couldn't find it, execute an -imageNamed:-like search so we can find resources even if the
            // extension is not provided in the path.  This allows the same path to work regardless of shouldCacheImage.
            NSString *filename = [[NSBundle mainBundle] pathForResource:URL.path.lastPathComponent ofType:nil];
            if (filename != nil) {
              nonAnimatedImage = [UIImage imageWithContentsOfFile:filename];
            }
          }

          // If the file may be an animated gif and then created an animated image.
          id<A_SAnimatedImageProtocol> animatedImage = nil;
          if (_downloaderFlags.downloaderImplementsAnimatedImage) {
            NSData *data = [NSData dataWithContentsOfURL:URL];
            if (data != nil) {
              animatedImage = [_downloader animatedImageWithData:data];

              if ([animatedImage respondsToSelector:@selector(isDataSupported:)] && [animatedImage isDataSupported:data] == NO) {
                animatedImage = nil;
              }
            }
          }

          if (animatedImage != nil) {
            [self _locked_setAnimatedImage:animatedImage];
          } else {
            [self _locked__setImage:nonAnimatedImage];
          }
        }

        _imageLoaded = YES;

        [self _locked_setCurrentImageQuality:1.0];

        if (_delegateFlags.delegateDidLoadImageWithInfo) {
          A_SDN::MutexUnlocker u(__instanceLock__);
          A_SNetworkImageNodeDidLoadInfo info = {};
          info.imageSource = A_SNetworkImageSourceFileURL;
          [delegate imageNode:self didLoadImage:self.image info:info];
        } else if (_delegateFlags.delegateDidLoadImage) {
          A_SDN::MutexUnlocker u(__instanceLock__);
          [delegate imageNode:self didLoadImage:self.image];
        }
      });
    } else {
      __weak __typeof__(self) weakSelf = self;
      auto finished = ^(id <A_SImageContainerProtocol>imageContainer, NSError *error, id downloadIdentifier, A_SNetworkImageSource imageSource) {
       
        __typeof__(self) strongSelf = weakSelf;
        if (strongSelf == nil) {
          return;
        }

        as_log_verbose(A_SImageLoadingLog(), "Downloaded image for %@ img: %@ urls: %@", self, [imageContainer asdk_image], URLs);
        
        // Grab the lock for the rest of the block
        A_SDN::MutexLocker l(strongSelf->__instanceLock__);
        
        //Getting a result back for a different download identifier, download must not have been successfully canceled
        if (A_SObjectIsEqual(strongSelf->_downloadIdentifier, downloadIdentifier) == NO && downloadIdentifier != nil) {
          return;
        }
          
        //No longer in preload range, no point in setting the results (they won't be cleared in exit preload range)
        if (A_SInterfaceStateIncludesPreload(self->_interfaceState) == NO) {
          self->_downloadIdentifier = nil;
          self->_cacheUUID = nil;
          return;
        }

        if (imageContainer != nil) {
          [strongSelf _locked_setCurrentImageQuality:1.0];
          if ([imageContainer asdk_animatedImageData] && strongSelf->_downloaderFlags.downloaderImplementsAnimatedImage) {
            id animatedImage = [strongSelf->_downloader animatedImageWithData:[imageContainer asdk_animatedImageData]];
            [strongSelf _locked_setAnimatedImage:animatedImage];
          } else {
            [strongSelf _locked__setImage:[imageContainer asdk_image]];
          }
          strongSelf->_imageLoaded = YES;
        }

        strongSelf->_downloadIdentifier = nil;
        strongSelf->_cacheUUID = nil;

        if (imageContainer != nil) {
          if (strongSelf->_delegateFlags.delegateDidLoadImageWithInfo) {
            A_SDN::MutexUnlocker u(strongSelf->__instanceLock__);
            A_SNetworkImageNodeDidLoadInfo info = {};
            info.imageSource = imageSource;
            [delegate imageNode:strongSelf didLoadImage:strongSelf.image info:info];
          } else if (strongSelf->_delegateFlags.delegateDidLoadImage) {
            A_SDN::MutexUnlocker u(strongSelf->__instanceLock__);
            [delegate imageNode:strongSelf didLoadImage:strongSelf.image];
          }
        } else if (error && strongSelf->_delegateFlags.delegateDidFailWithError) {
          A_SDN::MutexUnlocker u(strongSelf->__instanceLock__);
          [delegate imageNode:strongSelf didFailWithError:error];
        }
      };

      // As the _cache and _downloader is only set once in the intializer we don't have to use a
      // lock in here
      if (_cache != nil) {
        NSUUID *cacheUUID = [NSUUID UUID];
        __instanceLock__.lock();
          _cacheUUID = cacheUUID;
        __instanceLock__.unlock();

        as_log_verbose(A_SImageLoadingLog(), "Decaching image for %@ urls: %@", self, URLs);
        
        A_SImageCacherCompletion completion = ^(id <A_SImageContainerProtocol> imageContainer) {
          // If the cache UUID changed, that means this request was cancelled.
          __instanceLock__.lock();
          NSUUID *currentCacheUUID = _cacheUUID;
          __instanceLock__.unlock();
          
          if (!A_SObjectIsEqual(currentCacheUUID, cacheUUID)) {
            return;
          }
          
          if ([imageContainer asdk_image] == nil && _downloader != nil) {
            [self _downloadImageWithCompletion:^(id<A_SImageContainerProtocol> imageContainer, NSError *error, id downloadIdentifier) {
              finished(imageContainer, error, downloadIdentifier, A_SNetworkImageSourceDownload);
            }];
          } else {
            as_log_verbose(A_SImageLoadingLog(), "Decached image for %@ img: %@ urls: %@", self, [imageContainer asdk_image], URLs);
            finished(imageContainer, nil, nil, A_SNetworkImageSourceAsynchronousCache);
          }
        };
        
        if (_cacheFlags.cacheSupportsCachedURLs) {
          [_cache cachedImageWithURLs:URLs
                        callbackQueue:dispatch_get_main_queue()
                           completion:completion];
        } else {
          [_cache cachedImageWithURL:[URLs lastObject]
                       callbackQueue:dispatch_get_main_queue()
                          completion:completion];
        }
      } else {
        [self _downloadImageWithCompletion:^(id<A_SImageContainerProtocol> imageContainer, NSError *error, id downloadIdentifier) {
          finished(imageContainer, error, downloadIdentifier, A_SNetworkImageSourceDownload);
        }];
      }
    }
  }
}

#pragma mark - A_SDisplayNode+Subclasses

- (void)displayDidFinish
{
  [super displayDidFinish];
  
  id<A_SNetworkImageNodeDelegate> delegate = nil;
  
  __instanceLock__.lock();
    if (_delegateFlags.delegateDidFinishDecoding && self.layer.contents != nil) {
      /* We store the image quality in _currentImageQuality whenever _image is set. On the following displayDidFinish, we'll know that
       _currentImageQuality is the quality of the image that has just finished rendering. In order for this to be accurate, we
       need to be sure we are on main thread when we set _currentImageQuality. Otherwise, it is possible for _currentImageQuality
       to be modified at a point where it is too late to cancel the main thread's previous display (the final sentinel check has passed), 
       but before the displayDidFinish of the previous display pass is called. In this situation, displayDidFinish would be called and we
       would set _renderedImageQuality to the new _currentImageQuality, but the actual quality of the rendered image should be the previous 
       value stored in _currentImageQuality. */

      _renderedImageQuality = _currentImageQuality;
      
      // Assign the delegate to be used
      delegate = _delegate;
    }
  
  __instanceLock__.unlock();
  
  if (delegate != nil) {
    [delegate imageNodeDidFinishDecoding:self];
  }
}

@end
