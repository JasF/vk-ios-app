//
//  PI_NRemoteImageDownloadTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PI_NRemoteImageDownloadTask.h"

#import "PI_NRemoteImageTask+Subclassing.h"
#import "PI_NRemoteImage.h"
#import "PI_NRemoteImageCallbacks.h"
#import "PI_NRemoteLock.h"
#import "PI_NSpeedRecorder.h"

@interface PI_NRemoteImageDownloadTask ()
{
    PI_NProgressiveImage *_progressImage;
    PI_NResume *_resume;
    id<PI_NRequestRetryStrategy> _retryStrategy;
}

@end

@implementation PI_NRemoteImageDownloadTask

- (instancetype)initWithManager:(PI_NRemoteImageManager *)manager
{
    if (self = [super initWithManager:manager]) {
        _retryStrategy = manager.retryStrategyCreationBlock();
    }
    return self;
}

- (void)callProgressDownload
{
    NSDictionary *callbackBlocks = self.callbackBlocks;
    #if PI_NRemoteImageLogging
    NSString *key = self.key;
    #endif
    
    __block int64_t completedBytes;
    __block int64_t totalBytes;
    
    [self.lock lockWithBlock:^{
        completedBytes = self->_progressImage.dataTask.countOfBytesReceived;
        totalBytes = self->_progressImage.dataTask.countOfBytesExpectedToReceive;
    }];
    
    [callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PI_NRemoteImageCallbacks *callback, BOOL *stop) {
        PI_NRemoteImageManagerProgressDownload progressDownloadBlock = callback.progressDownloadBlock;
        if (progressDownloadBlock != nil) {
            PI_NLog(@"calling progress for UUID: %@ key: %@", UUID, key);
            dispatch_async(self.manager.callbackQueue, ^
            {
                progressDownloadBlock(completedBytes, totalBytes);
            });
        }
    }];
}

- (void)callProgressImageWithImage:(nonnull PI_NImage *)image renderedImageQuality:(CGFloat)renderedImageQuality
{
    NSDictionary *callbackBlocks = self.callbackBlocks;
#if PI_NRemoteImageLogging
    NSString *key = self.key;
#endif
    
    
    [callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PI_NRemoteImageCallbacks *callback, BOOL *stop) {
        PI_NRemoteImageManagerImageCompletion progressImageBlock = callback.progressImageBlock;
        if (progressImageBlock != nil) {
            PI_NLog(@"calling progress for UUID: %@ key: %@", UUID, key);
            CFTimeInterval requestTime = callback.requestTime;

            dispatch_async(self.manager.callbackQueue, ^
            {
                progressImageBlock([PI_NRemoteImageManagerResult imageResultWithImage:image
                                                           alternativeRepresentation:nil
                                                                       requestLength:CACurrentMediaTime() - requestTime
                                                                          resultType:PI_NRemoteImageResultTypeProgress
                                                                                UUID:UUID
                                                                            response:nil
                                                                               error:nil
                                                                renderedImageQuality:renderedImageQuality]);
           });
        }
    }];
}

- (BOOL)cancelWithUUID:(NSUUID *)UUID resume:(PI_NResume **)resume
{
    __block BOOL noMoreCompletions;
    __block PI_NResume *strongResume;
    BOOL hasResume = resume != nil;
    [self.lock lockWithBlock:^{
        if (hasResume) {
            //consider skipping cancelation if there's a request for resume data and the time to start the connection is greater than
            //the time remaining to download.
            NSTimeInterval timeToFirstByte = [[PI_NSpeedRecorder sharedRecorder] weightedTimeToFirstByteForHost:self->_progressImage.dataTask.currentRequest.URL.host];
            if (self->_progressImage.estimatedRemainingTime <= timeToFirstByte) {
                noMoreCompletions = NO;
                return;
            }
        }
        
        noMoreCompletions = [super l_cancelWithUUID:UUID];
        
        if (noMoreCompletions) {
            [self.manager.urlSessionTaskQueue removeDownloadTaskFromQueue:self->_progressImage.dataTask];
            [self->_progressImage.dataTask cancel];
            
            if (hasResume && self->_ifRange && self->_progressImage.dataTask.countOfBytesExpectedToReceive > 0 && self->_progressImage.dataTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown) {
                NSData *progressData = self->_progressImage.data;
                if (progressData.length > 0) {
                    strongResume = [PI_NResume resumeData:progressData ifRange:self->_ifRange totalBytes:self->_progressImage.dataTask.countOfBytesExpectedToReceive];
                }
            }
            
            PI_NLog(@"Canceling download of URL: %@, UUID: %@", _progressImage.dataTask.originalRequest.URL, UUID);
        }
#if PI_NRemoteImageLogging
        else {
            PI_NLog(@"Decrementing download of URL: %@, UUID: %@", _progressImage.dataTask.originalRequest.URL, UUID);
        }
#endif
    }];
    
    if (hasResume) {
        *resume = strongResume;
    }
    
    return noMoreCompletions;
}

- (void)setPriority:(PI_NRemoteImageManagerPriority)priority
{
    [super setPriority:priority];
    if (@available(iOS 8.0, macOS 10.10, tvOS 9.0, watchOS 2.0, *)) {
        [self.lock lockWithBlock:^{
            if (self->_progressImage.dataTask) {
                self->_progressImage.dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
                [self.manager.urlSessionTaskQueue setQueuePriority:priority forTask:self->_progressImage.dataTask];
            }
        }];
    }
}

- (NSURL *)URL
{
    __block NSURL *url;
    [self.lock lockWithBlock:^{
        url = self->_progressImage.dataTask.originalRequest.URL;
    }];
    return url;
}

- (nonnull PI_NRemoteImageManagerResult *)imageResultWithImage:(nullable PI_NImage *)image
                                    alternativeRepresentation:(nullable id)alternativeRepresentation
                                                requestLength:(NSTimeInterval)requestLength
                                                        error:(nullable NSError *)error
                                                   resultType:(PI_NRemoteImageResultType)resultType
                                                         UUID:(nullable NSUUID *)UUID
                                                     response:(nonnull NSURLResponse *)response
{
    __block NSUInteger bytesSavedByResuming;
    [self.lock lockWithBlock:^{
        bytesSavedByResuming = self->_resume.resumeData.length;
    }];
    return [PI_NRemoteImageManagerResult imageResultWithImage:image
                                   alternativeRepresentation:alternativeRepresentation
                                               requestLength:requestLength
                                                  resultType:resultType
                                                        UUID:UUID
                                                    response:response
                                                       error:error
                                        bytesSavedByResuming:bytesSavedByResuming];
}

- (void)didReceiveData:(NSData *_Nonnull)data
{
    [self callProgressDownload];
    
    __block int64_t expectedNumberOfBytes;
    [self.lock lockWithBlock:^{
        expectedNumberOfBytes = self->_progressImage.dataTask.countOfBytesExpectedToReceive;
    }];
    
    [self updateData:data isResume:NO expectedBytes:expectedNumberOfBytes];
}

- (void)updateData:(NSData *)data isResume:(BOOL)isResume expectedBytes:(int64_t)expectedBytes
{
    __block PI_NProgressiveImage *progressImage;
    __block BOOL hasProgressBlocks = NO;
    [self.lock lockWithBlock:^{
        progressImage = self->_progressImage;
        [[self l_callbackBlocks] enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PI_NRemoteImageCallbacks *callback, BOOL *stop) {
            if (callback.progressImageBlock) {
                hasProgressBlocks = YES;
                *stop = YES;
            }
        }];
    }];
    
    [progressImage updateProgressiveImageWithData:data expectedNumberOfBytes:expectedBytes isResume:isResume];
    
    if (hasProgressBlocks) {
        if (PI_NNSOperationSupportsBlur) {
            [self.manager.concurrentOperationQueue scheduleOperation:^{
                CGFloat renderedImageQuality = 1.0;
                PI_NImage *image = [progressImage currentImageBlurred:self.manager.shouldBlurProgressive maxProgressiveRenderSize:self.manager.maxProgressiveRenderSize renderedImageQuality:&renderedImageQuality];
                if (image) {
                    [self callProgressImageWithImage:image renderedImageQuality:renderedImageQuality];
                }
            } withPriority:PI_NOperationQueuePriorityLow];
        }
    }
}

- (void)didReceiveResponse:(nonnull NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Got partial data back for a resume
        if (httpResponse.statusCode == 206) {
            __block PI_NResume *resume;
            [self.lock lockWithBlock:^{
                resume = self->_resume;
            }];
            
            [self updateData:resume.resumeData isResume:YES expectedBytes:resume.totalBytes];
        } else {
            //Check if there's resume data and we didn't get back a 206, get rid of it
            [self.lock lockWithBlock:^{
                self->_resume = nil;
            }];
        }
        
        // Check to see if the server supports resume
        if ([[httpResponse allHeaderFields][@"Accept-Ranges"] isEqualToString:@"bytes"]) {
            NSString *ifRange = nil;
            NSString *etag = nil;
            
            if ((etag = [httpResponse allHeaderFields][@"ETag"])) {
                if ([etag hasPrefix:@"W/"] == NO) {
                    ifRange = etag;
                }
            } else {
                ifRange = [httpResponse allHeaderFields][@"Last-Modified"];
            }
            
            if (ifRange.length > 0) {
                [self.lock lockWithBlock:^{
                    self->_ifRange = ifRange;
                }];
            }
        }
    }
}

- (void)scheduleDownloadWithRequest:(nonnull NSURLRequest *)request
                             resume:(nullable PI_NResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PI_NRemoteImageManagerPriority)priority
                  completionHandler:(nonnull PI_NRemoteImageManagerDataCompletion)completionHandler
{
  [self scheduleDownloadWithRequest:request resume:resume skipRetry:skipRetry priority:priority isRetry:NO completionHandler:completionHandler];
}

- (void)scheduleDownloadWithRequest:(NSURLRequest *)request
                             resume:(PI_NResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PI_NRemoteImageManagerPriority)priority
                            isRetry:(BOOL)isRetry
                  completionHandler:(PI_NRemoteImageManagerDataCompletion)completionHandler
{
    [self.lock lockWithBlock:^{
        if (self->_progressImage != nil || [self l_callbackBlocks].count == 0 || (isRetry == NO && self->_retryStrategy.numberOfRetries > 0)) {
            return;
        }
        self->_resume = resume;
        
        NSURLRequest *adjustedRequest = request;
        if (self->_resume) {
            NSMutableURLRequest *mutableRequest = [request mutableCopy];
            NSMutableDictionary *headers = [[mutableRequest allHTTPHeaderFields] mutableCopy];
            headers[@"If-Range"] = self->_resume.ifRange;
            headers[@"Range"] = [NSString stringWithFormat:@"bytes=%tu-", self->_resume.resumeData.length];
            mutableRequest.allHTTPHeaderFields = headers;
            adjustedRequest = mutableRequest;
        }
        
        self->_progressImage = [[PI_NProgressiveImage alloc] initWithDataTask:[self.manager.urlSessionTaskQueue addDownloadWithSessionManager:self.manager.sessionManager
                                                                                                                                     request:adjustedRequest
                                                                                                                                    priority:priority
                                                                                                                           completionHandler:^(NSURLResponse * _Nonnull response, NSError * _Nonnull remoteError)
        {
            [self.manager.concurrentOperationQueue scheduleOperation:^{
                NSError *error = remoteError;
#if PI_NRemoteImageLogging
                if (error && error.code != NSURLErrorCancelled) {
                    PI_NLog(@"Failed downloading image: %@ with error: %@", request.URL, error);
                } else if (error == nil && response.expectedContentLength == 0) {
                    PI_NLog(@"image is empty at URL: %@", request.URL);
                } else {
                    PI_NLog(@"Finished downloading image: %@", request.URL);
                }
#endif
                
                if (error.code != NSURLErrorCancelled) {
                    NSData *data = self.progressImage.data;
                    
                    if (error == nil && data == nil) {
                        error = [NSError errorWithDomain:PI_NRemoteImageManagerErrorDomain
                                                    code:PI_NRemoteImageManagerErrorImageEmpty
                                                userInfo:nil];
                    }
                    
                    __block BOOL retry = NO;
                    __block int64_t delay = 0;
                    [self.lock lockWithBlock:^{
                        retry = skipRetry == NO && [self->_retryStrategy shouldRetryWithError:error];
                        if (retry) {
                            // Clear out the exsiting progress image or else new data from retry will be appended
                            self->_progressImage = nil;
                            [self->_retryStrategy incrementRetryCount];
                            delay = [self->_retryStrategy nextDelay];
                        }
                    }];
                    if (retry) {
                        PI_NLog(@"Retrying download of %@ in %lld seconds.", request.URL, delay);
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [self scheduleDownloadWithRequest:request resume:nil skipRetry:skipRetry priority:priority isRetry:YES completionHandler:completionHandler];
                        });
                        return;
                    }
                    
                    completionHandler(data, response, error);
                }
            }];
        }]];
        
        if (@available(iOS 8.0, macOS 10.10, tvOS 9.0, watchOS 2.0, *)) {
            self->_progressImage.dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
        }
    }];
}

- (PI_NProgressiveImage *)progressImage
{
    __block PI_NProgressiveImage *progressImage = nil;
    [self.lock lockWithBlock:^{
        progressImage = self->_progressImage;
    }];
    return progressImage;
}

+ (BOOL)retriableError:(NSError *)remoteImageError
{
    if ([remoteImageError.domain isEqualToString:PI_NURLErrorDomain]) {
        return remoteImageError.code >= 500;
    } else if ([remoteImageError.domain isEqualToString:NSURLErrorDomain] && remoteImageError.code == NSURLErrorUnsupportedURL) {
        return NO;
    } else if ([remoteImageError.domain isEqualToString:PI_NRemoteImageManagerErrorDomain]) {
        return NO;
    }
    return YES;
}

- (CFTimeInterval)estimatedRemainingTime
{
    return self.progressImage.estimatedRemainingTime;
}

- (NSData *)data
{
    return self.progressImage.data;
}

@end
