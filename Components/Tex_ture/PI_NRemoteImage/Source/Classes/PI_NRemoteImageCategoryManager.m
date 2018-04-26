//
//  PI_NRemoteImageCategory.m
//  Pods
//
//  Created by Garrett Moon on 11/4/14.
//
//

#import "PI_NRemoteImageCategoryManager.h"

#import <objc/runtime.h>

@implementation PI_NRemoteImageCategoryManager

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
{
    [self setImageOnView:view fromURL:url placeholderImage:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(PI_NImage *)placeholderImage
{
    [self setImageOnView:view fromURL:url placeholderImage:placeholderImage completion:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
            completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view fromURL:url placeholderImage:nil completion:completion];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(PI_NImage *)placeholderImage
            completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:placeholderImage
            processorKey:nil
               processor:nil
              completion:completion];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PI_NRemoteImageManagerImageProcessor)processor
{
    [self setImageOnView:view
                 fromURL:url
            processorKey:processorKey
               processor:processor
              completion:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(PI_NImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PI_NRemoteImageManagerImageProcessor)processor
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:placeholderImage
            processorKey:processorKey
               processor:processor
              completion:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PI_NRemoteImageManagerImageProcessor)processor
            completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:nil
            processorKey:processorKey
               processor:processor
              completion:completion];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
              fromURLs:(NSArray <NSURL *> *)urls
{
    [self setImageOnView:view
                fromURLs:urls
        placeholderImage:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
              fromURLs:(NSArray <NSURL *> *)urls
      placeholderImage:(PI_NImage *)placeholderImage
{
    [self setImageOnView:view
                fromURLs:urls
        placeholderImage:placeholderImage
              completion:nil];
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
              fromURLs:(NSArray <NSURL *> *)urls
      placeholderImage:(PI_NImage *)placeholderImage
            completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    return [self setImageOnView:view
                       fromURLs:urls
               placeholderImage:placeholderImage
                   processorKey:nil
                      processor:nil
                     completion:completion];
}

+ (NSUUID *)downloadImageOperationUUIDOnView:(id <PI_NRemoteImageCategory>)view
{
    return (NSUUID *)objc_getAssociatedObject(view, @selector(downloadImageOperationUUIDOnView:));
}

+ (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID onView:(id <PI_NRemoteImageCategory>)view
{
    objc_setAssociatedObject(view, @selector(downloadImageOperationUUIDOnView:), downloadImageOperationUUID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)updateWithProgressOnView:(id <PI_NRemoteImageCategory>)view
{
    return [(NSNumber *)objc_getAssociatedObject(view, @selector(updateWithProgressOnView:)) boolValue];
}

+ (void)setUpdateWithProgressOnView:(BOOL)updateWithProgress onView:(id <PI_NRemoteImageCategory>)view
{
    objc_setAssociatedObject(view, @selector(updateWithProgressOnView:), [NSNumber numberWithBool:updateWithProgress], OBJC_ASSOCIATION_RETAIN);
}

+ (void)cancelImageDownloadOnView:(id <PI_NRemoteImageCategory>)view
{
    if ([self downloadImageOperationUUIDOnView:view]) {
        [[PI_NRemoteImageManager sharedImageManager] cancelTaskWithUUID:[self downloadImageOperationUUIDOnView:view]];
        [self setDownloadImageOperationUUID:nil onView:view];
    }
}

+ (void)setImageOnView:(id <PI_NRemoteImageCategory>)view
              fromURLs:(NSArray <NSURL *> *)urls
      placeholderImage:(PI_NImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PI_NRemoteImageManagerImageProcessor)processor
            completion:(PI_NRemoteImageManagerImageCompletion)completion
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setImageOnView:view
                        fromURLs:urls
                placeholderImage:placeholderImage
                    processorKey:processorKey
                       processor:processor
                      completion:completion];
        });
        return;
    }
    
    [self cancelImageDownloadOnView:view];
  
    if (placeholderImage) {
        [view pin_setPlaceholderWithImage:placeholderImage];
    }
    
    if (urls == nil || urls.count == 0) {
        if (!placeholderImage) {
            [view pin_clearImages];
        }
        return;
    }
    
    PI_NRemoteImageManagerDownloadOptions options;
    if([view respondsToSelector:@selector(pin_defaultOptions)]) {
        options = [view pin_defaultOptions];
    } else {
        options = PI_NRemoteImageManagerDownloadOptionsNone;
    }
    
    if ([view pin_ignoreGIFs]) {
        options |= PI_NRemoteImageManagerDisallowAlternateRepresentations;
    }
    
    PI_NRemoteImageManagerImageCompletion internalProgress = nil;
    if ([self updateWithProgressOnView:view] && processorKey.length <= 0 && processor == nil) {
        internalProgress = ^(PI_NRemoteImageManagerResult *result)
        {
            void (^mainQueue)(void) = ^{
                //if result.UUID is nil, we returned immediately and want this result
                NSUUID *currentUUID = [self downloadImageOperationUUIDOnView:view];
                if (![currentUUID isEqual:result.UUID] && result.UUID != nil) {
                    return;
                }
                if (result.image) {
                    [view pin_updateUIWithRemoteImageManagerResult:result];

                }
            };
            if ([NSThread isMainThread]) {
                mainQueue();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    mainQueue();
                });
            }
        };
    }
    
    PI_NRemoteImageManagerImageCompletion internalCompletion = ^(PI_NRemoteImageManagerResult *result)
    {
        void (^mainQueue)(void) = ^{
            //if result.UUID is nil, we returned immediately and want this result
            NSUUID *currentUUID = [self downloadImageOperationUUIDOnView:view];
            if (![currentUUID isEqual:result.UUID] && result.UUID != nil) {
                return;
            }
            [self setDownloadImageOperationUUID:nil onView:view];
            if (result.error) {
                if (completion) {
                    completion(result);
                }
                return;
            }
            
            [view pin_updateUIWithRemoteImageManagerResult:result];
            
            if (completion) {
                completion(result);
            }
        };
        if ([NSThread isMainThread]) {
            mainQueue();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                mainQueue();
            });
        }
    };
    
    NSUUID *downloadImageOperationUUID = nil;
    if (urls.count > 1) {
        downloadImageOperationUUID = [[PI_NRemoteImageManager sharedImageManager] downloadImageWithURLs:urls
                                                                                               options:options
                                                                                         progressImage:internalProgress
                                                                                            completion:internalCompletion];
    } else if (processorKey.length > 0 && processor) {
        downloadImageOperationUUID = [[PI_NRemoteImageManager sharedImageManager] downloadImageWithURL:urls[0]
                                                                                              options:options
                                                                                         processorKey:processorKey
                                                                                            processor:processor
                                                                                           completion:internalCompletion];
    } else {
        downloadImageOperationUUID = [[PI_NRemoteImageManager sharedImageManager] downloadImageWithURL:urls[0]
                                                                                              options:options
                                                                                        progressImage:internalProgress
                                                                                           completion:internalCompletion];
    }
    
    [self setDownloadImageOperationUUID:downloadImageOperationUUID onView:view];
}

@end
