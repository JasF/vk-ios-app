//
//  PI_NRemoteImageManager+Private.h
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 5/18/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#ifndef PI_NRemoteImageManager_Private_h
#define PI_NRemoteImageManager_Private_h

#import "PI_NRemoteImageDownloadQueue.h"

typedef void (^PI_NRemoteImageManagerDataCompletion)(NSData *data, NSURLResponse *response, NSError *error);

@interface PI_NRemoteImageManager (private)

@property (nonatomic, strong, readonly) dispatch_queue_t callbackQueue;
@property (nonatomic, strong, readonly) PI_NOperationQueue *concurrentOperationQueue;
@property (nonatomic, strong, readonly) PI_NRemoteImageDownloadQueue *urlSessionTaskQueue;
@property (nonatomic, strong, readonly) PI_NURLSessionManager *sessionManager;

@property (nonatomic, readonly) NSArray <NSNumber *> *progressThresholds;
@property (nonatomic, readonly) NSTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, readonly) BOOL shouldBlurProgressive;
@property (nonatomic, readonly) CGSize maxProgressiveRenderSize;

@end

#endif /* PI_NRemoteImageManager_Private_h */
