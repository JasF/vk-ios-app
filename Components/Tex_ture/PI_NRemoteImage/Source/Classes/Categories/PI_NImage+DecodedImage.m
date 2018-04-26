//
//  UIImage+DecodedImage.m
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import "PI_NImage+DecodedImage.h"

#import <ImageIO/ImageIO.h>

#ifdef PI_N_WEBP
#import "PI_NImage+WebP.h"
#endif

#import "NSData+ImageDe_tectors.h"

#if !PI_N_TARGET_IOS
@implementation NSImage (PI_NiOSMapping)

- (CGImageRef)CGImage
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSRect rect = NSMakeRect(0.0, 0.0, self.size.width, self.size.height);
    return [self CGImageForProposedRect:&rect context:context hints:NULL];
}

+ (NSImage *)imageWithData:(NSData *)imageData;
{
    return [[self alloc] initWithData:imageData];
}

+ (NSImage *)imageWithContentsOfFile:(NSString *)path
{
    return path ? [[self alloc] initWithContentsOfFile:path] : nil;
}

+ (NSImage *)imageWithCGImage:(CGImageRef)imageRef
{
    return [[self alloc] initWithCGImage:imageRef size:CGSizeZero];
}

@end
#endif

NSData * __nullable PI_NImageJPEGRepresentation(PI_NImage * __nonnull image, CGFloat compressionQuality)
{
#if PI_N_TARGET_IOS
    return UIImageJPEGRepresentation(image, compressionQuality);
#elif PI_N_TARGET_MAC
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSDictionary *imageProperties = @{NSImageCompressionFactor : @(compressionQuality)};
    return [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
#endif
}

NSData * __nullable PI_NImagePNGRepresentation(PI_NImage * __nonnull image) {
#if PI_N_TARGET_IOS
    return UIImagePNGRepresentation(image);
#elif PI_N_TARGET_MAC
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSDictionary *imageProperties = @{NSImageCompressionFactor : @1};
    return [imageRep representationUsingType:NSPNGFileType properties:imageProperties];
#endif
}


@implementation PI_NImage (PI_NDecodedImage)

+ (PI_NImage *)pin_decodedImageWithData:(NSData *)data
{
    return [self pin_decodedImageWithData:data skipDecodeIfPossible:NO];
}

+ (PI_NImage *)pin_decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible
{
    if (data == nil) {
        return nil;
    }
    
#if PI_N_WEBP
    if ([data pin_isWebP]) {
        return [PI_NImage pin_imageWithWebPData:data];
    }
#endif
    
    PI_NImage *decodedImage = nil;
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    if (imageSourceRef) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache : (NSNumber *)kCFBooleanFalse});
        if (imageRef) {
#if PI_N_TARGET_IOS
            UIImageOrientation orientation = pin_UIImageOrientationFromImageSource(imageSourceRef);
            if (skipDecodeIfPossible) {
                decodedImage = [PI_NImage imageWithCGImage:imageRef scale:1.0 orientation:orientation];
            } else {
                decodedImage = [self pin_decodedImageWithCGImageRef:imageRef orientation:orientation];
            }
#elif PI_N_TARGET_MAC
            if (skipDecodeIfPossible) {
                CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
                decodedImage = [[NSImage alloc] initWithCGImage:imageRef size:imageSize];
            } else {
                decodedImage = [self pin_decodedImageWithCGImageRef:imageRef];
            }
#endif
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSourceRef);
    }
    
    return decodedImage;
}

+ (PI_NImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef
{
#if PI_N_TARGET_IOS
    return [self pin_decodedImageWithCGImageRef:imageRef orientation:UIImageOrientationUp];
}

+ (PI_NImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation)orientation
{
#endif
#if PI_N_TARGET_IOS
    return [UIImage imageWithCGImage:[self pin_decodedImageRefWithCGImageRef:imageRef] scale:1.0 orientation:orientation];
#elif PI_N_TARGET_MAC
    return [[NSImage alloc] initWithCGImage:[self pin_decodedImageRefWithCGImageRef:imageRef] size:NSZeroSize];
#endif
}

+ (CGImageRef)pin_decodedImageRefWithCGImageRef:(CGImageRef)imageRef
{
    BOOL opaque = YES;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    if (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaOnly || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast) {
        opaque = NO;
    }
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    CGBitmapInfo info = opaque ? (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host) : (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    //Use UIGraphicsBeginImageContext parameters from docs: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/#//apple_ref/c/func/UIGraphicsBeginImageContextWithOptions
    CGContextRef ctx = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height,
                                             8,
                                             0,
                                             colorspace,
                                             info);
    
    CGColorSpaceRelease(colorspace);
    
    if (ctx) {
        CGContextSetBlendMode(ctx, kCGBlendModeCopy);
        CGContextDrawImage(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), imageRef);
        
        CGImageRef decodedImageRef = CGBitmapContextCreateImage(ctx);
        if (decodedImageRef) {
            CFAutorelease(decodedImageRef);
        }
        CGContextRelease(ctx);
        return decodedImageRef;
        
    }
    
    return imageRef;
}

#if PI_N_TARGET_IOS
UIImageOrientation pin_UIImageOrientationFromImageSource(CGImageSourceRef imageSourceRef) {
    UIImageOrientation orientation = UIImageOrientationUp;
    
    if (imageSourceRef != nil) {
        NSDictionary *dict = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL));
        
        if (dict != nil) {
            
            NSNumber* exifOrientation = dict[(id)kCGImagePropertyOrientation];
            if (exifOrientation != nil) {
                
                switch (exifOrientation.intValue) {
                    case 1: /*kCGImagePropertyOrientationUp*/
                        orientation = UIImageOrientationUp;
                        break;
                        
                    case 2: /*kCGImagePropertyOrientationUpMirrored*/
                        orientation = UIImageOrientationUpMirrored;
                        break;
                        
                    case 3: /*kCGImagePropertyOrientationDown*/
                        orientation = UIImageOrientationDown;
                        break;
                        
                    case 4: /*kCGImagePropertyOrientationDownMirrored*/
                        orientation = UIImageOrientationDownMirrored;
                        break;
                    case 5: /*kCGImagePropertyOrientationLeftMirrored*/
                        orientation = UIImageOrientationLeftMirrored;
                        break;
                        
                    case 6: /*kCGImagePropertyOrientationRight*/
                        orientation = UIImageOrientationRight;
                        break;
                        
                    case 7: /*kCGImagePropertyOrientationRightMirrored*/
                        orientation = UIImageOrientationRightMirrored;
                        break;
                        
                    case 8: /*kCGImagePropertyOrientationLeft*/
                        orientation = UIImageOrientationLeft;
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    
    return orientation;
}

#endif

@end
