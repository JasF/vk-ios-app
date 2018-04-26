//
//  UIImage+DecodedImage.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <Foundation/Foundation.h>

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageMacros.h"

#if !PI_N_TARGET_IOS
@interface NSImage (PI_NiOSMapping)

@property(nonatomic, readonly, nullable) CGImageRef CGImage;

+ (nullable NSImage *)imageWithData:(nonnull NSData *)imageData;
+ (nullable NSImage *)imageWithContentsOfFile:(nonnull NSString *)path;
+ (nonnull NSImage *)imageWithCGImage:(nonnull CGImageRef)imageRef;

@end
#endif

NSData * __nullable PI_NImageJPEGRepresentation(PI_NImage * __nonnull image, CGFloat compressionQuality);
NSData * __nullable PI_NImagePNGRepresentation(PI_NImage * __nonnull image);

@interface PI_NImage (PI_NDecodedImage)

+ (nullable PI_NImage *)pin_decodedImageWithData:(nonnull NSData *)data;
+ (nullable PI_NImage *)pin_decodedImageWithData:(nonnull NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (nullable PI_NImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef;
#if PI_N_TARGET_IOS
+ (nullable PI_NImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef orientation:(UIImageOrientation) orientation;
#endif
+ (nullable CGImageRef)pin_decodedImageRefWithCGImageRef:(nonnull CGImageRef)imageRef;

@end
