//
//  PI_NRemoteImageCategory.h
//  Pods
//
//  Created by Garrett Moon on 11/4/14.
//
//

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageManager.h"

@protocol PI_NRemoteImageCategory;

/**
 PI_NRemoteImageCategoryManager is a class that handles subclassing image display classes. PI_NImageView+PI_NRemoteImage, UIButton+PI_NRemoteImage, etc, all delegate their work to this class. If you'd like to create a category to display an image on a view, you should mimic one of the above categories.
 */

@interface PI_NRemoteImageCategoryManager : NSObject

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
      placeholderImage:(nullable PI_NImage *)placeholderImage;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
      placeholderImage:(nullable PI_NImage *)placeholderImage
            completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
            completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
          processorKey:(nullable NSString *)processorKey
             processor:(nullable PI_NRemoteImageManagerImageProcessor)processor;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
      placeholderImage:(nullable PI_NImage *)placeholderImage
          processorKey:(nullable NSString *)processorKey
             processor:(nullable PI_NRemoteImageManagerImageProcessor)processor;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
               fromURL:(nullable NSURL *)url
          processorKey:(nullable NSString *)processorKey
             processor:(nullable PI_NRemoteImageManagerImageProcessor)processor
            completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
              fromURLs:(nullable NSArray <NSURL *> *)urls
      placeholderImage:(nullable PI_NImage *)placeholderImage
          processorKey:(nullable NSString *)processorKey
             processor:(nullable PI_NRemoteImageManagerImageProcessor)processor
            completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
              fromURLs:(nullable NSArray <NSURL *> *)urls;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
              fromURLs:(nullable NSArray <NSURL *> *)urls
      placeholderImage:(nullable PI_NImage *)placeholderImage;

+ (void)setImageOnView:(nonnull id <PI_NRemoteImageCategory>)view
              fromURLs:(nullable NSArray <NSURL *> *)urls
      placeholderImage:(nullable PI_NImage *)placeholderImage
            completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

+ (void)cancelImageDownloadOnView:(nonnull id <PI_NRemoteImageCategory>)view;

+ (nullable NSUUID *)downloadImageOperationUUIDOnView:(nonnull id <PI_NRemoteImageCategory>)view;

+ (void)setDownloadImageOperationUUID:(nullable NSUUID *)downloadImageOperationUUID onView:(nonnull id <PI_NRemoteImageCategory>)view;

+ (BOOL)updateWithProgressOnView:(nonnull id <PI_NRemoteImageCategory>)view;

+ (void)setUpdateWithProgressOnView:(BOOL)updateWithProgress onView:(nonnull id <PI_NRemoteImageCategory>)view;

@end

/**
 Protocol to implement on UIView subclasses to support PI_NRemoteImage
 */
@protocol PI_NRemoteImageCategory <NSObject>

//Call manager

/**
 Set the image from the given URL.
 
 @param url NSURL to fetch from.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url;

/**
 Set the image from the given URL and set placeholder image while image at URL is being retrieved.
 
 @param url NSURL to fetch from.
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url placeholderImage:(nullable PI_NImage *)placeholderImage;

/**
 Set the image from the given URL and call completion when finished.
 
 @param url NSURL to fetch from.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

/**
 Set the image from the given URL, set placeholder while image at url is being retrieved and call completion when finished.
 
 @param url NSURL to fetch from.
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url placeholderImage:(nullable PI_NImage *)placeholderImage completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view.
 
 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PI_NRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url processorKey:(nullable NSString *)processorKey processor:(nullable PI_NRemoteImageManagerImageProcessor)processor;

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view.
 
 @param url NSURL to fetch from.
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PI_NRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url placeholderImage:(nullable PI_NImage *)placeholderImage processorKey:(nullable NSString *)processorKey processor:(nullable PI_NRemoteImageManagerImageProcessor)processor;

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.
 
 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PI_NRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url processorKey:(nullable NSString *)processorKey processor:(nullable PI_NRemoteImageManagerImageProcessor)processor completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.
 
 @param url NSURL to fetch from.
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PI_NRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(nullable NSURL *)url placeholderImage:(nullable PI_NImage *)placeholderImage processorKey:(nullable NSString *)processorKey processor:(nullable PI_NRemoteImageManagerImageProcessor)processor completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

/**
 Retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 */
- (void)pin_setImageFromURLs:(nullable NSArray <NSURL *> *)urls;

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 */
- (void)pin_setImageFromURLs:(nullable NSArray <NSURL *> *)urls placeholderImage:(nullable PI_NImage *)placeholderImage;

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view. Call completion after image has been fetched and set on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage PI_NImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURLs:(nullable NSArray <NSURL *> *)urls placeholderImage:(nullable PI_NImage *)placeholderImage completion:(nullable PI_NRemoteImageManagerImageCompletion)completion;

/**
 Cancels the image download. Guarantees that previous setImage calls will *not* have their results set on the image view after calling this (as opposed to PI_NRemoteImageManager which does not guarantee cancellation).
 */
- (void)pin_cancelImageDownload;

/**
 Returns the NSUUID associated with any PI_NRemoteImage task currently running on the view.
 
 @return NSUUID associated with any PI_NRemoteImage task currently running on the view.
 */
- (nullable NSUUID *)pin_downloadImageOperationUUID;

/**
 Set the current NSUUID associated with a PI_NRemoteImage task running on the view.
 
 @param downloadImageOperationUUID NSUUID associated with a PI_NRemoteImage task.
 */
- (void)pin_setDownloadImageOperationUUID:(nullable NSUUID *)downloadImageOperationUUID;

/**
 Whether the view should update with progress images (such as those provided by progressive JPEG images).
 
 @return BOOL value indicating whether the view should update with progress images
 */
@property (nonatomic, assign) BOOL pin_updateWithProgress;

//Handle
- (void)pin_setPlaceholderWithImage:(nullable PI_NImage *)image;
- (void)pin_updateUIWithRemoteImageManagerResult:(nonnull PI_NRemoteImageManagerResult *)result;
- (void)pin_clearImages;
- (BOOL)pin_ignoreGIFs;

@optional

- (PI_NRemoteImageManagerDownloadOptions)pin_defaultOptions;

@end
