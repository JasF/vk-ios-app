//
//  PI_NRemoteImageDownloadQueue.h
//  PI_NRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PI_NRemoteImageManager.h"

@class PI_NURLSessionManager;

NS_ASSUME_NONNULL_BEGIN

typedef void (^PI_NRemoteImageDownloadCompletion)(NSURLResponse * _Nullable response, NSError *error);

@interface PI_NRemoteImageDownloadQueue : NSObject

@property (nonatomic, assign) NSUInteger maxNumberOfConcurrentDownloads;

- (instancetype)init NS_UNAVAILABLE;
+ (PI_NRemoteImageDownloadQueue *)queueWithMaxConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads;

- (NSURLSessionDataTask *)addDownloadWithSessionManager:(PI_NURLSessionManager *)sessionManager
                                                request:(NSURLRequest *)request
                                               priority:(PI_NRemoteImageManagerPriority)priority
                                      completionHandler:(PI_NRemoteImageDownloadCompletion)completionHandler;

/***
 This prevents a task from being run if it hasn't already started yet. It is the caller's responsibility to cancel
 the task if it has already been started.
 
 @return BOOL Returns YES if the task was in the queue. 
 */
- (BOOL)removeDownloadTaskFromQueue:(NSURLSessionDataTask *)downloadTask;

/*
 This sets the tasks priority of execution. It is the caller's responsibility to set the priority on the task itself
 for NSURLSessionManager.
 */
- (void)setQueuePriority:(PI_NRemoteImageManagerPriority)priority forTask:(NSURLSessionDataTask *)downloadTask;

NS_ASSUME_NONNULL_END

@end
