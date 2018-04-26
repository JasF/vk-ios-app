//
//  PI_NRemoteImageCallbacks.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>

#import "PI_NRemoteImageManager.h"

@interface PI_NRemoteImageCallbacks : NSObject

@property (atomic, strong, nullable) PI_NRemoteImageManagerImageCompletion completionBlock;
@property (atomic, strong, nullable) PI_NRemoteImageManagerImageCompletion progressImageBlock;
@property (atomic, strong, nullable) PI_NRemoteImageManagerProgressDownload progressDownloadBlock;
@property (assign, readonly) CFTimeInterval requestTime;

@end
