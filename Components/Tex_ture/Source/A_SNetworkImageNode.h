//
//  A_SNetworkImageNode.h
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

#import <Async_DisplayKit/A_SImageNode.h>

NS_ASSUME_NONNULL_BEGIN

@protocol A_SNetworkImageNodeDelegate, A_SImageCacheProtocol, A_SImageDownloaderProtocol;


/**
 * A_SNetworkImageNode is a simple image node that can download and display an image from the network, with support for a
 * placeholder image (<defaultImage>).  The currently-displayed image is always available in the inherited A_SImageNode
 * <image> property.
 *
 * @see A_SMultiplexImageNode for a more powerful counterpart to this class.
 */
@interface A_SNetworkImageNode : A_SImageNode

/**
 * The designated initializer. Cache and Downloader are WEAK references.
 *
 * @param cache The object that implements a cache of images for the image node.  Weak reference.
 * @param downloader The object that implements image downloading for the image node.  Must not be nil.  Weak reference.
 *
 * @discussion If `cache` is nil, the receiver will not attempt to retrieve images from a cache before downloading them.
 *
 * @return An initialized A_SNetworkImageNode.
 */
- (instancetype)initWithCache:(nullable id<A_SImageCacheProtocol>)cache downloader:(id<A_SImageDownloaderProtocol>)downloader NS_DESIGNATED_INITIALIZER;

/**
 * Convenience initializer.
 *
 * @return An A_SNetworkImageNode configured to use the NSURLSession-powered A_SBasicImageDownloader, and no extra cache.
 */
- (instancetype)init;

/**
 * The delegate, which must conform to the <A_SNetworkImageNodeDelegate> protocol.
 */
@property (nullable, nonatomic, weak, readwrite) id<A_SNetworkImageNodeDelegate> delegate;

/**
 * The image to display.
 *
 * @discussion By setting an image to the image property the A_SNetworkImageNode will act like a plain A_SImageNode.
 * As soon as the URL is set the A_SNetworkImageNode will act like an A_SNetworkImageNode and the image property
 * will be managed internally. This means the image property will be cleared out and replaced by the placeholder 
 * (<defaultImage>) image while loading and the final image after the new image data was downloaded and processed.
 * If you want to use a placholder image functionality use the defaultImage property instead.
 */
@property (nullable, nonatomic, strong) UIImage *image;

/**
 * A placeholder image to display while the URL is loading. This is slightly different than placeholderImage in the
 * A_SDisplayNode superclass as defaultImage will *not* be displayed synchronously. If you wish to have the image
 * displayed synchronously, use @c placeholderImage.
 */
@property (nullable, nonatomic, strong, readwrite) UIImage *defaultImage;

/**
 * The URL of a new image to download and display.
 *
 * @discussion By setting an URL, the image property of this node will be managed internally. This means previously
 * directly set images to the image property will be cleared out and replaced by the placeholder (<defaultImage>) image
 * while loading and the final image after the new image data was downloaded and processed.
 */
@property (nullable, nonatomic, strong, readwrite) NSURL *URL;

/**
 * An array of URLs of increasing cost to download.
 *
 * @discussion By setting an array of URLs, the image property of this node will be managed internally. This means previously
 * directly set images to the image property will be cleared out and replaced by the placeholder (<defaultImage>) image
 * while loading and the final image after the new image data was downloaded and processed.
 */
@property (nullable, nonatomic, strong, readwrite) NSArray <NSURL *> *URLs;

/**
 * Download and display a new image.
 *
 * @param URL The URL of a new image to download and display.
 * @param reset Whether to display a placeholder (<defaultImage>) while loading the new image.
 *
 * @discussion By setting an URL, the image property of this node will be managed internally. This means previously
 * directly set images to the image property will be cleared out and replaced by the placeholder (<defaultImage>) image
 * while loading and the final image after the new image data was downloaded and processed.
 */
- (void)setURL:(nullable NSURL *)URL resetToDefault:(BOOL)reset;

/**
 * If <URL> is a local file, set this property to YES to take advantage of UIKit's image caching.  Defaults to YES.
 */
@property (nonatomic, assign, readwrite) BOOL shouldCacheImage;

/**
 * If the downloader implements progressive image rendering and this value is YES progressive renders of the
 * image will be displayed as the image downloads. Regardless of this properties value, progress renders will
 * only occur when the node is visible. Defaults to YES.
 */
@property (nonatomic, assign, readwrite) BOOL shouldRenderProgressImages;

/**
 * The image quality of the current image. This is a number between 0 and 1 and can be used to track
 * progressive progress. Calculated by dividing number of bytes / expected number of total bytes.
 */
@property (nonatomic, assign, readonly) CGFloat currentImageQuality;

/**
 * The image quality (value between 0 and 1) of the last image that completed displaying.
 */
@property (nonatomic, assign, readonly) CGFloat renderedImageQuality;

@end


#pragma mark -

typedef NS_ENUM(NSInteger, A_SNetworkImageSource) {
  A_SNetworkImageSourceUnspecified = 0,
  A_SNetworkImageSourceSynchronousCache,
  A_SNetworkImageSourceAsynchronousCache,
  A_SNetworkImageSourceFileURL,
  A_SNetworkImageSourceDownload,
};

/// A struct that carries details about A_SNetworkImageNode's image loads.
typedef struct {
  /// The source from which the image was loaded.
  A_SNetworkImageSource imageSource;
} A_SNetworkImageNodeDidLoadInfo;

/**
 * The methods declared by the A_SNetworkImageNodeDelegate protocol allow the adopting delegate to respond to
 * notifications such as finished decoding and downloading an image.
 */
@protocol A_SNetworkImageNodeDelegate <NSObject>
@optional

/**
 * Notification that the image node finished downloading an image, with additional info.
 * If implemented, this method will be called instead of `imageNode:didLoadImage:`.
 *
 * @param imageNode The sender.
 * @param image The newly-loaded image.
 * @param info Misc information about the image load.
 *
 * @discussion Called on a background queue.
 */
- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image info:(A_SNetworkImageNodeDidLoadInfo)info;

/**
 * Notification that the image node finished downloading an image.
 *
 * @param imageNode The sender.
 * @param image The newly-loaded image.
 *
 * @discussion Called on a background queue.
 */
- (void)imageNode:(A_SNetworkImageNode *)imageNode didLoadImage:(UIImage *)image;

/**
 * Notification that the image node started to load
 *
 * @param imageNode The sender.
 *
 * @discussion Called on a background queue.
 */
- (void)imageNodeDidStartFetchingData:(A_SNetworkImageNode *)imageNode;

/**
 * Notification that the image node failed to download the image.
 *
 * @param imageNode The sender.
 * @param error The error with details.
 *
 * @discussion Called on a background queue.
 */
- (void)imageNode:(A_SNetworkImageNode *)imageNode didFailWithError:(NSError *)error;

/**
 * Notification that the image node finished decoding an image.
 *
 * @param imageNode The sender.
 */
- (void)imageNodeDidFinishDecoding:(A_SNetworkImageNode *)imageNode;

@end

NS_ASSUME_NONNULL_END
