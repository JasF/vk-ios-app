//
//  UIImage+ScaledImage.h
//  Pods
//
//  Created by Michael Schneider on 2/9/17.
//
//

#import <Foundation/Foundation.h>

#if PI_N_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PI_N_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PI_NRemoteImageMacros.h"

@interface PI_NImage (PI_NScaledImage)

- (PI_NImage *)pin_scaledImageForKey:(NSString *)key;
+ (PI_NImage *)pin_scaledImageForImage:(PI_NImage *)image withKey:(NSString *)key;

@end
