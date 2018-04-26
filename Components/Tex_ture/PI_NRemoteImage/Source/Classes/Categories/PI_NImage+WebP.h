//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#if PI_N_WEBP

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageMacros.h"

@interface PI_NImage (PI_NWebP)

+ (PI_NImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

#endif
