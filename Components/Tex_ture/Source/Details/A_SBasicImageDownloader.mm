//
//  A_SBasicImageDownloader.mm
//  Tex_ture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /A_SDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Async_DisplayKit/A_SBasicImageDownloader.h>

#import <objc/runtime.h>

#import <Async_DisplayKit/A_SBasicImageDownloaderInternal.h>
#import <Async_DisplayKit/A_SImageContainerProtocolCategories.h>
#import <Async_DisplayKit/A_SThread.h>


#pragma mark -
/**
 * Collection of properties associated with a download request.
 */

NSString * const kA_SBasicImageDownloaderContextCallbackQueue = @"kA_SBasicImageDownloaderContextCallbackQueue";
NSString * const kA_SBasicImageDownloaderContextProgressBlock = @"kA_SBasicImageDownloaderContextProgressBlock";
NSString * const kA_SBasicImageDownloaderContextCompletionBlock = @"kA_SBasicImageDownloaderContextCompletionBlock";

@interface A_SBasicImageDownloaderContext ()
{
  BOOL _invalid;
  A_SDN::RecursiveMutex __instanceLock__;
}

@property (nonatomic, strong) NSMutableArray *callbackDatas;

@end

@implementation A_SBasicImageDownloaderContext

static NSMutableDictionary *currentRequests = nil;
// Allocate currentRequestsLock on the heap to prevent destruction at app exit (https://github.com/Tex_tureGroup/Tex_ture/issues/136)
static A_SDN::StaticMutex& currentRequestsLock = *new A_SDN::StaticMutex;

+ (A_SBasicImageDownloaderContext *)contextForURL:(NSURL *)URL
{
  A_SDN::StaticMutexLocker l(currentRequestsLock);
  if (!currentRequests) {
    currentRequests = [[NSMutableDictionary alloc] init];
  }
  A_SBasicImageDownloaderContext *context = currentRequests[URL];
  if (!context) {
    context = [[A_SBasicImageDownloaderContext alloc] initWithURL:URL];
    currentRequests[URL] = context;
  }
  return context;
}

+ (void)cancelContextWithURL:(NSURL *)URL
{
  A_SDN::StaticMutexLocker l(currentRequestsLock);
  if (currentRequests) {
    [currentRequests removeObjectForKey:URL];
  }
}

- (instancetype)initWithURL:(NSURL *)URL
{
  if (self = [super init]) {
    _URL = URL;
    _callbackDatas = [NSMutableArray array];
  }
  return self;
}

- (void)cancel
{
  A_SDN::MutexLocker l(__instanceLock__);

  NSURLSessionTask *sessionTask = self.sessionTask;
  if (sessionTask) {
    [sessionTask cancel];
    self.sessionTask = nil;
  }

  _invalid = YES;
  [self.class cancelContextWithURL:self.URL];
}

- (BOOL)isCancelled
{
  A_SDN::MutexLocker l(__instanceLock__);
  return _invalid;
}

- (void)addCallbackData:(NSDictionary *)callbackData
{
  A_SDN::MutexLocker l(__instanceLock__);
  [self.callbackDatas addObject:callbackData];
}

- (void)performProgressBlocks:(CGFloat)progress
{
  A_SDN::MutexLocker l(__instanceLock__);
  for (NSDictionary *callbackData in self.callbackDatas) {
    A_SImageDownloaderProgress progressBlock = callbackData[kA_SBasicImageDownloaderContextProgressBlock];
    dispatch_queue_t callbackQueue = callbackData[kA_SBasicImageDownloaderContextCallbackQueue];

    if (progressBlock) {
      dispatch_async(callbackQueue, ^{
        progressBlock(progress);
      });
    }
  }
}

- (void)completeWithImage:(UIImage *)image error:(NSError *)error
{
  A_SDN::MutexLocker l(__instanceLock__);
  for (NSDictionary *callbackData in self.callbackDatas) {
    A_SImageDownloaderCompletion completionBlock = callbackData[kA_SBasicImageDownloaderContextCompletionBlock];
    dispatch_queue_t callbackQueue = callbackData[kA_SBasicImageDownloaderContextCallbackQueue];

    if (completionBlock) {
      dispatch_async(callbackQueue, ^{
        completionBlock(image, error, nil);
      });
    }
  }

  self.sessionTask = nil;
  [self.callbackDatas removeAllObjects];
}

- (NSURLSessionTask *)createSessionTaskIfNecessaryWithBlock:(NSURLSessionTask *(^)())creationBlock {
  {
    A_SDN::MutexLocker l(__instanceLock__);

    if (self.isCancelled) {
      return nil;
    }

    if (self.sessionTask && (self.sessionTask.state == NSURLSessionTaskStateRunning)) {
      return nil;
    }
  }

  NSURLSessionTask *newTask = creationBlock();

  {
    A_SDN::MutexLocker l(__instanceLock__);

    if (self.isCancelled) {
      return nil;
    }

    if (self.sessionTask && (self.sessionTask.state == NSURLSessionTaskStateRunning)) {
      return nil;
    }

    self.sessionTask = newTask;
    
    return self.sessionTask;
  }
}

@end


#pragma mark -
/**
 * NSURLSessionDownloadTask lacks a `userInfo` property, so add this association ourselves.
 */
@interface NSURLRequest (A_SBasicImageDownloader)
@property (nonatomic, strong) A_SBasicImageDownloaderContext *asyncdisplaykit_context;
@end

@implementation NSURLRequest (A_SBasicImageDownloader)
static const char *kContextKey = NSStringFromClass(A_SBasicImageDownloaderContext.class).UTF8String;
- (void)setAsyncdisplaykit_context:(A_SBasicImageDownloaderContext *)asyncdisplaykit_context
{
  objc_setAssociatedObject(self, kContextKey, asyncdisplaykit_context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (A_SBasicImageDownloader *)asyncdisplaykit_context
{
  return objc_getAssociatedObject(self, kContextKey);
}
@end


#pragma mark -
@interface A_SBasicImageDownloader () <NSURLSessionDownloadDelegate>
{
  NSOperationQueue *_sessionDelegateQueue;
  NSURLSession *_session;
}

@end

@implementation A_SBasicImageDownloader

+ (instancetype)sharedImageDownloader
{
  static A_SBasicImageDownloader *sharedImageDownloader = nil;
  static dispatch_once_t once = 0;
  dispatch_once(&once, ^{
    sharedImageDownloader = [[A_SBasicImageDownloader alloc] _init];
  });
  return sharedImageDownloader;
}

#pragma mark Lifecycle.

- (instancetype)_init
{
  if (!(self = [super init]))
    return nil;

  _sessionDelegateQueue = [[NSOperationQueue alloc] init];
  _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                           delegate:self
                                      delegateQueue:_sessionDelegateQueue];

  return self;
}


#pragma mark A_SImageDownloaderProtocol.

- (id)downloadImageWithURL:(NSURL *)URL
                      callbackQueue:(dispatch_queue_t)callbackQueue
                   downloadProgress:(nullable A_SImageDownloaderProgress)downloadProgress
                         completion:(A_SImageDownloaderCompletion)completion
{
  A_SBasicImageDownloaderContext *context = [A_SBasicImageDownloaderContext contextForURL:URL];

  // NSURLSessionDownloadTask will do file I/O to create a temp directory. If called on the main thread this will
  // cause significant performance issues.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // associate metadata with it
    NSMutableDictionary *callbackData = [NSMutableDictionary dictionary];
    callbackData[kA_SBasicImageDownloaderContextCallbackQueue] = callbackQueue ? : dispatch_get_main_queue();

    if (downloadProgress) {
      callbackData[kA_SBasicImageDownloaderContextProgressBlock] = [downloadProgress copy];
    }

    if (completion) {
      callbackData[kA_SBasicImageDownloaderContextCompletionBlock] = [completion copy];
    }

    [context addCallbackData:[NSDictionary dictionaryWithDictionary:callbackData]];

    // Create new task if necessary
    NSURLSessionDownloadTask *task = (NSURLSessionDownloadTask *)[context createSessionTaskIfNecessaryWithBlock:^(){return [_session downloadTaskWithURL:URL];}];

    if (task) {
      task.originalRequest.asyncdisplaykit_context = context;

      // start downloading
      [task resume];
    }
  });

  return context;
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  A_SDisplayNodeAssert([downloadIdentifier isKindOfClass:A_SBasicImageDownloaderContext.class], @"unexpected downloadIdentifier");
  A_SBasicImageDownloaderContext *context = (A_SBasicImageDownloaderContext *)downloadIdentifier;

  [context cancel];
}


#pragma mark NSURLSessionDownloadDelegate.

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  A_SBasicImageDownloaderContext *context = downloadTask.originalRequest.asyncdisplaykit_context;
  [context performProgressBlocks:(CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite];
}

// invoked if the download succeeded with no error
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location
{
  A_SBasicImageDownloaderContext *context = downloadTask.originalRequest.asyncdisplaykit_context;
  if ([context isCancelled]) {
    return;
  }

  if (context) {
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
    [context completeWithImage:image error:nil];
  }
}

// invoked unconditionally
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)task
                           didCompleteWithError:(NSError *)error
{
  A_SBasicImageDownloaderContext *context = task.originalRequest.asyncdisplaykit_context;
  if (context && error) {
    [context completeWithImage:nil error:error];
  }
}

@end
