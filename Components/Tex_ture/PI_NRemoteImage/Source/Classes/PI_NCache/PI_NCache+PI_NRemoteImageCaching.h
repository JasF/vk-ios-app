//
//  PI_NCache+PI_NRemoteImageCaching.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import <PI_NCache/PI_NCache.h>

#import "PI_NRemoteImageCaching.h"
#import "PI_NRemoteImageManager.h"

@interface PI_NCache (PI_NRemoteImageCaching) <PI_NRemoteImageCaching>

@end

@interface PI_NRemoteImageManager (PI_NCache)

@property (nonatomic, nullable, readonly) PI_NCache <PI_NRemoteImageCaching> *pinCache;

@end
