//
//  PI_NRemoteImageBasicCache.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import <Foundation/Foundation.h>
#import "PI_NRemoteImageCaching.h"

/**
 *  Simplistic <PI_NRemoteImageCacheProtocol> wrapper based on NSCache.
 *  not persisting any data on disk
 */
@interface PI_NRemoteImageBasicCache : NSObject <PI_NRemoteImageCaching>

@end
