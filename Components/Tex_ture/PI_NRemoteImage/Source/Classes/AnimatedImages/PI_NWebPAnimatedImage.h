//
//  PI_NWebPAnimatedImage.h
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 9/14/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "PI_NAnimatedImage.h"

@interface PI_NWebPAnimatedImage : PI_NAnimatedImage <PI_NAnimatedImage>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

@end
