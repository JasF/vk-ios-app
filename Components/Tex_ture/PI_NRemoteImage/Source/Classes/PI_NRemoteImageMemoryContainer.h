//
//  PI_NRemoteImageMemoryContainer.h
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import <Foundation/Foundation.h>

#import "PI_NRemoteImageMacros.h"
#import "PI_NRemoteLock.h"

@class PI_NImage;

@interface PI_NRemoteImageMemoryContainer : NSObject

@property (nonatomic, strong) PI_NImage *image;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) PI_NRemoteLock *lock;

@end
