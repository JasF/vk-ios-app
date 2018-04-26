//
//  A_SMultiplexImageNode.mm
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

#import <Async_DisplayKit/A_SMultiplexImageNode.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import <Async_DisplayKit/A_SAvailability.h>
#import <Async_DisplayKit/A_SDisplayNode+FrameworkSubclasses.h>
#import <Async_DisplayKit/A_SDisplayNodeExtras.h>
#import <Async_DisplayKit/A_SPhotosFrameworkImageRequest.h>
#import <Async_DisplayKit/A_SEqualityHelpers.h>
#import <Async_DisplayKit/A_SInternalHelpers.h>
#import <Async_DisplayKit/A_SLog.h>

#if A_S_PI_N_REMOTE_IMAGE
#import <Async_DisplayKit/A_SPI_NRemoteImageDownloader.h>
#else
#import <Async_DisplayKit/A_SBasicImageDownloader.h>
#endif

NSString *const A_SMultiplexImageNodeErrorDomain = @"A_SMultiplexImageNodeErrorDomain";

static NSString *const kAssetsLibraryURLScheme = @"assets-library";

static const CGSize kMinReleaseImageOnBackgroundSize = {20.0, 20.0};

/**
  @abstract Signature for the block to be performed after an image has loaded.
  @param image The image that was loaded, or nil if no image was loaded.
  @param imageIdentifier The identifier of the image that was loaded, or nil if no image was loaded.
  @param error An error describing why an image couldn't be loaded, if it failed to load; nil otherwise.
 */
typedef void(^A_SMultiplexImageLoadCompletionBlock)(UIImage *image, id imageIdentifier, NSError *error);

@interface A_SMultiplexImageNode ()
{
@private
  // Core.
  id<A_SImageCacheProtocol> _cache;
  id<A_SImageDownloaderProtocol> _downloader;

  __weak id<A_SMultiplexImageNodeDelegate> _delegate;
  struct {
    unsigned int downloadStart:1;
    unsigned int downloadProgress:1;
    unsigned int downloadFinish:1;
    unsigned int updatedImageDisplayFinish:1;
    unsigned int updatedImage:1;
    unsigned int displayFinish:1;
  } _delegateFlags;

  __weak id<A_SMultiplexImageNodeDataSource> _dataSource;
  struct {
    unsigned int image:1;
    unsigned int URL:1;
    unsigned int asset:1;
  } _dataSourceFlags;

  // Image flags.
  BOOL _downloadsIntermediateImages; // Defaults to NO.
  A_SDN::Mutex _imageIdentifiersLock;
  NSArray *_imageIdentifiers;
  id _loadedImageIdentifier;
  id _loadingImageIdentifier;
  id _displayedImageIdentifier;
  __weak NSOperation *_phImageRequestOperation;
  
  // Networking.
  A_SDN::RecursiveMutex _downloadIdentifierLock;
  id _downloadIdentifier;
  
  // Properties
  BOOL _shouldRenderProgressImages;
  
  //set on init only
  BOOL _downloaderImplementsSetProgress;
  BOOL _downloaderImplementsSetPriority;
  BOOL _cacheSupportsClearing;
}

//! @abstract Read-write redeclaration of property declared in A_SMultiplexImageNode.h.
@property (nonatomic, readwrite, copy) id loadedImageIdentifier;

//! @abstract The image identifier that's being loaded by _loadNextImageWithCompletion:.
@property (nonatomic, readwrite, copy) id loadingImageIdentifier;

/**
  @abstract Returns the next image identifier that should be downloaded.
  @discussion This method obeys and reflects the value of `downloadsIntermediateImages`.
  @result The next image identifier, from `_imageIdentifiers`, that should be downloaded, or nil if no image should be downloaded next.
 */
- (id)_nextImageIdentifierToDownload;

/**
  @abstract Returns the best image that is immediately available from our datasource without downloading or hitting the cache.
  @param imageIdentifierOut Upon return, the image identifier for the returned image; nil otherwise.
  @discussion This method exclusively uses the data source's -multiplexImageNode:imageForIdentifier: method to return images. It does not fetch from the cache or kick off downloading.
  @result The best UIImage available immediately; nil if no image is immediately available.
 */
- (UIImage *)_bestImmediatelyAvailableImageFromDataSource:(id *)imageIdentifierOut;

/**
  @abstract Loads and displays the next image in the receiver's loading sequence.
  @discussion This method obeys `downloadsIntermediateImages`. This method has no effect if nothing further should be loaded, as indicated by `_nextImageIdentifierToDownload`. This method will load the next image from the data-source, if possible; otherwise, the session's image cache will be queried for the desired image, and as a last resort, the image will be downloaded.
 */
- (void)_loadNextImage;

/**
  @abstract Fetches the image corresponding to the given imageIdentifier from the given URL from the session's image cache.
  @param imageIdentifier The identifier for the image to be fetched. May not be nil.
  @param imageURL The URL of the image to fetch. May not be nil.
  @param completionBlock The block to be performed when the image has been fetched from the cache, if possible. May not be nil.
  @discussion This method queries both the session's in-memory and on-disk caches (with preference for the in-memory cache).
 */
- (void)_fetchImageWithIdentifierFromCache:(id)imageIdentifier URL:(NSURL *)imageURL completion:(void (^)(UIImage *image))completionBlock;

#if TARGET_OS_IOS
/**
  @abstract Loads the image corresponding to the given assetURL from the device's Assets Library.
  @param imageIdentifier The identifier for the image to be loaded. May not be nil.
  @param assetURL The assets-library URL (e.g., "assets-library://identifier") of the image to load, from ALAsset. May not be nil.
  @param completionBlock The block to be performed when the image has been loaded, if possible. May not be nil.
 */
- (void)_loadALAssetWithIdentifier:(id)imageIdentifier URL:(NSURL *)assetURL completion:(void (^)(UIImage *image, NSError *error))completionBlock;

/**
  @abstract Loads the image corresponding to the given image request from the Photos framework.
  @param imageIdentifier The identifier for the image to be loaded. May not be nil.
  @param request The photos image request to load. May not be nil.
  @param completionBlock The block to be performed when the image has been loaded, if possible. May not be nil.
 */
- (void)_loadPHAssetWithRequest:(A_SPhotosFrameworkImageRequest *)request identifier:(id)imageIdentifier completion:(void (^)(UIImage *image, NSError *error))completionBlock;
#endif
/**
 @abstract Downloads the image corresponding to the given imageIdentifier from the given URL.
 @param imageIdentifier The identifier for the image to be downloaded. May not be nil.
 @param imageURL The URL of the image to downloaded. May not be nil.
 @param completionBlock The block to be performed when the image has been downloaded, if possible. May not be nil.
 */
- (void)_downloadImageWithIdentifier:(id)imageIdentifier URL:(NSURL *)imageURL completion:(void (^)(UIImage *image, NSError *error))completionBlock;

@end

@implementation A_SMultiplexImageNode

#pragma mark - Getting Started / Tearing Down
- (instancetype)initWithCache:(id<A_SImageCacheProtocol>)cache downloader:(id<A_SImageDownloaderProtocol>)downloader
{
  if (!(self = [super init]))
    return nil;

  _cache = (id<A_SImageCacheProtocol>)cache;
  _downloader = (id<A_SImageDownloaderProtocol>)downloader;
  
  _downloaderImplementsSetProgress = [downloader respondsToSelector:@selector(setProgressImageBlock:callbackQueue:withDownloadIdentifier:)];
  _downloaderImplementsSetPriority = [downloader respondsToSelector:@selector(setPriority:withDownloadIdentifier:)];

  _cacheSupportsClearing = [cache respondsToSelector:@selector(clearFetchedImageFromCacheWithURL:)];
  
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
  [_phImageRequestOperation cancel];
}

#pragma mark - A_SDisplayNode Overrides

- (void)clearContents
{
  [super clearContents]; // This actually clears the contents, so we need to do this first for our displayedImageIdentifier to be meaningful.
  [self _setDisplayedImageIdentifier:nil withImage:nil];

  // NOTE: We intentionally do not cancel image downloads until `clearPreloadedData`.
}

- (void)didExitPreloadState
{
  [super didExitPreloadState];
    
  [_phImageRequestOperation cancel];

  [self _setDownloadIdentifier:nil];
  
  if (_cacheSupportsClearing && self.loadedImageIdentifier != nil) {
    NSURL *URL = [_dataSource multiplexImageNode:self URLForImageIdentifier:self.loadedImageIdentifier];
    if (URL != nil) {
      [_cache clearFetchedImageFromCacheWithURL:URL];
    }
  }

  // setting this to nil makes the node fetch images the next time its display starts
  _loadedImageIdentifier = nil;
  [self _setImage:nil];
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];

  [self _loadImageIdentifiers];
}

- (void)displayDidFinish
{
  [super displayDidFinish];

  // We may now be displaying the loaded identifier, if they're different.
  UIImage *displayedImage = self.image;
  if (displayedImage) {
    if (!A_SObjectIsEqual(_displayedImageIdentifier, _loadedImageIdentifier))
      [self _setDisplayedImageIdentifier:_loadedImageIdentifier withImage:displayedImage];

    // Delegateify
    if (_delegateFlags.displayFinish) {
      if (A_SDisplayNodeThreadIsMain())
        [_delegate multiplexImageNodeDidFinishDisplay:self];
      else {
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          __typeof__(self) strongSelf = weakSelf;
          if (!strongSelf)
            return;
          [strongSelf.delegate multiplexImageNodeDidFinishDisplay:strongSelf];
        });
      }
    }
  }
}

- (BOOL)placeholderShouldPersist
{
  return (self.image == nil && self.animatedImage == nil && self.imageIdentifiers.count > 0);
}

/* displayWillStartAsynchronously in A_SNetworkImageNode has a very similar implementation. Changes here are likely necessary
 in A_SNetworkImageNode as well. */
- (void)displayWillStartAsynchronously:(BOOL)asynchronously
{
  [super displayWillStartAsynchronously:asynchronously];
  
  [self didEnterPreloadState];
  
  if (_downloaderImplementsSetPriority) {
    {
      A_SDN::MutexLocker l(_downloadIdentifierLock);
      if (_downloadIdentifier != nil) {
        [_downloader setPriority:A_SImageDownloaderPriorityImminent withDownloadIdentifier:_downloadIdentifier];
      }
    }
  }
}

/* didEnterVisibleState / didExitVisibleState in A_SNetworkImageNode has a very similar implementation. Changes here are likely necessary
 in A_SNetworkImageNode as well. */
- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  
  if (_downloaderImplementsSetPriority) {
    A_SDN::MutexLocker l(_downloadIdentifierLock);
    if (_downloadIdentifier != nil) {
      [_downloader setPriority:A_SImageDownloaderPriorityVisible withDownloadIdentifier:_downloadIdentifier];
    }
  }
  
  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  
  if (_downloaderImplementsSetPriority) {
    A_SDN::MutexLocker l(_downloadIdentifierLock);
    if (_downloadIdentifier != nil) {
      [_downloader setPriority:A_SImageDownloaderPriorityPreload withDownloadIdentifier:_downloadIdentifier];
    }
  }
  
  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

#pragma mark - Core

- (void)setImage:(UIImage *)image
{
  A_SDisplayNodeAssert(NO, @"Setting the image directly on an A_SMultiplexImageNode is unsafe. It will be cleared in didExitPreloadRange and will have no way to restore in didEnterPreloadRange");
  super.image = image;
}

- (void)_setImage:(UIImage *)image
{
  super.image = image;
}

- (void)setDelegate:(id <A_SMultiplexImageNodeDelegate>)delegate
{
  if (_delegate == delegate)
    return;

  _delegate = delegate;
  _delegateFlags.downloadStart = [_delegate respondsToSelector:@selector(multiplexImageNode:didStartDownloadOfImageWithIdentifier:)];
  _delegateFlags.downloadProgress = [_delegate respondsToSelector:@selector(multiplexImageNode:didUpdateDownloadProgress:forImageWithIdentifier:)];
  _delegateFlags.downloadFinish = [_delegate respondsToSelector:@selector(multiplexImageNode:didFinishDownloadingImageWithIdentifier:error:)];
  _delegateFlags.updatedImageDisplayFinish = [_delegate respondsToSelector:@selector(multiplexImageNode:didDisplayUpdatedImage:withIdentifier:)];
  _delegateFlags.updatedImage = [_delegate respondsToSelector:@selector(multiplexImageNode:didUpdateImage:withIdentifier:fromImage:withIdentifier:)];
  _delegateFlags.displayFinish = [_delegate respondsToSelector:@selector(multiplexImageNodeDidFinishDisplay:)];
}


- (void)setDataSource:(id <A_SMultiplexImageNodeDataSource>)dataSource
{
  if (_dataSource == dataSource)
    return;

  _dataSource = dataSource;
  _dataSourceFlags.image = [_dataSource respondsToSelector:@selector(multiplexImageNode:imageForImageIdentifier:)];
  _dataSourceFlags.URL = [_dataSource respondsToSelector:@selector(multiplexImageNode:URLForImageIdentifier:)];
  #if TARGET_OS_IOS
  _dataSourceFlags.asset = [_dataSource respondsToSelector:@selector(multiplexImageNode:assetForLocalIdentifier:)];
  #endif
}


- (void)setShouldRenderProgressImages:(BOOL)shouldRenderProgressImages
{
  __instanceLock__.lock();
  if (shouldRenderProgressImages == _shouldRenderProgressImages) {
    __instanceLock__.unlock();
    return;
  }
  
  _shouldRenderProgressImages = shouldRenderProgressImages;
  
  
  __instanceLock__.unlock();
  [self _updateProgressImageBlockOnDownloaderIfNeeded];
}

- (BOOL)shouldRenderProgressImages
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _shouldRenderProgressImages;
}

#pragma mark -

#pragma mark -

- (NSArray *)imageIdentifiers
{
  A_SDN::MutexLocker l(_imageIdentifiersLock);
  return _imageIdentifiers;
}

- (void)setImageIdentifiers:(NSArray *)imageIdentifiers
{
  {
    A_SDN::MutexLocker l(_imageIdentifiersLock);
    if (A_SObjectIsEqual(_imageIdentifiers, imageIdentifiers)) {
      return;
    }

    _imageIdentifiers = [[NSArray alloc] initWithArray:imageIdentifiers copyItems:YES];
  }

  [self setNeedsPreload];
}

- (void)reloadImageIdentifierSources
{
  // setting this to nil makes the node think it has not downloaded any images
  _loadedImageIdentifier = nil;
  [self _loadImageIdentifiers];
}

#pragma mark -


#pragma mark - Core Internal
- (void)_setDisplayedImageIdentifier:(id)displayedImageIdentifier withImage:(UIImage *)image
{
  if (A_SObjectIsEqual(displayedImageIdentifier, _displayedImageIdentifier))
    return;

  _displayedImageIdentifier = displayedImageIdentifier;

  // Delegateify.
  // Note that we're using the params here instead of self.image and _displayedImageIdentifier because those can change before the async block below executes.
  if (_delegateFlags.updatedImageDisplayFinish) {
    if (A_SDisplayNodeThreadIsMain())
      [_delegate multiplexImageNode:self didDisplayUpdatedImage:image withIdentifier:displayedImageIdentifier];
    else {
      __weak __typeof__(self) weakSelf = self;
      dispatch_async(dispatch_get_main_queue(), ^{
        __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf)
          return;
        [strongSelf.delegate multiplexImageNode:strongSelf didDisplayUpdatedImage:image withIdentifier:displayedImageIdentifier];
      });
    }
  }
}

- (void)_setDownloadIdentifier:(id)downloadIdentifier
{
  A_SDN::MutexLocker l(_downloadIdentifierLock);
  if (A_SObjectIsEqual(downloadIdentifier, _downloadIdentifier))
    return;

  if (_downloadIdentifier) {
    [_downloader cancelImageDownloadForIdentifier:_downloadIdentifier];
  }
  _downloadIdentifier = downloadIdentifier;
}


#pragma mark - Image Loading Machinery

- (void)_loadImageIdentifiers
{
  // Grab the best possible image we can load right now.
  id bestImmediatelyAvailableImageIdentifier = nil;
  UIImage *bestImmediatelyAvailableImage = [self _bestImmediatelyAvailableImageFromDataSource:&bestImmediatelyAvailableImageIdentifier];
  as_log_verbose(A_SImageLoadingLog(), "%@ Best immediately available image identifier is %@", self, bestImmediatelyAvailableImageIdentifier);

  // Load it. This kicks off cache fetching/downloading, as appropriate.
  [self _finishedLoadingImage:bestImmediatelyAvailableImage forIdentifier:bestImmediatelyAvailableImageIdentifier error:nil];
}

- (UIImage *)_bestImmediatelyAvailableImageFromDataSource:(id *)imageIdentifierOut
{
  A_SDN::MutexLocker l(_imageIdentifiersLock);

  // If we don't have any identifiers to load or don't implement the image DS method, bail.
  if ([_imageIdentifiers count] == 0 || !_dataSourceFlags.image) {
    return nil;
  }

  // Grab the best available image from the data source.
  UIImage *existingImage = self.image;
  for (id imageIdentifier in _imageIdentifiers) {
    // If this image is already loaded, don't request it from the data source again because
    // the data source may generate a new instance of UIImage that returns NO for isEqual:
    // and we'll end up in an infinite loading loop.
    UIImage *image = A_SObjectIsEqual(imageIdentifier, _loadedImageIdentifier) ? existingImage : [_dataSource multiplexImageNode:self imageForImageIdentifier:imageIdentifier];
    if (image) {
      if (imageIdentifierOut) {
        *imageIdentifierOut = imageIdentifier;
      }

      return image;
    }
  }

  return nil;
}

#pragma mark -

/**
 @note: This should be called without _downloadIdentifierLock held. We will lock
 super to read our interface state and it's best to avoid acquiring both locks.
 */
- (void)_updateProgressImageBlockOnDownloaderIfNeeded
{
  BOOL shouldRenderProgressImages = self.shouldRenderProgressImages;
  
  // Read our interface state before locking so that we don't lock super while holding our lock.
  A_SInterfaceState interfaceState = self.interfaceState;
  A_SDN::MutexLocker l(_downloadIdentifierLock);
  
  if (!_downloaderImplementsSetProgress || _downloadIdentifier == nil) {
    return;
  }
  
  A_SImageDownloaderProgressImage progress = nil;
  if (shouldRenderProgressImages && A_SInterfaceStateIncludesVisible(interfaceState)) {
    __weak __typeof__(self) weakSelf = self;
    progress = ^(UIImage * _Nonnull progressImage, CGFloat progress, id _Nullable downloadIdentifier) {
      __typeof__(self) strongSelf = weakSelf;
      if (strongSelf == nil) {
        return;
      }
      
      A_SDN::MutexLocker l(strongSelf->_downloadIdentifierLock);
      //Getting a result back for a different download identifier, download must not have been successfully canceled
      if (A_SObjectIsEqual(strongSelf->_downloadIdentifier, downloadIdentifier) == NO && downloadIdentifier != nil) {
        return;
      }
      [strongSelf _setImage:progressImage];
    };
  }
  [_downloader setProgressImageBlock:progress callbackQueue:dispatch_get_main_queue() withDownloadIdentifier:_downloadIdentifier];
}

- (void)_clearImage
{
  // Destruction of bigger images on the main thread can be expensive
  // and can take some time, so we dispatch onto a bg queue to
  // actually dealloc.
  UIImage *image = self.image;
  CGSize imageSize = image.size;
  BOOL shouldReleaseImageOnBackgroundThread = imageSize.width > kMinReleaseImageOnBackgroundSize.width ||
  imageSize.height > kMinReleaseImageOnBackgroundSize.height;
  [self _setImage:nil];
  if (shouldReleaseImageOnBackgroundThread) {
    A_SPerformBackgroundDeallocation(&image);
  }
}

#pragma mark -
- (id)_nextImageIdentifierToDownload
{
  A_SDN::MutexLocker l(_imageIdentifiersLock);

  // If we've already loaded the best identifier, we've got nothing else to do.
  id bestImageIdentifier = _imageIdentifiers.firstObject;
  if (!bestImageIdentifier || A_SObjectIsEqual(_loadedImageIdentifier, bestImageIdentifier)) {
    return nil;
  }

  id nextImageIdentifierToDownload = nil;

  // If we're not supposed to download intermediate images, load the best identifier we've got.
  if (!_downloadsIntermediateImages) {
    nextImageIdentifierToDownload = bestImageIdentifier;
  }
  // Otherwise, load progressively.
  else {
    NSUInteger loadedIndex = [_imageIdentifiers indexOfObject:_loadedImageIdentifier];

    // If nothing has loaded yet, load the worst identifier.
    if (loadedIndex == NSNotFound) {
      nextImageIdentifierToDownload = [_imageIdentifiers lastObject];
    }
    // Otherwise, load the next best identifier (if there is one)
    else if (loadedIndex > 0) {
      nextImageIdentifierToDownload = _imageIdentifiers[loadedIndex - 1];
    }
  }

  return nextImageIdentifierToDownload;
}

- (void)_loadNextImage
{
  // Determine the next identifier to load (if any).
  id nextImageIdentifier = [self _nextImageIdentifierToDownload];
  if (!nextImageIdentifier) {
    [self _finishedLoadingImage:nil forIdentifier:nil error:nil];
    return;
  }

  as_activity_create_for_scope("Load next image for multiplex image node");
  as_log_verbose(A_SImageLoadingLog(), "Loading image for %@ ident: %@", self, nextImageIdentifier);
  self.loadingImageIdentifier = nextImageIdentifier;

  __weak __typeof__(self) weakSelf = self;
  A_SMultiplexImageLoadCompletionBlock finishedLoadingBlock = ^(UIImage *image, id imageIdentifier, NSError *error) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf)
      return;

    // Only nil out the loading identifier if the loading identifier hasn't changed.
    if (A_SObjectIsEqual(strongSelf.loadingImageIdentifier, nextImageIdentifier)) {
      strongSelf.loadingImageIdentifier = nil;
    }
    [strongSelf _finishedLoadingImage:image forIdentifier:imageIdentifier error:error];
  };

  // Ask our data-source if it's got this image.
  if (_dataSourceFlags.image) {
    UIImage *image = [_dataSource multiplexImageNode:self imageForImageIdentifier:nextImageIdentifier];
    if (image) {
      as_log_verbose(A_SImageLoadingLog(), "Acquired image from data source for %@ ident: %@", self, nextImageIdentifier);
      finishedLoadingBlock(image, nextImageIdentifier, nil);
      return;
    }
  }

  NSURL *nextImageURL = (_dataSourceFlags.URL) ? [_dataSource multiplexImageNode:self URLForImageIdentifier:nextImageIdentifier] : nil;
  // If we fail to get a URL for the image, we have no source and can't proceed.
  if (!nextImageURL) {
    as_log_error(A_SImageLoadingLog(), "Could not acquire URL %@ ident: (%@)", self, nextImageIdentifier);
    finishedLoadingBlock(nil, nil, [NSError errorWithDomain:A_SMultiplexImageNodeErrorDomain code:A_SMultiplexImageNodeErrorCodeNoSourceForImage userInfo:nil]);
    return;
  }

  #if TARGET_OS_IOS
  // If it's an assets-library URL, we need to fetch it from the assets library.
  if ([[nextImageURL scheme] isEqualToString:kAssetsLibraryURLScheme]) {
    // Load the asset.
    [self _loadALAssetWithIdentifier:nextImageIdentifier URL:nextImageURL completion:^(UIImage *downloadedImage, NSError *error) {
      as_log_verbose(A_SImageLoadingLog(), "Acquired image from assets library for %@ %@", weakSelf, nextImageIdentifier);
      finishedLoadingBlock(downloadedImage, nextImageIdentifier, error);
    }];
  }
  // Likewise, if it's a iOS 8 Photo asset, we need to fetch it accordingly.
  else if (A_SPhotosFrameworkImageRequest *request = [A_SPhotosFrameworkImageRequest requestWithURL:nextImageURL]) {
    [self _loadPHAssetWithRequest:request identifier:nextImageIdentifier completion:^(UIImage *image, NSError *error) {
      as_log_verbose(A_SImageLoadingLog(), "Acquired image from Photos for %@ %@", weakSelf, nextImageIdentifier);
      finishedLoadingBlock(image, nextImageIdentifier, error);
    }];
  }
  #endif
  else // Otherwise, it's a web URL that we can download.
  {
    // First, check the cache.
    [self _fetchImageWithIdentifierFromCache:nextImageIdentifier URL:nextImageURL completion:^(UIImage *imageFromCache) {
      __typeof__(self) strongSelf = weakSelf;
      if (!strongSelf)
        return;

      // If we had a cache-hit, we're done.
      if (imageFromCache) {
        as_log_verbose(A_SImageLoadingLog(), "Acquired image from cache for %@ id: %@ img: %@", strongSelf, nextImageIdentifier, imageFromCache);
        finishedLoadingBlock(imageFromCache, nextImageIdentifier, nil);
        return;
      }

      // If the next image to load has changed, bail.
      if (!A_SObjectIsEqual([strongSelf _nextImageIdentifierToDownload], nextImageIdentifier)) {
        finishedLoadingBlock(nil, nil, [NSError errorWithDomain:A_SMultiplexImageNodeErrorDomain code:A_SMultiplexImageNodeErrorCodeBestImageIdentifierChanged userInfo:nil]);
        return;
      }

      // Otherwise, we've got to download it.
      [strongSelf _downloadImageWithIdentifier:nextImageIdentifier URL:nextImageURL completion:^(UIImage *downloadedImage, NSError *error) {
        __typeof__(self) strongSelf = weakSelf;
        if (downloadedImage) {
          as_log_verbose(A_SImageLoadingLog(), "Acquired image from download for %@ id: %@ img: %@", strongSelf, nextImageIdentifier, downloadedImage);
        } else {
          as_log_error(A_SImageLoadingLog(), "Error downloading image for %@ id: %@ err: %@", strongSelf, nextImageIdentifier, error);
        }
        finishedLoadingBlock(downloadedImage, nextImageIdentifier, error);
      }];
    }];
  }
}
#if TARGET_OS_IOS
- (void)_loadALAssetWithIdentifier:(id)imageIdentifier URL:(NSURL *)assetURL completion:(void (^)(UIImage *image, NSError *error))completionBlock
{
  A_SDisplayNodeAssertNotNil(imageIdentifier, @"imageIdentifier is required");
  A_SDisplayNodeAssertNotNil(assetURL, @"assetURL is required");
  A_SDisplayNodeAssertNotNil(completionBlock, @"completionBlock is required");

  ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];

  [assetLibrary assetForURL:assetURL resultBlock:^(ALAsset *asset) {
    ALAssetRepresentation *representation = [asset defaultRepresentation];
    CGImageRef coreGraphicsImage = [representation fullScreenImage];

    UIImage *downloadedImage = (coreGraphicsImage ? [UIImage imageWithCGImage:coreGraphicsImage] : nil);
    completionBlock(downloadedImage, nil);
  } failureBlock:^(NSError *error) {
    completionBlock(nil, error);
  }];
}

- (void)_loadPHAssetWithRequest:(A_SPhotosFrameworkImageRequest *)request identifier:(id)imageIdentifier completion:(void (^)(UIImage *image, NSError *error))completionBlock
{
  A_SDisplayNodeAssertNotNil(imageIdentifier, @"imageIdentifier is required");
  A_SDisplayNodeAssertNotNil(request, @"request is required");
  A_SDisplayNodeAssertNotNil(completionBlock, @"completionBlock is required");
  
  /*
   * Locking rationale:
   * As of iOS 9, Photos.framework will eventually deadlock if you hit it with concurrent fetch requests. rdar://22984886
   * Concurrent image requests are OK, but metadata requests aren't, so we limit ourselves to one at a time.
   */
  static NSLock *phRequestLock;
  static NSOperationQueue *phImageRequestQueue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    phRequestLock = [NSLock new];
    phImageRequestQueue = [NSOperationQueue new];
    phImageRequestQueue.maxConcurrentOperationCount = 10;
    phImageRequestQueue.name = @"org.Async_DisplayKit.MultiplexImageNode.phImageRequestQueue";
  });
  
  // Each A_SMultiplexImageNode can have max 1 inflight Photos image request operation
  [_phImageRequestOperation cancel];
  
  __weak __typeof(self) weakSelf = self;
  NSOperation *newImageRequestOp = [NSBlockOperation blockOperationWithBlock:^{
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf == nil) { return; }
    
    PHAsset *imageAsset = nil;
    
    // Try to get the asset immediately from the data source.
    if (_dataSourceFlags.asset) {
      imageAsset = [strongSelf.dataSource multiplexImageNode:strongSelf assetForLocalIdentifier:request.assetIdentifier];
    }
    
    // Fall back to locking and getting the PHAsset.
    if (imageAsset == nil) {
      [phRequestLock lock];
      // -[PHFetchResult dealloc] plays a role in the deadlock mentioned above, so we make sure the PHFetchResult is deallocated inside the critical section
      @autoreleasepool {
        imageAsset = [PHAsset fetchAssetsWithLocalIdentifiers:@[request.assetIdentifier] options:nil].firstObject;
      }
      [phRequestLock unlock];
    }
    
    if (imageAsset == nil) {
      NSError *error = [NSError errorWithDomain:A_SMultiplexImageNodeErrorDomain code:A_SMultiplexImageNodeErrorCodePHAssetIsUnavailable userInfo:nil];
      completionBlock(nil, error);
      return;
    }
    
    PHImageRequestOptions *options = [request.options copy];
    
    // We don't support opportunistic delivery – one request, one image.
    if (options.deliveryMode == PHImageRequestOptionsDeliveryModeOpportunistic) {
      options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    }
    
    if (options.deliveryMode == PHImageRequestOptionsDeliveryModeHighQualityFormat) {
      // Without this flag the result will be delivered on the main queue, which is pointless
      // But synchronous -> HighQualityFormat so we only use it if high quality format is specified
      options.synchronous = YES;
    }
    
    PHImageManager *imageManager = strongSelf.imageManager ? : PHImageManager.defaultManager;
    [imageManager requestImageForAsset:imageAsset targetSize:request.targetSize contentMode:request.contentMode options:options resultHandler:^(UIImage *image, NSDictionary *info) {
      NSError *error = info[PHImageErrorKey];
      
      if (error == nil && image == nil) {
        error = [NSError errorWithDomain:A_SMultiplexImageNodeErrorDomain code:A_SMultiplexImageNodeErrorCodePhotosImageManagerFailedWithoutError userInfo:nil];
      }
      
      if (NSThread.isMainThread) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
          completionBlock(image, error);
        });
      } else {
        completionBlock(image, error);
      }
    }];
  }];
  // If you don't set this, iOS will sometimes infer NSQualityOfServiceUserInteractive and promote the entire queue to that level, damaging system responsiveness
  newImageRequestOp.qualityOfService = NSQualityOfServiceUserInitiated;
  _phImageRequestOperation = newImageRequestOp;
  [phImageRequestQueue addOperation:newImageRequestOp];
}
#endif
- (void)_fetchImageWithIdentifierFromCache:(id)imageIdentifier URL:(NSURL *)imageURL completion:(void (^)(UIImage *image))completionBlock
{
  A_SDisplayNodeAssertNotNil(imageIdentifier, @"imageIdentifier is required");
  A_SDisplayNodeAssertNotNil(imageURL, @"imageURL is required");
  A_SDisplayNodeAssertNotNil(completionBlock, @"completionBlock is required");

  if (_cache) {
    [_cache cachedImageWithURL:imageURL callbackQueue:dispatch_get_main_queue() completion:^(id <A_SImageContainerProtocol> imageContainer) {
      completionBlock([imageContainer asdk_image]);
    }];
  }
  // If we don't have a cache, just fail immediately.
  else {
    completionBlock(nil);
  }
}

- (void)_downloadImageWithIdentifier:(id)imageIdentifier URL:(NSURL *)imageURL completion:(void (^)(UIImage *image, NSError *error))completionBlock
{
  A_SDisplayNodeAssertNotNil(imageIdentifier, @"imageIdentifier is required");
  A_SDisplayNodeAssertNotNil(imageURL, @"imageURL is required");
  A_SDisplayNodeAssertNotNil(completionBlock, @"completionBlock is required");

  // Delegate (start)
  if (_delegateFlags.downloadStart)
    [_delegate multiplexImageNode:self didStartDownloadOfImageWithIdentifier:imageIdentifier];

  __weak __typeof__(self) weakSelf = self;
  void (^downloadProgressBlock)(CGFloat) = nil;
  if (_delegateFlags.downloadProgress) {
    downloadProgressBlock = ^(CGFloat progress) {
      __typeof__(self) strongSelf = weakSelf;
      if (!strongSelf)
        return;
      [strongSelf.delegate multiplexImageNode:strongSelf didUpdateDownloadProgress:progress forImageWithIdentifier:imageIdentifier];
    };
  }

  // Download!
  A_SPerformBlockOnBackgroundThread(^{
    [self _setDownloadIdentifier:[_downloader downloadImageWithURL:imageURL
                                                     callbackQueue:dispatch_get_main_queue()
                                                  downloadProgress:downloadProgressBlock
                                                        completion:^(id <A_SImageContainerProtocol> imageContainer, NSError *error, id downloadIdentifier) {
                                                          // We dereference iVars directly, so we can't have weakSelf going nil on us.
                                                          __typeof__(self) strongSelf = weakSelf;
                                                          if (!strongSelf)
                                                            return;
                                                          
                                                          A_SDN::MutexLocker l(_downloadIdentifierLock);
                                                          //Getting a result back for a different download identifier, download must not have been successfully canceled
                                                          if (A_SObjectIsEqual(_downloadIdentifier, downloadIdentifier) == NO && downloadIdentifier != nil) {
                                                            return;
                                                          }
                                                          
                                                          completionBlock([imageContainer asdk_image], error);
                                                          
                                                          // Delegateify.
                                                          if (strongSelf->_delegateFlags.downloadFinish)
                                                            [strongSelf->_delegate multiplexImageNode:weakSelf didFinishDownloadingImageWithIdentifier:imageIdentifier error:error];
                                                        }]];
    [self _updateProgressImageBlockOnDownloaderIfNeeded];
  });
}

#pragma mark -
- (void)_finishedLoadingImage:(UIImage *)image forIdentifier:(id)imageIdentifier error:(NSError *)error
{
  // If we failed to load, we stop the loading process.
  // Note that if we bailed before we began downloading because the best identifier changed, we don't bail, but rather just begin loading the best image identifier.
  if (error && !([error.domain isEqual:A_SMultiplexImageNodeErrorDomain] && error.code == A_SMultiplexImageNodeErrorCodeBestImageIdentifierChanged))
    return;


  _imageIdentifiersLock.lock();
  NSUInteger imageIdentifierCount = [_imageIdentifiers count];
  _imageIdentifiersLock.unlock();

  // Update our image if we got one, or if we're not supposed to display one at all.
  // We explicitly perform this check because our datasource often doesn't give back immediately available images, even though we might have downloaded one already.
  // Because we seed this call with bestImmediatelyAvailableImageFromDataSource, we must be careful not to trample an existing image.
  if (image || imageIdentifierCount == 0) {
    as_log_verbose(A_SImageLoadingLog(), "[%p] loaded -> displaying (%@, %@)", self, imageIdentifier, image);
    id previousIdentifier = self.loadedImageIdentifier;
    UIImage *previousImage = self.image;

    self.loadedImageIdentifier = imageIdentifier;
    [self _setImage:image];

    if (_delegateFlags.updatedImage) {
      [_delegate multiplexImageNode:self didUpdateImage:image withIdentifier:imageIdentifier fromImage:previousImage withIdentifier:previousIdentifier];
    }

  }

  // Load our next image, if we have one to load.
  if ([self _nextImageIdentifierToDownload])
    [self _loadNextImage];
}

@end

@implementation NSURL (A_SPhotosFrameworkURLs)

+ (NSURL *)URLWithAssetLocalIdentifier:(NSString *)assetLocalIdentifier targetSize:(CGSize)targetSize contentMode:(PHImageContentMode)contentMode options:(PHImageRequestOptions *)options
{
  A_SPhotosFrameworkImageRequest *request = [[A_SPhotosFrameworkImageRequest alloc] initWithAssetIdentifier:assetLocalIdentifier];
  request.options = options;
  request.contentMode = contentMode;
  request.targetSize = targetSize;
  return request.url;
}

@end
