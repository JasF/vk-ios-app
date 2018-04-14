//
//  A_SBasicImageDownloader.h
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

#import <Async_DisplayKit/A_SImageProtocols.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @abstract Simple NSURLSession-based image downloader.
 */
@interface A_SBasicImageDownloader : NSObject <A_SImageDownloaderProtocol>

/**
 * A shared image downloader which can be used by @c A_SNetworkImageNodes and @c A_SMultiplexImageNodes
 *
 * This is a very basic image downloader. It does not support caching, progressive downloading and likely
 * isn't something you should use in production. If you'd like something production ready, see @c A_SPI_NRemoteImageDownloader
 *
 * @note It is strongly recommended you include PI_NRemoteImage and use @c A_SPI_NRemoteImageDownloader instead.
 */
+ (instancetype)sharedImageDownloader;

+ (instancetype)new __attribute__((unavailable("+[A_SBasicImageDownloader sharedImageDownloader] must be used.")));
- (instancetype)init __attribute__((unavailable("+[A_SBasicImageDownloader sharedImageDownloader] must be used.")));

@end

NS_ASSUME_NONNULL_END
