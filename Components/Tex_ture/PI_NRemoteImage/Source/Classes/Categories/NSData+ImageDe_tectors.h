//
//  NSData+ImageDe_tectors.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSData (PI_NImageDe_tectors)

- (BOOL)pin_isGIF;
- (BOOL)pin_isAnimatedGIF;
#if PI_N_WEBP
- (BOOL)pin_isWebP;
- (BOOL)pin_isAnimatedWebP;
#endif

@end
