//
//  PI_NURLSessionManager.h
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import <Foundation/Foundation.h>

extern NSErrorDomain _Nonnull const PI_NURLErrorDomain;

@protocol PI_NURLSessionManagerDelegate <NSObject>

@required
- (void)didReceiveData:(nonnull NSData *)data forTask:(nonnull NSURLSessionTask *)task;

@optional
- (void)didReceiveResponse:(nonnull NSURLResponse *)response forTask:(nonnull NSURLSessionTask *)task;
- (void)didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge forTask:(nullable NSURLSessionTask *)task completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential  * _Nullable credential))completionHandler;


@end

typedef void (^PI_NURLSessionDataTaskCompletion)(NSURLSessionTask * _Nonnull task, NSError * _Nullable error);

@interface PI_NURLSessionManager : NSObject

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration;

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull PI_NURLSessionDataTaskCompletion)completionHandler;

- (void)invalidateSessionAndCancelTasks;

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didFinishCollectingMetrics:(nonnull NSURLSessionTaskMetrics *)metrics NS_AVAILABLE(10_12, 11_0);

@property (atomic, weak, nullable) id <PI_NURLSessionManagerDelegate> delegate;

#if DEBUG
- (void)concurrentDownloads:(void (^_Nullable)(NSUInteger concurrentDownloads))concurrentDownloadsCompletion;
#endif

@end
