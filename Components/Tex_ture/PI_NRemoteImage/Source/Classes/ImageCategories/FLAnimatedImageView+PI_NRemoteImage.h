//
//  FLAnimatedImageView+PI_NRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PI_NRemoteImageMacros.h"
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImageView.h>

#import "PI_NRemoteImageCategoryManager.h"

@interface FLAnimatedImageView (PI_NRemoteImage) <PI_NRemoteImageCategory>

@end

#endif