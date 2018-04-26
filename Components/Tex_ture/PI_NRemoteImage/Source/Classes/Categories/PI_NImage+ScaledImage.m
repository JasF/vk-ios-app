//
//  UIImage+ScaledImage.m
//  Pods
//
//  Created by Michael Schneider on 2/9/17.
//
//

#import "PI_NImage+ScaledImage.h"

static inline PI_NImage *PI_NScaledImageForKey(NSString * __nullable key, PI_NImage * __nullable image) {
    if (image == nil) {
        return nil;
    }
    
#if PI_N_TARGET_IOS
    
    NSCAssert(image.CGImage != NULL, @"CGImage should not be NULL");
    
    CGFloat scale = 1.0;
    if (key.length >= 8) {
        if ([key rangeOfString:@"_2x."].location != NSNotFound ||
            [key rangeOfString:@"@2x."].location != NSNotFound) {
            scale = 2.0;
        }
        
        if ([key rangeOfString:@"_3x."].location != NSNotFound ||
            [key rangeOfString:@"@3x."].location != NSNotFound) {
            scale = 3.0;
        }
    }
    
    if (scale != image.scale) {
        return [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
    }
    
    return image;

#elif PI_N_TARGET_MAC
    return image;
#endif
}

@implementation PI_NImage (ScaledImage)

- (PI_NImage *)pin_scaledImageForKey:(NSString *)key
{
    return PI_NScaledImageForKey(key, self);
}

+ (PI_NImage *)pin_scaledImageForImage:(PI_NImage *)image withKey:(NSString *)key
{
    return PI_NScaledImageForKey(key, image);
}

@end
