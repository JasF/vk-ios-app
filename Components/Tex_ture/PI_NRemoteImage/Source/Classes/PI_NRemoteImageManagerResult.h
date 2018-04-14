//
//  PI_NRemoteImageManagerResult.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageMacros.h"
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

/** How the image was fetched. */
typedef NS_ENUM(NSUInteger, PI_NRemoteImageResultType) {
    /** Returned if no image is returned */
    PI_NRemoteImageResultTypeNone = 0,
    /** Image was fetched from the memory cache */
    PI_NRemoteImageResultTypeMemoryCache,
    /** Image was fetched from the disk cache */
    PI_NRemoteImageResultTypeCache,
    /** Image was downloaded */
    PI_NRemoteImageResultTypeDownload,
    /** Image is progress */
    PI_NRemoteImageResultTypeProgress,
};

@interface PI_NRemoteImageManagerResult : NSObject

@property (nonatomic, readonly, strong, nullable) PI_NImage *image;
@property (nonatomic, readonly, strong, nullable) id alternativeRepresentation;
@property (nonatomic, readonly, assign) NSTimeInterval requestDuration;
@property (nonatomic, readonly, strong, nullable) NSError *error;
@property (nonatomic, readonly, assign) PI_NRemoteImageResultType resultType;
@property (nonatomic, readonly, strong, nullable) NSUUID *UUID;
@property (nonatomic, readonly, assign) CGFloat renderedImageQuality;
@property (nonatomic, readonly, assign) NSUInteger bytesSavedByResuming;
@property (nonatomic, readonly, strong, nullable) NSURLResponse *response;

+ (nonnull instancetype)imageResultWithImage:(nullable PI_NImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PI_NRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error;

+ (nonnull instancetype)imageResultWithImage:(nullable PI_NImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PI_NRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error
                        bytesSavedByResuming:(NSUInteger)bytesSavedByResuming;

+ (nonnull instancetype)imageResultWithImage:(nullable PI_NImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PI_NRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error
                        renderedImageQuality:(CGFloat)renderedImageQuality;

@end
