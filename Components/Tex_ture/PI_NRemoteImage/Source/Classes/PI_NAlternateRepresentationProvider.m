//
//  PI_NAlternateRepresentationProvider.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "PI_NAlternateRepresentationProvider.h"

#import "NSData+ImageDe_tectors.h"
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

@implementation PI_NAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PI_NRemoteImageManagerDownloadOptions)options
{
#if USE_FLANIMATED_IMAGE
    if ([data pin_isAnimatedGIF]) {
        return [FLAnimatedImage animatedImageWithGIFData:data];
    }
#endif
    return nil;
}

@end
