//
//  A_SPI_NRemoteImageDownloader.h
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

#import <Async_DisplayKit/A_SImageProtocols.h>

NS_ASSUME_NONNULL_BEGIN

@class PI_NRemoteImageManager;

@interface A_SPI_NRemoteImageDownloader : NSObject <A_SImageCacheProtocol, A_SImageDownloaderProtocol>

/**
 * A shared image downloader which can be used by @c A_SNetworkImageNodes and @c A_SMultiplexImageNodes
 *
 * This is the default downloader used by network backed image nodes if PI_NRemoteImage and PI_NCache are
 * available. It uses PI_NRemoteImage's features to provide caching and progressive image downloads.
 */
+ (A_SPI_NRemoteImageDownloader *)sharedDownloader;


/**
 * Sets the default NSURLSessionConfiguration that will be used by @c A_SNetworkImageNodes and @c A_SMultiplexImageNodes
 * while loading images off the network. This must be specified early in the application lifecycle before
 * `sharedDownloader` is accessed.
 *
 * @param configuration The session configuration that will be used by `sharedDownloader`
 *
 */
+ (void)setSharedImageManagerWithConfiguration:(nullable NSURLSessionConfiguration *)configuration;

/**
 * The shared instance of a @c PI_NRemoteImageManager used by all @c A_SPI_NRemoteImageDownloaders
 *
 * @discussion you can use this method to access the shared manager. This is useful to share a cache
 * and resources if you need to download images outside of an @c A_SNetworkImageNode or 
 * @c A_SMultiplexImageNode. It's also useful to access the memoryCache and diskCache to set limits
 * or handle authentication challenges.
 *
 * @return An instance of a @c PI_NRemoteImageManager
 */
- (PI_NRemoteImageManager *)sharedPI_NRemoteImageManager;

@end

NS_ASSUME_NONNULL_END

#endif
