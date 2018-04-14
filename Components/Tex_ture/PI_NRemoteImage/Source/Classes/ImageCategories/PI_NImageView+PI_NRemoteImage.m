//
//  UIImageView+PI_NRemoteImage.m
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PI_NImageView+PI_NRemoteImage.h"

@implementation PI_NImageView (PI_NRemoteImage)

- (void)pin_setImageFromURL:(NSURL *)url
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PI_NImage *)placeholderImage
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURL:(NSURL *)url completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PI_NImage *)placeholderImage completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PI_NRemoteImageManagerImageProcessor)processor
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PI_NImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PI_NRemoteImageManagerImageProcessor)processor
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PI_NRemoteImageManagerImageProcessor)processor completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PI_NImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PI_NRemoteImageManagerImageProcessor)processor completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURLs:url?@[url]:nil placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURLs:urls];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PI_NImage *)placeholderImage
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PI_NImage *)placeholderImage completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [PI_NRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage completion:completion];
}

- (void)pin_cancelImageDownload
{
    [PI_NRemoteImageCategoryManager cancelImageDownloadOnView:self];
}

- (NSUUID *)pin_downloadImageOperationUUID
{
    return [PI_NRemoteImageCategoryManager downloadImageOperationUUIDOnView:self];
}

- (void)pin_setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID
{
    [PI_NRemoteImageCategoryManager setDownloadImageOperationUUID:downloadImageOperationUUID onView:self];
}

- (BOOL)pin_updateWithProgress
{
    return [PI_NRemoteImageCategoryManager updateWithProgressOnView:self];
}

- (void)setPin_updateWithProgress:(BOOL)updateWithProgress
{
    [PI_NRemoteImageCategoryManager setUpdateWithProgressOnView:updateWithProgress onView:self];
}

- (void)pin_setPlaceholderWithImage:(PI_NImage *)image
{
    self.image = image;
}

- (void)pin_updateUIWithRemoteImageManagerResult:(PI_NRemoteImageManagerResult *)result
{
    if (result.image) {
        self.image = result.image;

#if PI_N_TARGET_IOS
        [self setNeedsLayout];
#elif PI_N_TARGET_MAC
        [self setNeedsLayout:YES];
#endif
    }
}

- (void)pin_clearImages
{
    self.image = nil;
    
#if PI_N_TARGET_IOS
    [self setNeedsLayout];
#elif PI_N_TARGET_MAC
    [self setNeedsLayout:YES];
#endif
}

- (BOOL)pin_ignoreGIFs
{
    return YES;
}

@end
